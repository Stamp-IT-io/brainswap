source "$(dirname "${BASH_SOURCE[0]}")/debug.sh"

ACCESS_SPEC_REGEX='^((.+),)?(((([^,@]+)@)?([^,@:]+))(:([^,:]+))?)$'

# Internal function
function _get_access_spec_part () {
	local access_spec
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	part=$2						# Parenthesis number in the regex

	if [ -z "$access_spec" ]; then
		print_error_stack_exit "empty access_spec"
	fi

	echo "$access_spec" | sed -nE "s/${ACCESS_SPEC_REGEX}/\\${part}/; T bad; p; q0; :bad; q2"
	if [ $? == 2]; then
		print_error_stack_exit "bad acces_spec: $1"
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
	_get_access_spec_part "$1" 4
}

# Returns the host part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_remote_host () {
	_get_access_spec_part "$1" 7
}

# Returns the port part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_remote_port () {
	_get_access_spec_part "$1" 9
}


