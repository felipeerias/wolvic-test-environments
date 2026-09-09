#!/bin/zsh
#
# preview-tonemap.sh — render an EXR through a tonemap chain to an
# equirectangular LDR PNG, for quick A/B comparison without rebuilding
# the full cubemap pipeline.
#
# Usage:
#   preview-tonemap.sh SOURCE.exr [OPERATOR] [EV] [PEAK]
#
# OPERATOR (default: hable)
#   hable     — filmic, preserves highlights, crushes shadows
#   mobius    — gentler shoulder/toe than hable
#   reinhard  — uniform compression, simplest
#   clamp     — no tonemap, just exposure + clip(0,1) + sRGB gamma
#
# EV (default: 0, range -3..3)
#   Stops of exposure compensation applied BEFORE the tonemap.
#   +1.0 doubles the linear values; +2.0 quadruples them; -1.0 halves them.
#
# PEAK (default: 10)
#   Linear value that the tonemap operator maps to white (ffmpeg tonemap
#   `peak=`). Ignored by `clamp`. Same meaning as in build-environment.sh.
#
# The whole chain runs in 32-bit float until the final PNG conversion
# (exposure, zscale and tonemap all support gbrpf32le), so highlights above
# 1.0 reach the tonemap intact. build-environment.sh uses the same chain.
#
# Examples:
#   preview-tonemap.sh ~/EXR/goegap_8k.exr
#   preview-tonemap.sh ~/EXR/goegap_8k.exr hable 1.5
#   preview-tonemap.sh ~/EXR/goegap_8k.exr mobius 1.0
#   preview-tonemap.sh ~/EXR/goegap_8k.exr clamp 0.5
#   preview-tonemap.sh ~/EXR/venice_sunset_8k.exr mobius 0 20
#
# Output: <basename>_preview_<operator>_ev<N>_peak<P>.png at 4096x2048.
# Open in any image viewer; or for an interactive first-person view
# (closer to VR), drop the PNG into https://pannellum.org or a similar
# browser panorama viewer.

set -euo pipefail

if [[ $# -lt 1 || $# -gt 4 ]]; then
    print -u2 "Usage: $0 SOURCE.exr [OPERATOR] [EV] [PEAK]"
    print -u2 "  OPERATOR: hable (default) | mobius | reinhard | clamp"
    print -u2 "  EV: stops of exposure compensation, -3..3 (default 0)"
    print -u2 "  PEAK: linear value mapped to white by the tonemap (default 10)"
    exit 1
fi

SRC="$(realpath "$1")"
OPERATOR="${2:-hable}"
EV="${3:-0}"
PEAK="${4:-10}"

NUM_RE='^[+-]?([0-9]+[.]?[0-9]*|[.][0-9]+)$'
if [[ ! "$EV" =~ $NUM_RE ]] || (( EV < -3 || EV > 3 )); then
    print -u2 "Error: EV must be a number within -3..3 (ffmpeg exposure filter range), got '$EV'"
    exit 1
fi
if [[ ! "$PEAK" =~ $NUM_RE ]] || (( PEAK <= 1 )); then
    print -u2 "Error: PEAK must be a number greater than 1, got '$PEAK'"
    exit 1
fi

if [[ "${SRC:l}" != *.exr ]]; then
    print -u2 "Error: input must be a .exr file"
    exit 1
fi

case "$OPERATOR" in
    hable|mobius|reinhard) TONEMAP="tonemap=${OPERATOR}:desat=0:peak=${PEAK}" ;;
    clamp|none|"")         TONEMAP="" ;;
    *) print -u2 "Unknown operator '$OPERATOR' (use: hable | mobius | reinhard | clamp)"; exit 1 ;;
esac

EV_TAG=$(printf 'ev%+g' "$EV")
BASE="${SRC:r:t}"
EXPOSURE=""
if (( EV != 0 )); then
    EXPOSURE="exposure=exposure=${EV},"
fi

if [[ -z "$TONEMAP" ]]; then
    # No tonemap operator: exposure in float, then encode sRGB; values above
    # 1.0 clip in the final conversion to 8-bit RGB.
    OUT="${BASE}_preview_${OPERATOR}_${EV_TAG}.png"
    CHAIN="setparams=color_trc=linear:color_primaries=bt709:colorspace=bt709:range=pc,\
${EXPOSURE}\
zscale=t=iec61966-2-1:p=bt709:m=bt709,\
format=rgb24,\
scale=4096:2048"
else
    # Exposure in float, then the standard linear→BT.2020→tonemap→sRGB chain.
    OUT="${BASE}_preview_${OPERATOR}_${EV_TAG}_peak${PEAK}.png"
    CHAIN="setparams=color_trc=linear:color_primaries=bt709:colorspace=bt709:range=pc,\
${EXPOSURE}\
zscale=t=linear:p=bt2020:m=bt2020nc,\
${TONEMAP},\
zscale=t=iec61966-2-1:p=bt709:m=bt709,\
format=rgb24,\
scale=4096:2048"
fi

echo "==> $OUT  (operator=$OPERATOR, $EV_TAG, peak=$PEAK)"
ffmpeg -hide_banner -loglevel warning -y -i "$SRC" -vf "$CHAIN" \
    -frames:v 1 -update 1 "$OUT"
