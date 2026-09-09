#!/bin/zsh
#
# preview-environment.sh — re-project a built environment's cube faces back
# to an equirectangular PNG, to verify orientation and face continuity
# without deploying to a headset.
#
# Usage:
#   preview-environment.sh ENV_NAME [OUT.png]
#
# Reads ./ENV_NAME/ENV_NAME_misc.zip (the uncompressed PNG faces) and writes
# ENV_NAME_reproj.png (4096x2048) in the current directory unless OUT is given.
#
# The output shows the environment as Wolvic presents it to the user: the
# reverse projection applies yaw=180 (undoing the build's rotation) and then
# mirrors horizontally (reproducing Wolvic's cube-map mirroring, see the
# "Orientation" notes in build-environment.sh). For an environment built with
# the default flip the result should match the source panorama: centre of the
# source in the centre of the output, left is left, seams invisible. For an
# environment built with --no-flip it shows the mirrored source, which is
# what Wolvic will show.

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    print -u2 "Usage: $0 ENV_NAME [OUT.png]"
    exit 1
fi

ENV_NAME="$1"
OUT="${2:-${ENV_NAME}_reproj.png}"
ZIP="$PWD/$ENV_NAME/${ENV_NAME}_misc.zip"

if [[ ! -f "$ZIP" ]]; then
    print -u2 "Error: $ZIP not found"
    exit 1
fi

WORK_DIR="$(mktemp -d -t wolvic-preview-XXXXXX)"
trap "rm -rf '$WORK_DIR'" EXIT

unzip -q "$ZIP" -d "$WORK_DIR"

# Reassemble the 3x2 strip in v360's default c3x2 order (rludfb):
#   [right=posx][left=negx][up=posy]
#   [down=negy ][front=posz][back=negz]
montage "$WORK_DIR/posx.png" "$WORK_DIR/negx.png" "$WORK_DIR/posy.png" \
        "$WORK_DIR/negy.png" "$WORK_DIR/posz.png" "$WORK_DIR/negz.png" \
        -tile 3x2 -geometry +0+0 "$WORK_DIR/strip.png"

# yaw=180 undoes the build rotation; hflip reproduces Wolvic's mirroring.
ffmpeg -hide_banner -loglevel warning -y -i "$WORK_DIR/strip.png" \
    -vf "v360=c3x2:e:w=4096:h=2048:interp=lanczos:yaw=180,hflip" \
    -frames:v 1 -update 1 "$OUT"

echo "==> $OUT"
