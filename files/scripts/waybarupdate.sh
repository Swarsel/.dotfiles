CFG=$(git --git-dir="$HOME"/.dotfiles/.git --work-tree="$HOME"/.dotfiles/ status -s | wc -l)
CSE=$(git --git-dir="$DOCUMENT_DIR_PRIV"/CSE_TUWIEN/.git --work-tree="$DOCUMENT_DIR_PRIV"/CSE_TUWIEN/ status -s | wc -l)
PASS=$(($(git --git-dir="$HOME"/.local/share/password-store/.git --work-tree="$HOME"/.local/share/password-store/ status -s | wc -l) + $(git --git-dir="$HOME"/.local/share/password-store/.git --work-tree="$HOME"/.local/share/password-store/ diff origin/main..HEAD | wc -l)))

if [[ $CFG != 0 ]]; then
    CFG_STR='CONFIG'
else
    CFG_STR=''
fi

if [[ $CSE != 0 ]]; then
    CSE_STR=' CSE'
else
    CSE_STR=''
fi

if [[ $PASS != 0 ]]; then
    PASS_STR=' PASS'
else
    PASS_STR=''
fi

OUT="$CFG_STR""$CSE_STR""$PASS_STR"
echo "$OUT"
