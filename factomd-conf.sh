# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

source "$(dirname "${BASH_SOURCE[0]}")/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/parse.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ssh.sh"

FACTOMD_CONF_PATH="/var/lib/docker/volumes/factom_keys/_data/factomd.conf"

function get_factomd_conf_path() {
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	# For now, config path is constant, but in the future it could be different on different nodes
	remote_node=$(get_remote_spec $access_spec)
	print_error_stack_exit_if_failed "Cannot get remote node: bad or empty spec" 1

	echo $FACTOMD_CONF_PATH
}

function get_factomd_conf() {
	local sudo access_spec remote_node conf_content return_value

	# Also honors QUIET=1 global variable
	if [ "$1" == "--sudo" ]; then
		sudo="--sudo"
		shift
	fi
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	remote_node=$(get_remote_spec $access_spec)

	[ "$QUIET" != 1 ] && echo "Getting $FACTOMD_CONF_PATH from $remote_node..." >&2

	# Obtain config from remote_node
	conf_content="$(do_ssh $access_spec $sudo cat $FACTOMD_CONF_PATH)"

	if [ "$?" -ne 0 ]; then
		print_error_stack_exit "cannot connect to $remote_node or factomd.conf not readable. (try --sudo ?)"
	fi

	echo "$conf_content"
}

function put_factomd_conf() {
	local sudo access_spec remote_node conf_content return_value

	# Also honors QUIET=1 global variable
	if [ "$1" == "--sudo" ]; then
		sudo="--sudo"
		shift
	fi
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	conf_content="$2"

	remote_node=$(get_remote_spec $access_spec)

	[ "$QUIET" != 1 ] && echo "Overwriting $FACTOMD_CONF_PATH on $remote_node..." >&2

	# Obtain config from remote_node
	do_ssh $sudo $1 sh -c '"cat >'"$FACTOMD_CONF_PATH"'"' <<<"$conf_content"
	print_error_stack_exit_if_failed "cannot connect to $remote_node or factomd.conf not writable. (try --sudo ?)"

	return 0
}

function extract_conf_keys() {
	local prefix SED_NET_SCRIPT SED_ID_SCRIPT SED_PRIV_SCRIPT SED_PUB_SCRIPT SED_CAH_SCRIPT remote_node conf_content Net

	# Also honors QUIET=1 global variable
	prefix=$1
	conf_content="$(cat)"	# Reads config from stdin

	# sed script to extract Network
	SED_NET_SCRIPT='s/^[[:space:]]*Network[[:space:]]*=[[:space:]]*\(\([0-9a-zA-Z]\)*\)[^0-9a-zA-Z]*$/\1/pI'

	# sed script to extract IdentityChainID
	SED_ID_SCRIPT='s/^[[:space:]]*IdentityChainID[[:space:]]*=[[:space:]]*\(\([0-9a-zA-Z]\)*\)[^0-9a-zA-Z]*$/\1/pI'

	# sed script to extract LocalServerPrivKey
	SED_PRIV_SCRIPT='s/^[[:space:]]*LocalServerPrivKey[[:space:]]*=[[:space:]]*\(\([0-9a-zA-Z]\)*\)[^0-9a-zA-Z]*$/\1/pI'

	# sed script to extract LocalServerPublicKey
	SED_PUB_SCRIPT='s/^[[:space:]]*LocalServerPublicKey[[:space:]]*=[[:space:]]*\(\([0-9a-zA-Z]\)*\)[^0-9a-zA-Z]*$/\1/pI'

	# sed script to extract ChangeAcksHeight
	SED_CAH_SCRIPT='s/^[[:space:]]*ChangeAcksHeight[[:space:]]*=[[:space:]]*\(\([0-9]\)*\)[^0-9a-zA-Z]*$/\1/pI'

	if ! echo "$prefix" | grep -q "^[a-zA-Z0-9]*$"; then
		print_error_stack_exit "invalid prefix ($prefix)" >&2
	fi

	# Extract Network from config
	Net="$(echo "$conf_content" | sed -n $SED_NET_SCRIPT)"
	eval ${prefix}_Net='${Net:-MAIN}'

	# Extract Identity from config
	eval ${prefix}'_IdCId_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*IdentityChainID')"
	eval ${prefix}'_IdCId=$(echo $'${prefix}'_IdCId_line | sed -n $SED_ID_SCRIPT)'
	eval ${prefix}'_IdCId_short=$(echo $'${prefix}'_IdCId | cut -c 7-12)'
	eval ${prefix}'_LSPrivK_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*LocalServerPrivKey')"
	eval ${prefix}'_LSPrivK=$(echo $'${prefix}'_LSPrivK_line | sed -n $SED_PRIV_SCRIPT)'
	eval ${prefix}'_LSPubK_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*LocalServerPublicKey')"
	eval ${prefix}'_LSPubK=$(echo $'${prefix}'_LSPubK_line | sed -n $SED_PUB_SCRIPT)'
	eval ${prefix}'_CAH_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*ChangeAcksHeight')"
	eval ${prefix}'_CAH=$(echo $'${prefix}'_CAH_line | sed -n $SED_CAH_SCRIPT)'

	# Ensure $_IdCId looks like an identity chain Id
	if ! eval echo '$'${prefix}_IdCId | egrep -q "^$|^[0-9a-fA-F]{64}$"; then
		eval print_error_stack_exit "\"Id \$${prefix}_IdCId does not look like an identity chain Id.\""
	fi

	# Ensure $_LSPubK looks like a public key
	if ! eval echo '$'${prefix}_LSPubK | egrep -q "^$|^[0-9a-fA-F]{64}$"; then
		eval print_error_stack_exit "\"Public key \$${prefix}_LSPubK does not look like a public key.\""
	fi

	# Ensure $_LSPrivK looks like a private key
	if ! eval echo '$'${prefix}_LSPrivK | egrep -q "^$|^[0-9a-fA-F]{64}$"; then
		eval print_error_stack_exit "\"Private key \$${prefix}_LSPrivK does not look like a private key.\""
	fi
	
	# Ensure $_CAH looks like a block number
	if eval "test \"\$${prefix}_CAH_line\" != '' -a \"\$${prefix}_CAH\" == ''" ; then
		eval print_error_stack_exit "\"\$${prefix}_CAH_line does not look like a block number.\""
	fi

	eval ${prefix}'_CAH=${'${prefix}'_CAH:-0}'
	
	return 0
}

function get_factomd_keys() {
	local sudo access_spec prefix conf_content

	# Also honors QUIET=1 global variable
	if [ "$1" == "--sudo" ]; then
		sudo="--sudo"
		shift
	fi
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	prefix=$2

	# Obtain config from remote_node
	eval 'conf_content="$(get_factomd_conf $sudo $access_spec)"'
	print_error_stack_exit_if_failed "get_factomd_conf failed."
	eval 'extract_conf_keys $prefix <<<"$conf_content"'

	return 0
}

function ensure_factomd_conf_writable() {
	local sudo access_spec prefix remote_node

	# Also honors QUIET=1 global variable
	if [ "$1" == "--sudo" ]; then
		sudo="--sudo"
		shift
	fi
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port

	remote_node=$(get_remote_spec $access_spec)

	[ "$QUIET" != 1 ] && echo "Checking $FACTOMD_CONF_PATH is writable on $remote_node..." >&2
	
	if ! do_ssh $access_spec $sudo test -w $FACTOMD_CONF_PATH; then
		print_error_stack_exit "cannot connect to $remote_node or $FACTOMD_CONF_PATH not writable. (try --sudo ?)"
	fi
	
	return 0
}

function replace_conf_identity() {
	local IdCId LSPrivK LSPubK CAH dos IdCId_line LSPrivK_line LSPubK_line CAH_line conf_orig conf_cleaned conf_result CONF_APPEND

	# Also honors QUIET=1 global variable
	conf_orig="$1"
	IdCId="$2"
	LSPrivK="$3"
	LSPubK="$4"
	CAH="$5"

	# Check the first line to determine line ending
	dos=""
	if [ "$(head -n1 <<<"$conf_orig" | tail -c2)" == $'\r' ]; then
		dos=$'\r'
	fi

	# Ensure $_IdCId looks like an identity chain Id
	if [[ "$IdCId$LSPrivK$LSPubK" == "" ]]; then
		IdCId_line=""
		LSPrivK_line=""
		LSPubK_line=""
	else
		# If one of IdChain, Public key or Private key has a value, they must all have a value
		if [[ "$IdCId" =~ ^[0-9a-fA-F]{64}$ ]]; then
			# We add a backslash and a newline because the lines will be inserted in an append command of a sed script
			IdCId_line="IdentityChainID       = $IdCId$dos\\"$'\n'
		else
			print_error_stack_exit "Id Chain Id $IdCId does not look like an identity chain Id."
		fi

		# Ensure $_LSPubK looks like a public key
		if [[ "$LSPubK" =~ ^[0-9a-fA-F]{64}$ ]]; then
			# We add a backslash and a newline because the lines will be inserted in an append command of a sed script
			LSPubK_line="LocalServerPublicKey  = $LSPubK$dos\\"$'\n'
		else
			print_error_stack_exit "Public key $LSPubK does not look like a public key."
		fi

		# Ensure $_LSPrivK looks like a private key
		if [[ "$LSPrivK" =~ ^[0-9a-fA-F]{64}$ ]]; then
			# We add a backslash and a newline because the lines will be inserted in an append command of a sed script
			LSPrivK_line="LocalServerPrivKey    = $LSPrivK$dos\\"$'\n'
		else
			print_error_stack_exit "Private key $LSPrivK does not look like a private key."
		fi
	fi

	# Ensure $_CAH looks like a block number
	if [[ "$CAH" == "" ]]; then
		# no backslash because it is the last line of the sed script's append command
		CAH_line="ChangeAcksHeight      = 0$dos"$'\n'
	elif [[ "$CAH" =~ ^[0-9]{1,9}$ ]]; then
		CAH_line="ChangeAcksHeight      = $CAH$dos"$'\n'
	else
		print_error_stack_exit "Height $CAH does not look like a block number."
	fi

	# Find the place where the new identity will be inserted in config file (CONF_APPEND is a sed script)
	if grep -q -i '^[[:space:]]*;*[[:space:]]*BRAINSWAP_ID_BELOW' <<<"$conf_orig"; then
		CONF_APPEND='/^[[:space:]]*;*[[:space:]]*BRAINSWAP_ID_BELOW/a\'
	else
		if grep -q -i '^[[:space:]]*\[app\]' <<<"$conf_orig"; then
			CONF_APPEND='/^[[:space:]]*\[app\]/a\'
		else
			print_error_stack_exit "$node1 factomd.conf has neither [app] section nor commented line with BRAINSWAP_ID_BELOW."
		fi
	fi

	# Generating new factomd.conf
	conf_cleaned=$(egrep -i -v '^[[:space:]]*IdentityChainID|^[[:space:]]*LocalServerPrivKey|^[[:space:]]*LocalServerPublicKey|^[[:space:]]*ChangeAcksHeight' <<<"$conf_orig")
	print_error_stack_exit_if_failed "grep failed"
	conf_result=$(sed "$CONF_APPEND"$'\n'"$IdCId_line$LSPrivK_line$LSPubK_line$CAH_line" <<<"$conf_cleaned")
	print_error_stack_exit_if_failed "sed script failed"

	echo "$conf_result"
}
