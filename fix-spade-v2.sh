#!/usr/bin/env bash
# =============================================================================
#  SHEOL // fix-spade.sh  v2
#  Density-shaded ASCII spade. Reads as engraved metal in any terminal/TTY.
# =============================================================================

set -uo pipefail

GILT='\033[38;2;160;130;64m'
HALO='\033[38;2;232;200;112m'
BONE='\033[38;2;184;174;160m'
LINEN='\033[38;2;107;100;112m'
RESET='\033[0m'

step() { echo -e "${HALO}  ▸${RESET} ${BONE}$1${RESET}"; }
ok()   { echo -e "${GILT}  ✓${RESET} ${BONE}$1${RESET}"; }

echo
echo -e "${GILT}    ♠  spade fix v2${RESET}"
echo

DOTS=""
for c in "$HOME/sheol-dots" "$HOME/arch-dot-files/sheol-dots" "$HOME/arch-dot-files" "$(pwd)"; do
    if [ -d "$c/pkgs/fastfetch/.config/fastfetch" ]; then
        DOTS="$c"; break
    fi
done

if [ -z "$DOTS" ]; then
    echo "couldn't find sheol-dots repo"
    exit 1
fi

SPADE="$DOTS/pkgs/fastfetch/.config/fastfetch/spade.txt"

step "backing up old spade"
cp "$SPADE" "$SPADE.bak.$(date +%s)" 2>/dev/null || true

step "writing density-shaded spade"
cat > "$SPADE" << 'SPADE_EOF'
$1+---------------------+
$1|                     |
$1|          $1#$1          |
$1|         $1##$2=$1         |
$1|        $1##$2===$1        |
$1|      $1###$2==$1#$2===$1      |
$1|    $1####$2===$1##$2====$1    |
$1|  $1#####$2====$1###$2=====$1  |
$1| $1#####$2=====$1####$2=====$1 |
$1| $1#####$2=====$1####$2=====$1 |
$1|   $1####$2=  $1#  $1#$2====$1   |
$1|         $1##$2=$1         |
$1|       $1####$2===$1       |
$1|                     |
$1+---------------------+
$2     IORDANUS LANHAM
SPADE_EOF

ok "spade.txt updated"
echo

step "preview:"
echo
cat "$SPADE" | sed 's/\$1//g; s/\$2//g' | sed 's/^/    /'
echo

step "test it: run fastfetch"
echo
echo -e "${GILT}  ◆${RESET}  ${BONE}done${RESET}"
echo
echo -e "${BONE}  commit + push:${RESET}"
echo -e "${LINEN}    cd $DOTS && git add -A && git commit -m 'spade: density-shaded ASCII' && git push${RESET}"
echo
