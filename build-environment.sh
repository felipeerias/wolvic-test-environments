#!/bin/zsh
#
# build-environment.sh — build a Wolvic environment from an equirectangular
# panorama, either HDR (EXR/HDR) or LDR (JPG/PNG/TIFF/WebP).
# Outputs into ./ENV_NAME/ following the layout expected by props.json.
#
# Usage:
#   build-environment.sh ENV_NAME SOURCE [EV [PEAK [DESAT]]]
#
# SOURCE must be a 2:1 equirectangular panorama.
#   .exr / .hdr                 → HDR path: exposure + Mobius tonemap → sRGB LDR,
#                                 then project to cube faces.
#   .jpg / .png / .tif / .webp  → LDR path: pixels are already display-referred
#                                 sRGB, so they are projected as-is.
#
# EV (HDR only) is the exposure compensation in stops applied before the
# tonemap (default 0.0, range -3..3). All environments shipped so far from
# EXR (cannon, goegap, hillyterrain, dikhololonight, moonlessgolf; verified
# on a Quest 3 in May 2026) were built at EV 0.0. Reach for +0.5 / +1.0 only
# if a scene looks dim on the headset. Negative values darken.
#
# PEAK (HDR only) is the linear scene value that the Mobius tonemap maps to
# white (default 10, which is also ffmpeg's default for untagged linear
# input). The curve is applied to each pixel's brightest RGB component (after
# exposure and the BT.2020 conversion): pixels whose max component is below
# the Mobius knee (0.3) pass through unchanged, brighter ones are scaled down
# smoothly so that PEAK lands on white, and anything above PEAK clips. Raise
# it to keep more detail in very bright skies/suns at the cost of slightly
# darker upper-midtones; lower it (e.g. 4) for a brighter, more contrasty
# look with earlier clipping.
#
# DESAT (HDR only) is the linear luma above which highlights are pushed
# toward white (ffmpeg tonemap `desat`; default 16, 0 disables). Needed for
# scenes with a visible sun: the in-camera-clipped sun core in PolyHaven
# HDRIs is extremely saturated (Venice: R 8640, G 1280, B 0) and, because the
# tonemap scales all channels by the same factor, it would render as a
# coloured disc that is darker than the near-white bloom around it. With 16
# only pixels at least 4 stops above white are affected, so sunset colours
# and skies keep their hue; lower values whiten more of the bloom. Use 0 for
# sun-free scenes where very bright coloured areas should keep their colour
# (e.g. a sunlit courtyard seen from a shaded interior).
# Use ./preview-tonemap.sh to compare candidate EV/PEAK/DESAT values without building.
#
# Recommended HDR source: 8K EXR from polyhaven.com. 16K adds processing time
# with no visible gain at 1024² output. Avoid 4K and below — they don't supply
# enough pixels per cube face. For LDR sources, 4096x2048 is the practical
# minimum; larger is better.
#
# Outputs (in ./ENV_NAME/):
#   $ENV_NAME.png            — 256x256 thumbnail (from the face the user sees
#                              when facing forward)
#   $ENV_NAME.zip            — ETC2 KTX linear (alias of _ktx)
#   $ENV_NAME_ktx.zip        — ETC2 KTX linear
#   $ENV_NAME_ktx_srgb.zip   — ETC2 KTX sRGB (Oculus / PICO / PFDM)
#   $ENV_NAME_misc.zip       — uncompressed PNG linear
#   $ENV_NAME_misc_srgb.zip  — uncompressed PNG sRGB (Quest after v69)
#
# Pipeline:
#   1. (HDR only) ffmpeg applies the exposure (float-capable `exposure`
#      filter), converts to linear BT.2020 (tonemap's native space), runs
#      tonemap=mobius with an explicit PEAK and DESAT, then encodes sRGB BT.709. The
#      whole chain stays in 32-bit float until the final rgb24 conversion, so
#      highlights above 1.0 roll off instead of clipping. Single pass over the
#      equirectangular so the mapping is consistent across faces. Mobius has
#      a gentler knee than hable, which crushed the moody feel of overcast/
#      night scenes.
#      History: until Sept 2026 the exposure step used lutrgb, which has no
#      float support; ffmpeg silently converted to 16-bit integer before it
#      and clipped everything above 1.0, so bright skies/water came out as
#      flat, textureless highlights (all at the same ~0.83 sRGB grey-white).
#      At EV 0 and PEAK 10 the new chain maps every pixel that was not
#      clipped before (max component ≤ 1.0 linear) identically; only the
#      formerly clipped highlights change. With EV ≠ 0 the results differ
#      slightly for pixels the old chain had clipped after the multiply.
#   2. ffmpeg v360 projects equirectangular → 6 cube faces at 2048² (Lanczos).
#   3. ImageMagick crops the 3x2 strip into 6 face PNGs.
#   4. Lanczos-downscale to 1024² + gentle unsharp pass.
#   5. mipgen encodes ETC2 KTX (linear and sRGB).
#   6. Five zips + thumbnail copied into ./ENV_NAME/.
#
# Orientation: v360 `yaw=180` rotates the entire output cube 180° around Y
# before extraction, so the user — who otherwise defaults to facing the
# panorama's back due to Wolvic's skybox geometry conventions (Skybox.cpp
# negates both vertex positions and UVs) — ends up facing the panorama
# center. Rotating the whole cube (vs. swapping individual face files) keeps
# the 6 faces internally consistent so they tile without seams.
# Verify a build without a headset with ./preview-environment.sh.
#
# Output face size is 1024 to match the layer allocation in
# wolvic/app/src/main/cpp/BrowserWorld.cpp (size = 1024).
#
# Known limitation: ffmpeg's EXR decoder fails ("decode_block() failed") on
# PIZ-compressed EXRs that carry an alpha channel (e.g. PolyHaven's
# camdeboo_road). Strip the alpha first, e.g. with the OpenEXR Python
# bindings (pip install OpenEXR numpy):
#   with OpenEXR.File(src) as f: rgb = f.channels()["RGBA"].pixels[..., :3]
#   OpenEXR.File({"compression": OpenEXR.ZIP_COMPRESSION,
#                 "type": OpenEXR.scanlineimage}, {"RGB": rgb}).write(dst)
# DWAA-compressed RGBA EXRs (e.g. cannon) decode fine.
#
# Dependencies: ffmpeg (with v360+zscale+tonemap), ffprobe, convert, zip, mipgen.

set -euo pipefail

usage() {
    print -u2 "Usage: $0 ENV_NAME SOURCE [EV [PEAK [DESAT]]]"
    print -u2 ""
    print -u2 "SOURCE: 2:1 equirectangular panorama."
    print -u2 "        .exr/.hdr are tonemapped (HDR path); .jpg/.png/.tif/.webp used as-is."
    print -u2 "EV:     HDR only. Exposure compensation in stops, -3..3 (default 0.0, which is"
    print -u2 "        what every shipped EXR environment used; +0.5/+1.0 brighten)."
    print -u2 "PEAK:   HDR only. Linear value mapped to white by the Mobius tonemap (default 10)."
    print -u2 "DESAT:  HDR only. Luma above which highlights turn white (default 16, 0 = off)."
    print -u2 ""
    print -u2 "Example: $0 goegap ~/Downloads/goegap_8k.exr"
    print -u2 "Example: $0 venicesunset ~/Downloads/venice_sunset_8k.exr 0 10 16"
    print -u2 "Example: $0 cloister ~/Downloads/historic_cloister_passage_8k.exr -1 10 0"
    print -u2 "Example: $0 lubnaig ~/Downloads/lubnaig.jpg"
    exit 1
}

if [[ $# -lt 2 || $# -gt 5 ]]; then
    usage
fi

ENV_NAME="$1"
SRC="$(realpath "$2")"
EXT="${SRC:e:l}"

case "$EXT" in
    exr|hdr)                   MODE=hdr ;;
    jpg|jpeg|png|tif|tiff|webp) MODE=ldr ;;
    *)
        print -u2 "Error: unsupported source format '.$EXT' (got: $SRC)"
        print -u2 "Supported: .exr .hdr (HDR) and .jpg .jpeg .png .tif .tiff .webp (LDR)"
        exit 1
        ;;
esac

EV="${3:-0.0}"
PEAK="${4:-10}"
DESAT="${5:-16}"
NUM_RE='^[+-]?([0-9]+[.]?[0-9]*|[.][0-9]+)$'
if [[ "$MODE" == ldr ]]; then
    if [[ $# -ge 3 ]]; then
        print -u2 "Warning: EV/PEAK/DESAT are only used for HDR sources; ignoring them for $SRC"
    fi
else
    if [[ ! "$EV" =~ $NUM_RE ]]; then
        print -u2 "Error: EV must be a number in stops (got: '$EV')"
        exit 1
    fi
    if (( EV < -3 || EV > 3 )); then
        print -u2 "Error: EV must be within -3..3 (ffmpeg exposure filter range), got $EV"
        exit 1
    fi
    if [[ ! "$PEAK" =~ $NUM_RE ]] || (( PEAK <= 1 )); then
        print -u2 "Error: PEAK must be a number greater than 1 (got: '$PEAK')"
        exit 1
    fi
    if [[ ! "$DESAT" =~ $NUM_RE ]] || (( DESAT < 0 )); then
        print -u2 "Error: DESAT must be a number >= 0 (got: '$DESAT')"
        exit 1
    fi
fi

# Sanity-check the source is 2:1 equirectangular. ffmpeg autorotates sources
# that carry rotation metadata (e.g. EXIF Orientation on JPEGs), so compare
# the dimensions as they will be after that rotation.
SRC_DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$SRC")
SRC_W=${SRC_DIMS%x*}
SRC_H=${SRC_DIMS#*x}
SRC_ROT=$(ffprobe -v error -select_streams v:0 -show_entries stream_side_data=rotation -of csv=p=0 "$SRC" 2>/dev/null | head -n1)
SRC_ROT=${SRC_ROT:-0}
SRC_ROT=${SRC_ROT%.*}
if (( (SRC_ROT % 180 + 180) % 180 == 90 )); then
    print -u2 "Note: source carries a ${SRC_ROT}° rotation; ffmpeg autorotates it, checking the rotated size."
    (( SRC_W, SRC_H = SRC_H, SRC_W ))
fi
if (( SRC_W != 2 * SRC_H )); then
    print -u2 "Error: source is ${SRC_W}x${SRC_H} (after rotation), expected a 2:1 equirectangular panorama."
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
echo "    source : $SRC (${SRC_DIMS}, ${MODE:u})"
echo "    output : $OUT_DIR"
if [[ "$MODE" == hdr ]]; then
    echo "    EV     : $EV stops"
    echo "    PEAK   : $PEAK (linear value mapped to white)"
    echo "    DESAT  : $DESAT (luma above which highlights turn white; 0 = off)"
fi

STRIP="$WORK_DIR/strip.png"

# Step 1+2: (HDR: exposure pre-multiply + tonemap HDR linear → sRGB LDR) +
# project equirectangular → cube strip. Single ffmpeg pass.
PROJECT="v360=e:c3x2:w=${STRIP_W}:h=${STRIP_H}:interp=lanczos:yaw=180"
if [[ "$MODE" == hdr ]]; then
    echo "==> exposure ${EV}EV + tonemap (Mobius, peak ${PEAK}, desat ${DESAT}) + project @ ${EDGE_HIGH}px/face (Lanczos)"
    # EXR has no colorspace metadata ffmpeg can pick up, so we declare it via
    # setparams (PolyHaven HDRIs are linear sRGB / Rec.709). Everything up to
    # the final format=rgb24 runs on gbrpf32le: `exposure`, zscale and tonemap
    # all support float, so no clipping happens before the tonemap. Do NOT
    # reintroduce lutrgb (no float support → auto-converted to 16-bit and
    # clipped) or a `format=gbrpf32le` (swscale float→float also clips).
    EXPOSURE=""
    if (( EV != 0 )); then
        EXPOSURE="exposure=exposure=${EV},"
    fi
    FILTERS="setparams=color_trc=linear:color_primaries=bt709:colorspace=bt709:range=pc,\
${EXPOSURE}\
zscale=t=linear:p=bt2020:m=bt2020nc,\
tonemap=mobius:desat=${DESAT}:peak=${PEAK},\
zscale=t=iec61966-2-1:p=bt709:m=bt709,\
format=rgb24,\
${PROJECT}"
else
    echo "==> project @ ${EDGE_HIGH}px/face (Lanczos)"
    # Convert to full-resolution RGB before projecting so chroma-subsampled
    # JPEGs are resampled as RGB rather than as 4:2:0 planes.
    FILTERS="format=rgb24,${PROJECT}"
fi
ffmpeg -hide_banner -loglevel warning -y -i "$SRC" \
    -vf "$FILTERS" \
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

# Thumbnail: negz is the face the user sees when facing forward (see
# "Orientation" above), i.e. the center of the source panorama.
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
