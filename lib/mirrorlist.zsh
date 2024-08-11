source "$(dirname "$0")/print.zsh"

function _pacman_get_reflector_opts() {
    function _question() { printf "\e[36m%s\e[0m \e[90m(%s)\e[0m " "$1" "$2"; }
    function _check_val() {
        if [[ -z "$2" ]]; then
            _pac_print_red "$1"
            return 1
        fi
    }

    local REFLECTOR_CONFIG_PATH="$HOME/.reflector"

    if command -v fzf &>/dev/null; then
        local all_countries=("AF:Afghanistan" "AL:Albania" "DZ:Algeria" "AD:Andorra" "AO:Angola" "AG:Antigua and Barbuda" "AR:Argentina" "AM:Armenia" "AU:Australia" "AT:Austria" "AZ:Azerbaijan" "BS:Bahamas" "BH:Bahrain" "BD:Bangladesh" "BB:Barbados" "BY:Belarus" "BE:Belgium" "BZ:Belize" "BJ:Benin" "BT:Bhutan" "BO:Bolivia" "BA:Bosnia and Herzegovina" "BW:Botswana" "BR:Brazil" "BN:Brunei" "BG:Bulgaria" "BF:Burkina Faso" "BI:Burundi" "CV:Cabo Verde" "KH:Cambodia" "CM:Cameroon" "CA:Canada" "CF:Central African Republic" "TD:Chad" "CL:Chile" "CN:China" "CO:Colombia" "KM:Comoros" "CD:Congo, Democratic Republic of the" "CG:Congo, Republic of the" "CR:Costa Rica" "HR:Croatia" "CU:Cuba" "CY:Cyprus" "CZ:Czech Republic" "DK:Denmark" "DJ:Djibouti" "DM:Dominica" "DO:Dominican Republic" "EC:Ecuador" "EG:Egypt" "SV:El Salvador" "GQ:Equatorial Guinea" "ER:Eritrea" "EE:Estonia" "SZ:Eswatini" "ET:Ethiopia" "FJ:Fiji" "FI:Finland" "FR:France" "GA:Gabon" "GM:Gambia" "GE:Georgia" "DE:Germany" "GH:Ghana" "GR:Greece" "GD:Grenada" "GT:Guatemala" "GN:Guinea" "GW:Guinea-Bissau" "GY:Guyana" "HT:Haiti" "HN:Honduras" "HU:Hungary" "IS:Iceland" "IN:India" "ID:Indonesia" "IR:Iran" "IQ:Iraq" "IE:Ireland" "IL:Israel" "IT:Italy" "JM:Jamaica" "JP:Japan" "JO:Jordan" "KZ:Kazakhstan" "KE:Kenya" "KI:Kiribati" "KP:Korea, North" "KR:Korea, South" "XK:Kosovo" "KW:Kuwait" "KG:Kyrgyzstan" "LA:Laos" "LV:Latvia" "LB:Lebanon" "LS:Lesotho" "LR:Liberia" "LY:Libya" "LI:Liechtenstein" "LT:Lithuania" "LU:Luxembourg" "MG:Madagascar" "MW:Malawi" "MY:Malaysia" "MV:Maldives" "ML:Mali" "MT:Malta" "MH:Marshall Islands" "MR:Mauritania" "MU:Mauritius" "MX:Mexico" "FM:Micronesia" "MD:Moldova" "MC:Monaco" "MN:Mongolia" "ME:Montenegro" "MA:Morocco" "MZ:Mozambique" "MM:Myanmar" "NA:Namibia" "NR:Nauru" "NP:Nepal" "NL:Netherlands" "NZ:New Zealand" "NI:Nicaragua" "NE:Niger" "NG:Nigeria" "MK:North Macedonia" "NO:Norway" "OM:Oman" "PK:Pakistan" "PW:Palau" "PA:Panama" "PG:Papua New Guinea" "PY:Paraguay" "PE:Peru" "PH:Philippines" "PL:Poland" "PT:Portugal" "QA:Qatar" "RO:Romania" "RU:Russia" "RW:Rwanda" "WS:Samoa" "SM:San Marino" "ST:Sao Tome and Principe" "SA:Saudi Arabia" "SN:Senegal" "RS:Serbia" "SC:Seychelles" "SL:Sierra Leone" "SG:Singapore" "SK:Slovakia" "SI:Slovenia" "SB:Solomon Islands" "SO:Somalia" "ZA:South Africa" "SS:South Sudan" "ES:Spain" "LK:Sri Lanka" "SD:Sudan" "SR:Suriname" "SE:Sweden" "CH:Switzerland" "SY:Syria" "TW:Taiwan" "TJ:Tajikistan" "TZ:Tanzania" "TH:Thailand" "TL:Timor-Leste" "TR:Turkey" "TM:Turkmenistan" "TV:Tuvalu" "UG:Uganda" "UA:Ukraine" "AE:United Arab Emirates" "GB:United Kingdom" "US:United States" "UY:Uruguay" "UZ:Uzbekistan" "VU:Vanuatu" "VA:Vatican City" "VE:Venezuela" "VN:Vietnam" "YE:Yemen" "ZM:Zambia" "ZW:Zimbabwe")
        local _fzf_flags=(
            '--multi'
            '--prompt=Country: '
            '--header=Use <Tab> key for selecting multiple'
            '--bind=tab:toggle+clear-query'
            '--preview=printf "%s\n" {+}'
            '--preview-label=Selected Countries'
        )
        selected_countries=$(printf "%s\n" "${all_countries[@]}" | fzf "${_fzf_flags[@]}" | cut -d: -f1 | xargs -rd'\n' printf '%s,')
    else
        _question "What countries (code or name) you want to use? (Comma Sparated)" "Required"
        read -r selected_countries
    fi
    _check_val "You must provide at least one country." "$selected_countries" || return 1

    _question "How much time since last synchronized? (Hours)" "Default: 12"
    read -r age
    [[ -z $age ]] && age="12"
    _check_val "You must provide an age value." "$age" || return 1

    if command -v fzf &>/dev/null; then
        local protocals=(https http ftp rsync)
        local _fzf_flags=(
            '--multi'
            '--prompt=Protocol: '
            '--header=Use <Tab> key for selecting multiple'
            '--bind=tab:select+clear-query'
            '--preview=printf "%s\n" {+}'
            '--preview-label=Selected protocols'
        )
        protocol=$(printf "%s\n" "${protocals[@]}" | fzf "${_fzf_flags[@]}" | cut -d: -f1 | xargs -rd'\n' printf '%s,')
    else
        _question "What protocol should the mirror use? (Comma Sperated)" "Default: https"
        read -r protocol
    fi
    _check_val "You must provide at least one protocol." "$protocol" || return 1

    if command -v fzf &>/dev/null; then
        local sort_types=(age rate country score rsync)
        local _fzf_flags=('--prompt=Sorting type: ' '--header=Use <Tab> key for selecting multiple')
        sort=$(printf "%s\n" "${sort_types[@]}" | fzf "${_fzf_flags[@]}")
    else
        _question "What type of sorting should be used" "Default: score"
        read -r sort
    fi
    _check_val "You must provide at a sorting type." "$sort" || return 1

    printf "%s\n" "$selected_countries" "$age" "$protocol" "$sort" >"$REFLECTOR_CONFIG_PATH"

    unfunction _question
    unfunction _check_val
}

function _pacman_update_mirror_list() {
    if ! command -v reflector &>/dev/null; then
        _pac_print_red "Install reflector to use REFLECTOR(1)."
        return
    fi

    local REFLECTOR_CONFIG_PATH="$HOME/.reflector"

    if [[ ! -f $REFLECTOR_CONFIG_PATH || "$1" == "-u" || "$1" == "--update-options" ]]; then
        if _pacman_get_reflector_opts; then
            {
                IFS=$'\n'
                read -r selected_countries
                read -r age
                read -r protocol
                read -r sort
            } <"$REFLECTOR_CONFIG_PATH"
        else
            _pac_print_red "Failed to get reflector options"
            return 1
        fi
    else
        {
            IFS=$'\n'
            read -r selected_countries
            read -r age
            read -r protocol
            read -r sort
        } <"$REFLECTOR_CONFIG_PATH"
    fi

    if [[ -z $selected_countries || -z $age || -z $protocol || -z $sort ]]; then
        _pac_print_red "Failed to load reflector options"
    fi

    _pac_print_prompt "You like to create an backup of exist mirror-list" "y/n"

    read -r backup_create
    if [[ -z "$backup_create" || $backup_create =~ ^[Yy]$ ]]; then
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.pac_backup
    fi

    _pac_print_green "Update mirrorlist using following reflector options: "
    echo "Country: $selected_countries"
    echo "Age: $age"
    echo "Protocol: $protocol"
    echo "Sort: $sort"

    sudo reflector --verbose --country="$selected_countries" --age="$age" --protocol="$protocol" --sort="$sort" --save /etc/pacman.d/mirrorlist

    _pac_print_cyan "$(_pac_print_bold 'This is your new mirrorlist: ')"
    cat /etc/pacman.d/mirrorlist

}
