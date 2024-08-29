0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
local LIB="${0:A:h}/lib"

source "$LIB/clear-cache.zsh"
source "$LIB/mirrorlist.zsh"
source "$LIB/print.zsh"

function pac() {
    case $1 in
    add)
        if [[ -n $PACMAN_WRAPPER ]]; then
            _pac_print_green "Using $PACMAN_WRAPPER for installation."
            sudo $PACMAN_WRAPPER -S ${@:2}
        else
            sudo pacman -S ${@:2}
        fi
        ;;
    remove)
        sudo pacman -Rs ${@:2}
        ;;
    rm)
        pac remove ${@:2}
        ;;
    upgrade)
        if [[ $# -gt 1 ]]; then
            if [[ -n $PACMAN_WRAPPER ]]; then
                sudo pacman -Sy
                _pac_print_green "Using $PACMAN_WRAPPER for upgrading."
                sudo $PACMAN_WRAPPER -S ${@:2}
            else
                sudo pacman -Sy ${@:2}
            fi
        else
            if [[ -n $PACMAN_WRAPPER ]]; then
                sudo pacman -Sy
                _pac_print_green "Using $PACMAN_WRAPPER for upgrading."
                sudo $PACMAN_WRAPPER -Su
            else
                sudo pacman -Syu
            fi
        fi
        ;;
    upg)
        pac upgrade ${@:2}
        ;;
    list)
        if command -v fzf >/dev/null; then
            pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'
        else
            pacman -Qq | less
        fi
        ;;
    search)
        if [[ "$#" == 2 ]]; then
            if command -v fzf >/dev/null; then
                pacman -Slq | grep $2 | fzf --preview 'pacman -Si {}' --layout=reverse --bind 'enter:execute(pacman -Si {} | less)'
            else
                pacman -Slq | grep $2 | xargs pacman -Si | less
            fi
        else
            if command -v fzf >/dev/null; then
                pacman -Slq | fzf --preview 'pacman -Si {}' --layout=reverse --bind 'enter:execute(pacman -Si {} | less)'
            else
                pacman -Slq | xargs pacman -Si | less
            fi
        fi
        ;;
    prune)
        if pacman -Qtdq >/dev/null; then
            printf "\e[31m%s\e[0m" "This process might delete some necessary packages. Are you sure? (y/n) "
            read confirm
            [[ $confirm =~ ^[Yy]$ ]] && sudo pacman -Rns $(pacman -Qtdq)
        else
            _pac_print_yellow "No unused dependency found."
        fi
        ;;
    own)
        pacman -Qo ${@:2}
        ;;
    tree)
        if command -v pactree >/dev/null; then
            pactree ${@:2}
        else
            _pac_print_red "Install $(pacman-contrib) to use pactree(8)."
        fi
        ;;
    why)
        if command -v pactree >/dev/null; then
            pactree -r ${@:2}
        else
            _pac_print_red "Install $(pacman-contrib) to use pactree(8)."
        fi
        ;;
    mirrors)
        _pacman_update_mirror_list ${@:2}
        ;;
    clean)
        if command -v paccache >/dev/null; then
            _pacman_clear_cache ${@:2}
        else
            _pac_print_red "Install $(pacman-contrib) to use paccache(8)."
        fi
        ;;
    *)
        echo $'pac - A powerfull help functions for pacman

Usage:
  pac [command] [options]

Commands:
  add        Installing packages.
  remove     Removing packages.
  rm         Removing packages.
  upgrade    Upgrading packages.
  upg        Upgrading packages.
  list       List all the packages installed.
  search     Search the package online.
  prune      Removing unused packages (orphans).
  own        Identify which package a file in the file system belongs to.
  tree       View the dependency tree of a package.
  why        View the dependant tree of a package.
  mirrors    Updating mirror list using reflector.
  clean      Cleaning the package cache.

Options:
  -h, --help  Show this help message and exit.

Examples:
  pac add <package_name>       # Install a package
  pac rm <package_name>        # Remove a package
  pac upg                      # Upgrade all packages
  pac list                     # List all installed packages
  pac search <package_name>    # Search for a package online
  pac prune                    # Remove orphaned packages
  pac own <file_path>          # Find the package owning a specific file
  pac tree <package_name>      # Display the dependency tree of a package
  pac why <package_name>       # Display the dependant tree of a package
  pac mirrors                  # Update the mirror list
  pac clean                    # Clean the package cache'
        ;;
    esac
}
