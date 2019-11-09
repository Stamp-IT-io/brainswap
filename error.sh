# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

function must_succeed() {
	local return_value

	eval $1
	return_value=$?
	if [ "$return_value" != "0" ]; then
		print_error_stack_exit "Command failed: $1" $return_value
	fi
}

function get_stack () {
	# to avoid noise we start with 1 to skip get_stack caller
	local i
	echo "${BASH_SOURCE[1]}: ${FUNCNAME[1]}:${BASH_LINENO[0]}"
	for (( i=2; i<${#FUNCNAME[@]} ; i++ )); do
		echo "${BASH_SOURCE[$i]}: ${FUNCNAME[$i]}:${BASH_LINENO[(($i-1))]}"
	done
}

function print_error_stack_exit () {
	echo "Error: $1" >&2
	echo "Stack:" >&2
	# sed script to add indentation
	get_stack | sed 's/^.*$/\t\0/' >&2
	exit ${2:-1}	# 1 is the default exit code
}

function print_error_stack_exit_if_failed() {
	# Before anything else, we must save the last return value
	_peseif_last_return_value=$?

	if [ "$_peseif_last_return_value" != "0" ]; then
		# Cannot declare local before because it would change $?
		local message return_value
		message="${1:-"Command failed"}"
		return_value="${2:-$_peseif_last_return_value}"
		print_error_stack_exit "$message" $return_value
	fi

	return 0
}

