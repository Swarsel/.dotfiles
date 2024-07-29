shopt -s nullglob globstar

typeit=0
if [[ $# -ge 1 && $1 == "--type" ]]; then
    typeit=1
    shift
fi

export PASSWORD_STORE_DIR=~/.local/share/password-store
prefix=${PASSWORD_STORE_DIR-~/.local/share/password-store}
password_files=( "$prefix"/otp/**/*.gpg )
password_files=( "${password_files[@]#"$prefix"/}" )
password_files=( "${password_files[@]%.gpg}" )

password=$(printf '%s\n' "${password_files[@]}" | fuzzel --dmenu "$@")

[[ -n $password ]] || exit

if [[ $typeit -eq 0 ]]; then
  pass otp -c "$password" &>/tmp/pass-fuzzel
else
  pass otp "$password" | { IFS= read -r pass; printf %s "$pass"; } | wtype -
fi
notify-send -u critical -a pass -t 1000 "Copied/Typed OTPassword"
