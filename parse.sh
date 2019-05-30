source "$(dirname "${BASH_SOURCE[0]}")/error.sh"

ACCESS_SPEC_REGEX='^((.+),)?((([^,@]+)@)?([^,@:]+)(:([^,:]+))?)$'

# Internal function
function _get_access_spec_part () {
	local access_spec parts
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	# Next parameters are parentheses number in the regex
	parts=
	while [ -n "$2" ]; do
		if [ "$2" -ge 1 -a "$2" -le 9 ]; then
			parts="$parts\\$2"
			shift
		else
			print_error_stack_exit "not a valid part of regex: $2"
		fi
	done

	if [ -z "$access_spec" ]; then
		print_error_stack_exit "empty parts"
	fi

	if [ -z "$access_spec" ]; then
		print_error_stack_exit "empty access_spec"
	fi

	echo "$access_spec" | sed -nE "s/${ACCESS_SPEC_REGEX}/${parts}/; T bad; p; q0; :bad; q2"
	if [ $? == 2 ]; then
		print_error_stack_exit "bad acces_spec: ${access_spec}" 2
	fi
}

# Returns the jumpuser@jumphost:jumpport part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_jump_spec () {
	_get_access_spec_part "$1" 2
}

# Returns the user@host:port part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_remote_spec () {
	_get_access_spec_part "$1" 3
}

# Returns the user@host
function get_remote_userhost () {
	_get_access_spec_part "$1" 4 6
}

# Returns the host part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_remote_host () {
	_get_access_spec_part "$1" 6
}

# Returns the port part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_remote_port () {
	_get_access_spec_part "$1" 8
}


