# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

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

