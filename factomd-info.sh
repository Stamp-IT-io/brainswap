# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

source "$(dirname "${BASH_SOURCE[0]}")/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/parse.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ssh.sh"

function get_factomd_info() {
	local access_spec prefix remote_node WGET_FACTOMD_INDEX SED_VERSION_SCRIPT index

	# Also honors QUIET=1 global variable
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	prefix=$2
	if ! echo "$prefix" | grep -q "^[a-zA-Z0-9]*$"; then
		print_error_stack_exit "invalid prefix ($prefix)" >&2
	fi


	WGET_FACTOMD_INDEX="wget -q -O - \"http://127.0.0.1:8090/\""
	SED_VERSION_SCRIPT='s!^.*<h1[^>]*>\(.*\) <small>\([^<]*\)</small>.*Git Build: \([a-f0-9]*\)[^a-f0-9].*$!\2 \3!p'

	remote_node=$(get_remote_spec $access_spec)

	[ "$QUIET" != 1 ] && echo "Getting factomd version from $remote_node..." >&2

	index=$(do_ssh $access_spec $WGET_FACTOMD_INDEX)
	if [ "$?" -ne 0 ]; then
		print_error_stack_exit "Cannot get control panel home page from $remote_node."
	fi

	version_build=$(echo "$index" | sed -n "$SED_VERSION_SCRIPT")
	if [ "$?" -ne 0 ]; then
		print_error_stack_exit "sed failed while parsing version string of factomd index from $remote_node."
	fi
	if ! echo "$version_build" | grep -q '^[^ ]* [^ ]*$'; then
		print_error_stack_exit "Cannot parse version string of factomd index from $remote_node."
	fi

	read ${prefix}_factomd_version ${prefix}_factomd_build <<<"$version_build"

	if ! eval echo "\$${prefix}_factomd_version" | grep -q '^v[0-9]*[.][0-9]*[.][0-9]*'; then
		eval print_error_stack_exit "\"Version from $remote_node has an unexpected format: \$${prefix}_factomd_version.\""
	fi
}


function get_factomd_version() {
	local access_spec gfv_factomd_version gfv_factomd_build

	# Also honors QUIET=1 global variable
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	get_factomd_info "$access_spec" gfv

	echo "$gfv_factomd_version"
}

