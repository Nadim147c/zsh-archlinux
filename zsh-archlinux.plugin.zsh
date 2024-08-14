local LIB="$(dirname "$0")/lib"
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
        if [[ -n $PACMAN_WRAPPER ]]; then
            sudo pacman -Sy
            _pac_print_green "Using $PACMAN_WRAPPER for upgrading."
            sudo $PACMAN_WRAPPER -Su
        else
            sudo pacman -Syu
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
    esac
}

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `pac`. Otherwise, compinit will have already done that.
if [[ ! -f "${ZINIT[COMPLETIONS_DIR]:-$ZSH_CACHE_DIR/completions}/_pac" ]]; then
    typeset -g -A _comps
    autoload -Uz _pac
    _comps[pac]=_pac
fi

cat >|"${ZINIT[COMPLETIONS_DIR]:-$ZSH_CACHE_DIR/completions}/_pac" <<'EOF'
#compdef pac

# builds command for invoking pacman in a _call_program command - extracts
# relevant options already specified (config file, etc)
# $cmd must be declared by calling function
_pacman_get_command() {
	# this is mostly nicked from _perforce
	cmd=( "pacman" "2>/dev/null")
	integer i
	for (( i = 2; i < CURRENT - 1; i++ )); do
		if [[ ${words[i]} = "--config" || ${words[i]} = "--root" ]]; then
			cmd+=( ${words[i,i+1]} )
		fi
	done
}

_pacman_completions_all_packages() {
	local -a seq sep cmd packages repositories packages_long
	_pacman_get_command

	if [[ ${words[CURRENT-1]} == '--ignore' ]]; then
		seq='_sequence'
		sep=(-S ',')
	else
		seq=
		sep=()
	fi

	if compset -P1 '*/*'; then
		packages=( $(_call_program packages $cmd[@] -Sql ${words[CURRENT]%/*}) )
		typeset -U packages
		${seq} _wanted repo_packages expl "repository/package" compadd ${sep[@]} ${(@)packages}
	else
		packages=( $(_call_program packages $cmd[@] -Sql) )
		typeset -U packages
		${seq} _wanted packages expl "packages" compadd ${sep[@]} - "${(@)packages}"

		repositories=($(pacman-conf --repo-list))
		typeset -U repositories
		_wanted repo_packages expl "repository/package" compadd -S "/" $repositories
	fi
}

# provides completions for installed packages
_pacman_completions_installed_packages() {
	local -a cmd packages packages_long
	packages_long=(/var/lib/pacman/local/*(/))
	packages=( ${${packages_long#/var/lib/pacman/local/}%-*-*} )
	compadd "$@" -a packages
}

# provides completions for aur helpers
_pacman_completions_aur_helpers() {
    local -a aur_helpers 
    aur_helpers=(yay paru pikaur aura aurman pacaur trizen)
	compadd "$@" -a aur_helpers
}

# provides completions for aur helpers
_pacman_completions_mirrors_update() {
    local -a options
    options=("-u:Update reflector options." "--update-options:Update reflector options.")
	#compadd "$@" -a options
    _describe 'mirrors_update' options
}


local state com cur
local -a opts
local -a coms

cur=${words[${#words[@]}]}

# lookup for command
for word in ${words[@]:1}; do
    if [[ $word != -* ]]; then
        com=$word
        break
    fi
done

if [[ $cur == $com ]]; then
    state="command"
    coms+=("add:Installing packages." "remove:Removing packages." "upg:Upgrading packages." "list:List all the packages installed." "search:Search the package online." "prune:Removing unused packages (orphans)." "own:Which package a file in the file system belongs to." "tree:View the dependency tree of a package." "why:View the dependant tree of a package." "mirrors:Update mirror list using reflector." "clean:Cleaning the package cache.")
fi

case $state in
(command)
    _describe 'command' coms
;;
*)
    case "$com" in
        (add)
            _arguments '*:package:_pacman_completions_all_packages'
        ;;
        (remove)
            _arguments '*:package:_pacman_completions_installed_packages'
        ;;
        (mirrors)
            _arguments '*:package:_pacman_completions_mirrors_update'
        ;;
        (own)
            _arguments '*:file:_files'
        ;;
        (tree)
            _arguments '*:package:_pacman_completions_installed_packages'
        ;;
        (clean)
            _arguments '*:package:_pacman_completions_aur_helpers'
        ;;
        (why)
            _arguments '*:package:_pacman_completions_installed_packages'
        ;;
        *)
        # fallback to file completion
            _arguments '*:file:_files'
        ;;
    esac
esac

EOF
