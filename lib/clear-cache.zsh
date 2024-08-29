function _pacman_clear_cache() {
    printf "\e[31m%s\e[0m" "You are about delete pacman and aur caches. Are you sure? (y/n) "
    read -r confirm
    [[ $confirm =~ ^[Yy]$ ]] || return

    _pac_print_green "$(_pac_print_bold 'Clearing pacman caches...')"

    _PACCACHE="$(which paccache)"
    $_PACCACHE -vruk1
    $_PACCACHE -vrk2 -c /var/cache/pacman/pkg

    local aur_helper="${1:-paru}"
    _pac_print_green "$(_pac_print_bold "Clearing aur ($aur_helper) caches...")"

    AUR_CACHE_DIR="$HOME/.cache/$aur_helper/clone"
    AUR_CACHE_REMOVED=$(find "$AUR_CACHE_DIR" -maxdepth 1 -mindepth 1 -type d | xargs -rd'\n' printf "-c%s\n")
    AUR_REMOVED=$(echo $AUR_CACHE_REMOVED | xargs -rd'\n' $_PACCACHE -ruvk0 | sed '/\.cache/!d' | cut -d \' -f2 | xargs -rd'\n' -n1 dirname)
    if [[ -z "$AUR_REMOVED" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && rm -rf "$line" && echo "removed: '$line'"
        done <<<"$AUR_REMOVED"
    fi

    AUR_CACHE=$(find "$AUR_CACHE_DIR" -maxdepth 1 -mindepth 1 -type d | xargs -rd'\n' printf "-c%s\n")
    echo "$AUR_CACHE" | $_PACCACHE -vrk2

}
