#!/bin/zsh
#
# preview-tonemap.sh — render an EXR through a tonemap chain to an
# equirectangular LDR PNG, for quick A/B comparison without rebuilding
# the full cubemap pipeline.
#
# Usage:
#   preview-tonemap.sh SOURCE.exr [OPERATOR] [EV]
#
# OPERATOR (default: hable)
#   hable     — filmic, preserves highlights, crushes shadows
#   mobius    — gentler shoulder/toe than hable
#   reinhard  — uniform compression, simplest
#   clamp     — no tonemap, just exposure + clip(0,1) + sRGB gamma
#
# EV (default: 0)
#   Stops of exposure compensation applied BEFORE the tonemap.
#   +1.0 doubles the linear values; +2.0 quadruples them; -1.0 halves them.
#
# Examples:
#   preview-tonemap.sh ~/EXR/goegap_8k.exr
#   preview-tonemap.sh ~/EXR/goegap_8k.exr hable 1.5
#   preview-tonemap.sh ~/EXR/goegap_8k.exr mobius 1.0
#   preview-tonemap.sh ~/EXR/goegap_8k.exr clamp 0.5
#
# Output: <basename>_preview_<operator>_ev<N>.png at 4096x2048.
# Open in any image viewer; or for an interactive first-person view
# (closer to VR), drop the PNG into https://pannellum.org or a similar
# browser panorama viewer.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    print -u2 "Usage: $0 SOURCE.exr [OPERATOR] [EV]"
    print -u2 "  OPERATOR: hable (default) | mobius | reinhard | clamp"
    print -u2 "  EV: stops of exposure compensation (default 0)"
    exit 1
fi

SRC="$(realpath "$1")"
OPERATOR="${2:-hable}"
EV="${3:-0}"

if [[ "${SRC:l}" != *.exr ]]; then
    print -u2 "Error: input must be a .exr file"
    exit 1
fi

case "$OPERATOR" in
    hable|mobius|reinhard) TONEMAP="tonemap=${OPERATOR}:desat=0" ;;
    clamp|none|"")         TONEMAP="" ;;
    *) print -u2 "Unknown operator '$OPERATOR' (use: hable | mobius | reinhard | clamp)"; exit 1 ;;
esac

MULT=$(python3 -c "print(2 ** $EV)")
EV_TAG=$(printf 'ev%+g' "$EV")
BASE="${SRC:r:t}"
OUT="${BASE}_preview_${OPERATOR}_${EV_TAG}.png"

if [[ -z "$TONEMAP" ]]; then
    # No tonemap operator: pre-scale by 2^EV, clamp to [0,1] (lutrgb works on
    # ffmpeg's normalized float [0,65535]/65535 internally), encode sRGB.
    CHAIN="setparams=color_trc=linear:color_primaries=bt709:colorspace=bt709:range=pc,\
lutrgb=r='clip(val*${MULT},0,65535)':g='clip(val*${MULT},0,65535)':b='clip(val*${MULT},0,65535)',\
zscale=t=iec61966-2-1:p=bt709:m=bt709,\
format=rgb24,\
scale=4096:2048"
else
    # Pre-multiply by 2^EV (without clamping — let the tonemap operator
    # handle the rolloff), then the standard linear→BT.2020→tonemap→sRGB chain.
    CHAIN="setparams=color_trc=linear:color_primaries=bt709:colorspace=bt709:range=pc,\
lutrgb=r='val*${MULT}':g='val*${MULT}':b='val*${MULT}',\
zscale=t=linear:p=bt2020:m=bt2020nc,\
${TONEMAP},\
zscale=t=iec61966-2-1:p=bt709:m=bt709,\
format=rgb24,\
scale=4096:2048"
fi

echo "==> $OUT  (operator=$OPERATOR, $EV_TAG, mult=$MULT)"
ffmpeg -hide_banner -loglevel warning -y -i "$SRC" -vf "$CHAIN" \
    -frames:v 1 -update 1 "$OUT"
