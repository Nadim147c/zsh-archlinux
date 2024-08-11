function _pac_print_green() { printf "\e[32m%s\e[0m\n" "$1"; }
function _pac_print_yellow() { printf "\e[33m%s\e[0m\n" "$1"; }
function _pac_print_red() { printf "\e[31m%s\e[0m\n" "$1"; }
function _pac_print_cyan() { printf "\e[36m%s\e[0m\n" "$1"; }
function _pac_print_gray() { printf "\e[90m%s\e[0m\n" "$1"; }
function _pac_print_bold() { printf "\e[1m%s\e[0m\n" "$1"; }
function _pac_print_prompt() { printf "\e[90m%s\e[0m\n \e[90m(%s)\e[0m " "$1" "$2"; }
