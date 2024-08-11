function _pacman_clear_cache() {
    printf "\e[31m%s\e[0m" "You are about delete pacman and aur caches. Are you sure? (y/n) "
    read -r confirm
    [[ $confirm =~ ^[Yy]$ ]] || return

    _pac_print_green "$(_pac_print_bold 'Clearing pacman caches...')"
    /usr/bin/paccache -vruk1
    /usr/bin/paccache -vrk2 -c /var/cache/pacman/pkg

    local aur_helper="${1:-paru}"
    _pac_print_green "$(_pac_print_bold "Clearing aur ($aur_helper) caches...")"

    AUR_CACHE_DIR="$HOME/.cache/$aur_helper/clone"
    AUR_CACHE_REMOVED=$(find "$AUR_CACHE_DIR" -maxdepth 1 -mindepth 1 -type d | xargs -rd'\n' printf "-c%s\n")
    AUR_REMOVED=$(echo $AUR_CACHE_REMOVED | xargs -rd'\n' /usr/bin/paccache -ruvk0 | sed '/\.cache/!d' | cut -d \' -f2 | xargs -rd'\n' dirname)
    [ -z "$AUR_REMOVED" ] || _pac_print_gray "$(rm -vrf $AUR_REMOVED)"

    AUR_CACHE=$(find "$AUR_CACHE_DIR" -maxdepth 1 -mindepth 1 -type d | xargs -rd'\n' printf "-c%s\n")
    echo "$AUR_CACHE" | /usr/bin/paccache -vrk2

}
