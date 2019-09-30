# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

source "$(dirname "${BASH_SOURCE[0]}")/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/parse.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ssh.sh"

function get_factomd_details() {
	local access_spec prefix remote_node WGET_DETAILS SED_DETAILS_SCRIPT details dump

	# Also honors QUIET=1 global variable
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	prefix=$2
	if ! [[ "$prefix" =~ ^[a-zA-Z]*$ ]]; then
		print_error_stack_exit "Invalid prefix ($prefix)"
	fi

	# Command to get details about locally running factomd
	WGET_DETAILS="wget -q -O - \"http://127.0.0.1:8090/factomd?item=dataDump&value=\""

	# sed script to extract useful informations about factomd state
	SED_DETAILS_SCRIPT='
  s!.*===SummaryStart===......FNode0\[......\] \(....\).\{20,44\} \([0-9]\{5,7\}\)\[\([0-9a-f]\{6\}\)\] \([0-9]\{5,7\}\)/\([0-9]\{5,7\}\)/\([0-9]\{5,7\}\) .../.\(.\).*===SummaryEnd===!\1 \2 \3 \4 \5 \6 \7 __NEXT__!;
  s!__NEXT__.*"NextDump":"===ProcessListStart===[^"]*\(\\u003cnil\\u003e\)[^"]*===ProcessListEnd===!NextNil__RAW__!;
  s!__NEXT__.*"NextDump":"===ProcessListStart===[^"]*===ProcessListEnd===!OK__RAW__!;
  s!__NEXT__!NoNextDump__RAW__!;
  s!__RAW__.*"RawDump":"===ProcessListStart===[^"]*\(\\u003cnil\\u003e\)[^"]*===ProcessListEnd===!RawNil__PREV__!;
  s!__RAW__.*"RawDump":"===ProcessListStart===[^"]*===ProcessListEnd===!OK__PREV__!;
  s!__RAW__!NoRawDump__PREV__!;
  s!__PREV__.*"PrevDump":"===ProcessListStart===[^"]*\(\\u003cnil\\u003e\)[^"]*===ProcessListEnd===.*!PrevNil!;
  s!__PREV__.*"PrevDump":"===ProcessListStart===[^"]*===ProcessListEnd===.*!OK!;
  s!__PREV__.*!NoPrevDump!;
  p'

	remote_node=$(get_remote_spec $access_spec)

	[ "$QUIET" != 1 ] && echo "Getting factomd details from $remote_node..." >&2

	# Obtain information about factomd
	dump="$(do_ssh $access_spec $WGET_DETAILS)"
	if [ "$?" != 0 ]; then
		print_error_stack_exit "Cannot get dump of factomd from $remote_node, factomd is most likely not running or not ready."
	fi

	details=$(echo "$dump" | sed -n "$SED_DETAILS_SCRIPT")

	if [ "$details" == "" ]; then
		print_error_stack_exit "Cannot parse dump of factomd from $remote_node."
	fi

	if ! echo "$details" | egrep '^[^ ]{4} [0-9]* [0-9a-f]* [0-9]* [0-9]* [0-9]* [0-9]' >/dev/null; then
		print_error_stack_exit "Cannot parse details string of factomd from $remote_node ($details)."
	fi

	# Extract information about factomd
	eval read ${prefix}_factomd_flags ${prefix}_factomd_savedheight ${prefix}_factomd_savedheight_mr ${prefix}_factomd_prevheight ${prefix}_factomd_currheight ${prefix}_factomd_nextheight ${prefix}_factomd_minute ${prefix}_factomd_pl_stats <<<$details
}


function get_factomd_home() {
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

	get_factomd_home "$access_spec" gfv

	echo "$gfv_factomd_version"
}


