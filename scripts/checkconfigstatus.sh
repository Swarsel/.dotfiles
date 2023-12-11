#!/bin/bash

# CFG=$(git --git-dir=$HOME/.cfg/ --work-tree=$HOME diff --numstat | wc -l)
CFG=$(git --git-dir=$HOME/.dotfiles/.git --work-tree=$HOME/.dotfiles/ status -s | wc -l)
CSE=$(git --git-dir=$HOME/Documents/GitHub/CSE_TUWIEN/.git --work-tree=$HOME/Documents/GitHub/CSE_TUWIEN/ status -s | wc -l)
PASS=$(git --git-dir=$HOME/.local/share/password-store/.git --work-tree=$HOME/.local/share/password-store/ status -s | wc -l)

if [ $CFG != 0 ]; then
    CFG_STR='CONFIG'
else
    CFG_STR=''
fi

if [ $CSE != 0 ]; then
    CSE_STR=' CSE'
else
    CSE_STR=''
fi

if [ $PASS != 0 ]; then
    PASS_STR=' PASS'
else
    PASS_STR=''
fi

OUT="$CFG_STR""$CSE_STR""$PASS_STR"
echo "$OUT"
