#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/factomd-conf.sh"
source "$(dirname "${BASH_SOURCE[0]}")/factomd-status.sh"

function brainswap_get_node1_conf() {
	for v in node1; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Obtain config from node1
	node1_conf="$(get_factomd_conf $sudo1 $node1)"; exit_if_failed
	extract_conf_keys node1 <<<"$node1_conf"
}

function brainswap_ensure_identity_complete_node1() {
	for v in node1_IdCId_line node1_LSPrivK_line node1_LSPubK_line; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Ensure an identiy is in node1 config file
	if [ -z "$node1_IdCId_line" -o -z "$node1_LSPrivK_line" -o -z "$node1_LSPubK_line" ]; then
		# Technically, we could do a brainswap, but it is probably not what is intended
		print_error_stack_exit "$node1 has incomplete identity set in factomd.conf."
	fi
}

function brainswap_ensure_authority_and_ready_node1() {
	for v in node1_factomd_flags; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Ensure node1 is an authority node and operating
	if [ "$node1_factomd_flags" != "A___" -a "$node1_factomd_flags" != "L___" ]; then
		# We could do a brainswap, but it is probably not what is intended
		print_error_stack_exit "$node1 is not an authority node (or in ignore mode) no need for brainswap ($node1_factomd_flags)."
	fi
}

function brainswap_ensure_process_list_complete_node1() {
	for v in node1_factomd_pl_stats; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Ensure there is no <nil> in the process list of node1
	if [ "$node1_factomd_pl_stats" != "OKOKOK" ]; then
		print_error_stack_exit "$node1 process list is incomplete, there might be some network instability ($node1_factomd_pl_stats)."
	fi
}

function brainswap_ensure_no_brainswap_pending_node1() {
	for v in node1_factomd_nextheight node1_CAH; do
		test -v "$v"
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	# Ensure no brainswap is pending on node 1
	if [ "$node1_factomd_nextheight" -le "$node1_CAH" ]; then
		print_error_stack_exit "$node1 next height $node1_factomd_nextheight is not greater than config ChangeAcksHeight $node1_CAH (pending brainswap?)"
	fi
}

function brainswap_ensure_not_minute_0_node1() {
	for v in node1_factomd_minute; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	# During minute 0 we cannot tell if the nodes are really following minutes, so we do not initiate a brainswap
	if [ "$node1_factomd_minute" -eq "0" ]; then
		print_error_stack_exit "$node1 in minute 0, wait for one minute and try again."
	fi
}

function brainswap_get_node2_conf() {
	for v in node2; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Obtain config from node2
	node2_conf="$(get_factomd_conf $sudo2 $node2)"; exit_if_failed
	extract_conf_keys node2 <<<"$node2_conf"
}


function brainswap_ensure_same_network() {
	for v in node1_Net node2_Net; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" != "''"
		print_error_stack_exit_if_failed "Assertion failed: $v empty"
	done

	# Ensure node1 and node 2 are on the same network
	if [ "$node1_Net" != "$node2_Net" ]; then
		print_error_stack_exit "$node1 and $node2 are on two different networks, cannot brainswap."
	fi
}

function brainswap_ensure_not_same_identity() {
	for v in node1_IdCId node2_IdCId; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	if [ "$node1_IdCId" = "$node2_IdCId" ]; then
		print_error_stack_exit "$node1 and $node2 have the same identity in their config files. (Same node?)"
	fi
}

function brainswap_ensure_ready_node2() {
	for v in node2_factomd_flags; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Ensure node2 is ready for brainswap (not in WAIT / IGNORE)
	if [ "$node2_factomd_flags" != "A___" -a "$node2_factomd_flags" != "L___" -a "$node2_factomd_flags" != "____" ]; then
		print_error_stack_exit "$node2 is not ready for brainswap ($node2_factomd_flags)."
	fi
}

function brainswap_ensure_process_list_complete_node2() {
	for v in node2_factomd_pl_stats; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	# Ensure there is no <nil> in the process list of node2
	if [ "$node2_factomd_pl_stats" != "OKOKOK" ]; then
		print_error_stack_exit "$node2 process list is incomplete, there might be some network instability ($node2_factomd_pl_stats)."
	fi
}

function brainswap_ensure_no_brainswap_pending_node2() {
	for v in node2_factomd_nextheight node2_CAH; do
		test -v "$v"
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	# Ensure no brainswap is pending on node 2
	if [ "$node2_factomd_nextheight" -le "$node2_CAH" ]; then
		print_error_stack_exit "$node2 next height $node2_factomd_nextheight is not greater than config ChangeAcksHeight $node2_CAH (pending brainswap?)"
	fi
}

function brainswap_ensure_same_block_height() {
	for v in node1_factomd_nextheight node2_factomd_nextheight; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	# Ensure node1 and node2 are on the same block height
	if [ "$node1_factomd_nextheight" != "$node2_factomd_nextheight" ]; then
		print_error_stack_exit "$node1 and $node2 are not on the same block (next: $node1_factomd_nextheight, $node2_factomd_nextheight) try again in a few seconds."
	fi
}

function brainswap_ensure_same_minute() {
	for v in node1_factomd_minute node2_factomd_minute; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	# Ensure node1 and node2 are on the same minute
	if [ "$node1_factomd_minute" != "$node2_factomd_minute" ]; then
		print_error_stack_exit "$node1 and $node2 are not on the same minute ($node1_factomd_minute, $node2_factomd_minute) try again in a few seconds."
	fi
}

function brainswap_calculate_safe_swap_height() {
	for v in node1_factomd_minute node1_factomd_nextheight; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	local change_height BLOCK_DELAY
	BLOCK_DELAY=0

	change_height=$node1_factomd_nextheight
	if [ "$node1_factomd_minute" -eq 9 ]; then
		# If we are on minute 9, we are too close to next block, we wait for one more block
		change_height=$(($change_height + 1))
	fi
	# Add a delay of a few blocks?
	change_height=$(($change_height + $BLOCK_DELAY))

	echo $change_height
}

function brainswap_calculate_swap_wait_minutes() {
	for v in node1_factomd_minute node1_factomd_nextheight; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
		eval test "\$$v" -ge 0
		print_error_stack_exit_if_failed "Assertion failed: $v not a positive integer"
	done

	local change_height swap_wait
	change_height=$1

	if ! [ "$change_height" -gt 0 ]; then
		print_error_stack_exit "$change_height is not a valid block number (height must be passed as first argument)"
	fi

	# Calculate number of minutes before swap
	swap_wait=$(( ($change_height - $node1_factomd_nextheight + 1) * 10 - $node1_factomd_minute))

	echo $swap_wait
}

function brainswap_simulate_brainswap() {
	for v in node1_conf node1_IdCId node1_LSPrivK node1_LSPubK node2_conf node2_IdCId node2_LSPrivK node2_LSPubK node1 node2; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	local change_height swap_wait new_conf1 new_conf2
	change_height=$1

	if ! [ "$change_height" -gt 0 ]; then
		print_error_stack_exit "$change_height is not a valid block_number (height must be passed as first argument)"
	fi

	# Generating new factomd.conf for node1
	new_conf1="$(replace_conf_identity "$node1_conf" "$change_height" "$node2_IdCId" "$node2_LSPrivK" "$node2_LSPubK")"

	# Generating new factomd.conf for node2
	new_conf2="$(replace_conf_identity "$node2_conf" "$change_height" "$node1_IdCId" "$node1_LSPrivK" "$node1_LSPubK")"

	if [ "$QUIET" != 1 ]; then
		echo "--------" >&2
		echo "Node1: $node1:" >&2
		diff -u <(echo "$node1_conf") <(echo "$new_conf1") >&2
		echo "--------" >&2
		echo "Node2: $node2:" >&2
		diff -u <(echo "$node2_conf") <(echo "$new_conf2") >&2
		echo "--------" >&2
	fi
}

function brainswap_do_brainswap() {
	for v in node1_conf node1_IdCId node1_LSPrivK node1_LSPubK node2_conf node2_IdCId node2_LSPrivK node2_LSPubK; do
		test -v $v
		print_error_stack_exit_if_failed "Assertion failed: $v not set"
	done

	local change_height new_conf1 new_conf2 conf_path
	change_height=$1

	if ! [ "$change_height" -gt 0 ]; then
		print_error_stack_exit "$change_height is not a valid block_number (height must be passed as first argument)"
	fi

	# Last check to make sure change_height value is sane (brainswap should be effective in less than an hour)
	if ! [ "$(brainswap_calculate_swap_wait_minutes $change_height)" -lt 60 ]; then
		print_error_stack_exit "Block $change_height is too far in the future, not a good idea"
	fi

	# Generating new factomd.conf for node1
	new_conf1="$(replace_conf_identity "$node1_conf" "$change_height" "$node2_IdCId" "$node2_LSPrivK" "$node2_LSPubK")"

	# Generating new factomd.conf for node2
	new_conf2="$(replace_conf_identity "$node2_conf" "$change_height" "$node1_IdCId" "$node1_LSPrivK" "$node1_LSPubK")"

	[ "$QUIET" != 1 ] && echo "Rewriting factomd.conf on $node1..." >&2
	conf_path=$(get_factomd_conf_path $node1)			# We obtain the path in advance to avoid interference with return values
	(put_factomd_conf $sudo1 $node1 "$new_conf1" 2>/dev/null)	# We replace the error message, if any (subshell to prevent exit)
	print_error_stack_exit_if_failed "$0: Error overwriting $conf_path on $node1, BRAINSWAP FAILED, you must check that config was not overwritten."

	[ "$QUIET" != 1 ] && echo "Rewriting factomd.conf on $node2..." >&2
	conf_path=$(get_factomd_conf_path $node2)			# We obtain the path in advance to avoid interference with return values
	(put_factomd_conf $sudo2 $node2 "$new_conf2" 2>/dev/null)	# We replace the error message, if any (subshell to prevent exit)
	print_error_stack_exit_if_failed "$0: Error overwriting $conf_path on $node2, BRAINSWAP FAILED, you must check that both nodes do not have the same identity."
}
