# Adapted from https://code.kulupu.party/thesuess/home-manager/src/branch/main/modules/river.nix
shopt -s nullglob globstar

otp=0
typeit=0
while :; do
    case ${1:-} in
    -t | --type)
        typeit=1
        ;;
    -o | --otp)
        otp=1
        ;;
    *) break ;;
    esac
    shift
done

export PASSWORD_STORE_DIR=~/.local/share/password-store
prefix=${PASSWORD_STORE_DIR-~/.local/share/password-store}
if [[ $otp -eq 0 ]]; then
    password_files=("$prefix"/**/*.gpg)
else
    password_files=("$prefix"/otp/**/*.gpg)
fi
password_files=("${password_files[@]#"$prefix"/}")
password_files=("${password_files[@]%.gpg}")

password=$(printf '%s\n' "${password_files[@]}" | fuzzel --dmenu "$@")

[[ -n $password ]] || exit
if [[ $otp -eq 0 ]]; then
    if [[ $typeit -eq 0 ]]; then
        pass show -c "$password" &> /tmp/pass-fuzzel
    else
        pass show "$password" | {
            IFS= read -r pass
            printf %s "$pass"
        } | wtype -
    fi
else
    if [[ $typeit -eq 0 ]]; then
        pass otp -c "$password" &> /tmp/pass-fuzzel
    else
        pass otp "$password" | {
            IFS= read -r pass
            printf %s "$pass"
        } | wtype -
    fi
fi
notify-send -u critical -a pass -t 1000 "Copied/Typed Password"
