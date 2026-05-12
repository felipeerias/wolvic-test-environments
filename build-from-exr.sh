#!/bin/zsh
#
# build-from-exr.sh — build a Wolvic environment from an HDR EXR panorama.
# Outputs into ./ENV_NAME/ following the layout expected by props.json.
#
# Usage:
#   build-from-exr.sh ENV_NAME SOURCE.exr [EV]
#
# EV is the exposure compensation in stops applied before tonemap (default 1.0).
# PolyHaven HDRIs ship raw linear data with very high dynamic range, so an
# exposure boost is typically needed to match their web preview look.
# Typical values:
#   1.0  — daytime scenes (most cases)
#   0.0  — night / twilight scenes (preserves the dark mood)
#
# Recommended source: 8K EXR from polyhaven.com (or similar). 16K works but
# adds processing time with no visible gain at 1024² output. Avoid 4K and
# below — they don't supply enough pixels per cube face.
#
# Outputs (in ./ENV_NAME/):
#   $ENV_NAME.png            — 256x256 thumbnail
#   $ENV_NAME.zip            — ETC2 KTX linear (alias of _ktx)
#   $ENV_NAME_ktx.zip        — ETC2 KTX linear
#   $ENV_NAME_ktx_srgb.zip   — ETC2 KTX sRGB (Oculus / PICO / PFDM)
#   $ENV_NAME_misc.zip       — uncompressed PNG linear
#   $ENV_NAME_misc_srgb.zip  — uncompressed PNG sRGB (Quest after v69)
#
# Pipeline:
#   1. ffmpeg pre-multiplies linear values by 2^EV (exposure compensation),
#      then tonemap=mobius converts HDR linear → sRGB LDR. Single pass over
#      the equirectangular so the dynamic-range mapping is consistent across
#      faces. Mobius has gentle highlight/shadow rolloff — preserves the
#      moody feel of overcast/night scenes that hable would crush flat.
#   2. ffmpeg v360 projects equirectangular → 6 cube faces at 2048² (Lanczos).
#   3. ImageMagick crops the 3x2 strip into 6 face PNGs.
#   4. Lanczos-downscale to 1024² + gentle unsharp pass.
#   5. mipgen encodes ETC2 KTX (linear and sRGB).
#   6. Five zips + thumbnail copied into ./ENV_NAME/.
#
# Orientation: v360 `yaw=180` rotates the entire output cube 180° around Y
# before extraction, so the user — who otherwise defaults to facing the
# panorama's back due to Wolvic's skybox geometry conventions — ends up
# facing the panorama center. Rotating the whole cube (vs. swapping
# individual face files) keeps the 6 faces internally consistent so they
# tile without seams.
#
# Output face size is 1024 to match the layer allocation in
# wolvic/app/src/main/cpp/BrowserWorld.cpp (size = 1024).
#
# Dependencies: ffmpeg (with v360+zscale+tonemap), convert, zip, mipgen.

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    print -u2 "Usage: $0 ENV_NAME SOURCE.exr [EV]"
    print -u2 ""
    print -u2 "EV: exposure compensation in stops (default 1.0)"
    print -u2 "    1.0 for daytime scenes, 0.0 for night/twilight scenes."
    print -u2 ""
    print -u2 "Example: $0 goegap ~/Downloads/goegap_8k.exr 1.0"
    print -u2 "Example: $0 moonless_golf ~/Downloads/moonless_golf_8k.exr 0"
    exit 1
fi

ENV_NAME="$1"
SRC="$(realpath "$2")"
EV="${3:-1.0}"
EV_MULT=$(python3 -c "print(2 ** $EV)")

if [[ "${SRC:l}" != *.exr ]]; then
    print -u2 "Error: input must be a .exr file (got: $SRC)"
    print -u2 "For JPG/PNG sources, use ../skybox/1.8.4/build-environment.sh."
    exit 1
fi

OUT_DIR="$PWD/$ENV_NAME"

EDGE_HIGH=2048
EDGE_LOW=1024
STRIP_W=$((EDGE_HIGH * 3))
STRIP_H=$((EDGE_HIGH * 2))

WORK_DIR="$(mktemp -d -t wolvic-env-XXXXXX)"
trap "rm -rf '$WORK_DIR'" EXIT

mkdir -p "$OUT_DIR"

echo "==> Building '$ENV_NAME'"
echo "    source : $SRC"
echo "    output : $OUT_DIR"
echo "    EV     : $EV stops (linear multiplier ${EV_MULT})"

STRIP="$WORK_DIR/strip.png"

# Step 1+2: exposure pre-multiply + tonemap HDR linear → sRGB LDR + project
# equirectangular → cube strip. Single ffmpeg pass.
echo "==> exposure x${EV_MULT} + tonemap (Mobius) + project @ ${EDGE_HIGH}px/face (Lanczos)"
# EXR has no colorspace metadata ffmpeg can pick up, so we declare it via
# setparams (PolyHaven HDRIs are linear sRGB / Rec.709), then pre-multiply
# linear values by 2^EV for exposure compensation, detour through BT.2020
# because that's tonemap's native space, then back to sRGB BT.709.
ffmpeg -hide_banner -loglevel warning -y -i "$SRC" \
    -vf "setparams=color_trc=linear:color_primaries=bt709:colorspace=bt709:range=pc,\
lutrgb=r='val*${EV_MULT}':g='val*${EV_MULT}':b='val*${EV_MULT}',\
zscale=t=linear:p=bt2020:m=bt2020nc,\
tonemap=mobius:desat=0,\
zscale=t=iec61966-2-1:p=bt709:m=bt709,\
format=rgb24,\
v360=e:c3x2:w=${STRIP_W}:h=${STRIP_H}:interp=lanczos:yaw=180" \
    -frames:v 1 -update 1 "$STRIP"

# Step 3: crop strip into 6 face files.
# ffmpeg v360 c3x2 default ordering (out_forder=rludfb):
#   [right ][ left ][  up  ]
#   [ down ][front ][ back ]
echo "==> cropping cube faces"
cd "$WORK_DIR"
E=$EDGE_HIGH
E2=$((E * 2))
convert "$STRIP" -crop "${E}x${E}+0+0"        +repage posx_full.png  # right
convert "$STRIP" -crop "${E}x${E}+${E}+0"     +repage negx_full.png  # left
convert "$STRIP" -crop "${E}x${E}+${E2}+0"    +repage posy_full.png  # up
convert "$STRIP" -crop "${E}x${E}+0+${E}"     +repage negy_full.png  # down
convert "$STRIP" -crop "${E}x${E}+${E}+${E}"  +repage posz_full.png  # front
convert "$STRIP" -crop "${E}x${E}+${E2}+${E}" +repage negz_full.png  # back
rm -f "$STRIP"

# Step 4: Lanczos downscale + gentle unsharp.
echo "==> downscaling to ${EDGE_LOW}² (Lanczos + unsharp)"
for face in posx negx posy negy posz negz; do
    convert "${face}_full.png" \
        -filter Lanczos -resize "${EDGE_LOW}x${EDGE_LOW}!" \
        -unsharp 0x0.6+0.6+0.02 \
        "${face}.png"
done
rm -f *_full.png

# Step 5: package outputs.
echo "==> packaging"

zip -qj "${ENV_NAME}_misc.zip" \
    posx.png negx.png posy.png negy.png posz.png negz.png

for f in posx negx posy negy posz negz; do
    mipgen -f ktx -m 1 -c etc_rgb8_rgba_100 --strip-alpha "$f.png" "$f.ktx" >/dev/null
done
zip -qj "${ENV_NAME}.zip" posx.ktx negx.ktx posy.ktx negy.ktx posz.ktx negz.ktx
cp "${ENV_NAME}.zip" "${ENV_NAME}_ktx.zip"
rm -f *.ktx

for f in posx negx posy negy posz negz; do
    mipgen -f ktx -m 1 -c etc_srgb8_rgba_100 --strip-alpha "$f.png" "${f}_srgb.ktx" >/dev/null
done
zip -qj "${ENV_NAME}_ktx_srgb.zip" \
    posx_srgb.ktx negx_srgb.ktx posy_srgb.ktx negy_srgb.ktx posz_srgb.ktx negz_srgb.ktx
rm -f *_srgb.ktx

for f in posx negx posy negy posz negz; do
    convert "$f.png" -colorspace sRGB "${f}_srgb.png"
done
zip -qj "${ENV_NAME}_misc_srgb.zip" \
    posx_srgb.png negx_srgb.png posy_srgb.png negy_srgb.png posz_srgb.png negz_srgb.png

convert negz.png -resize "512x512" \
    -gravity Center -crop "256x256+0+0" +repage \
    "${ENV_NAME}.png"

# Step 6: move outputs into place.
mv "${ENV_NAME}.zip" "${ENV_NAME}_ktx.zip" "${ENV_NAME}_ktx_srgb.zip" \
   "${ENV_NAME}_misc.zip" "${ENV_NAME}_misc_srgb.zip" "${ENV_NAME}.png" \
   "$OUT_DIR/"

echo "==> done."
ls -la "$OUT_DIR/"
echo ""
echo "Don't forget to update props.json and README.md."
