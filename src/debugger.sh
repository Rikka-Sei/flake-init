#!/usr/bin/env bash

# debug levels
# info: information
# success: successful
# warn: warning
# error: errors
debug="info"

convert_level() {
	case $1 in
		log)
			return 1
			;;
		info)
			return 2
			;;
		success)
			return 3
			;;
		warn)
			return 4
			;;
		error)
			return 5
			;;
		line)
			return 6
			;;
		*)
			return 0
			;;
	esac
}

debuger() {
	convert_level $debug
	option_level=$?

	convert_level $1
	input_level=$?

	if [ "$option_level" -eq 0 ] || [ "$input_level" -eq 0 ]; then
		echo -e "[\033[31mInner Error\033[0m] Please check your shell script"
		echo -e "Input Str:"
		echo -e "1: $1"
		echo -e "2: $2"
		echo -e "3: $3"
		exit 1
	fi

	if [ "$input_level" -ge "$option_level" ]; then
		case $1 in
			log)
				echo -e "[\033[48;5;235m\033[93m$2\033[0m] $3"
				return 0
			;;
			info)
				echo -e "[\033[37m$2\033[0m] $3"
				return 0
				;;
			success)
				echo -e "[\033[32m$2\033[0m] $3"
				return 0
				;;
			warn)
				echo -e "[\033[33m$2\033[0m] $3"
				return 0
				;;
			error)
				echo -e "[\033[31m$2\033[0m] $3"
				return 0
				;;
			line)
				echo ""
				return 0
				;;
			*)
				echo -e "[\033[31mInner Error\033[0m] Please check your shell script"
				echo -e "Input Str:"
				echo -e "1: $1"
				echo -e "2: $2"
				echo -e "3: $3"
				exit 1
				;;
		esac
	fi
}

check_success() {
	if [ $? -ne 0 ]; then
        debuger error "Fail" "$1"
        exit 1
    else
        debuger success "OK" "$1"
    fi
}
