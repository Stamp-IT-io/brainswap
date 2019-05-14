# Returns the user@host:port part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_remote_spec () {
	local access_spec
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	if [ -z "$access_spec" ]; then
		echo "$0/get_remote_spec: empty access_spec" >&2
		return 1
	fi

	echo "$access_spec" | sed -n "s/^.*,\([^,]*\)$/\1/; p"
}

# Returns the jumpuser@jumphost:jumpport part of a jumpuser@jumphost:jumpport,user@host:port specification
function get_jump_spec () {
	local access_spec
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	if [ -z "$access_spec" ]; then
		echo "$0/get_remote_spec: empty access_spec" >&2
		return 1
	fi

	echo "$access_spec" | sed -n "s/^\(.*\),[^,]*$/\1/; p"
}

function get_remote_host () {
	local access_spec remote_host
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	remote_host="$(get_remote_spec $access_spec)"

	remote_host="${remote_host#*@}"
	remote_host="${remote_host%:*}"

	echo "$remote_host"
}


