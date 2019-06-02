# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

source "$(dirname "${BASH_SOURCE[0]}")/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/parse.sh"

function do_ssh () {
	local jump_spec jump_arg remote_userhost remote_port remote_port_arg
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	shift

	if [ -z "$*" ]; then
		print_error_stack_exit "no command to execute ($*)"
	fi

	# Extract jump host, if applicable
	jump_spec="$(get_jump_spec ${access_spec})"
	jump_arg="${jump_spec:+-J $jump_spec}"

	remote_userhost="$(get_remote_userhost ${access_spec})"

	remote_port="$(get_remote_port ${access_spec})"
	remote_port_arg="${remote_port:+-J $remote_port}"

	ssh $jump_arg $remote_userhost $remote_port_arg "$@"
}


