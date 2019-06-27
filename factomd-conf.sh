# Stamp-IT brainswap  Copyright 2018 Stamp-IT Blockchain Solution inc.

source "$(dirname "${BASH_SOURCE[0]}")/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/parse.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ssh.sh"

CONF_PATH="/var/lib/docker/volumes/factom_keys/_data/factomd.conf"

function get_factomd_conf() {
	local sudo access_spec prefix SED_NET_SCRIPT SED_ID_SCRIPT SED_PRIV_SCRIPT SED_PUB_SCRIPT SED_CAH_SCRIPT remote_node conf_content Net

	# Also honors QUIET=1 global variable
	if [ "$1" == "--sudo" ]; then
		sudo="--sudo"
		shift
	fi
	access_spec=$1 					# e.g. jumpuser@jumphost:jumpport,user@host:port
	prefix=$2

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

	remote_node=$(get_remote_spec $access_spec)

	[ "$QUIET" != 1 ] && echo "Getting $CONF_PATH from $remote_node..." >&2

	# Obtain config from remote_node
	conf_content="$(do_ssh $access_spec $sudo cat $CONF_PATH)"

	if [ "$?" -ne 0 ]; then
		print_error_stack_exit "cannot connect to $remote_node or factomd.conf not readable. (try --sudo ?)"
	fi

	# Extract Network from remote_node
	Net="$(echo "$conf_content" | sed -n $SED_NET_SCRIPT)"
	eval ${prefix}_Net='${Net:-MAIN}'

	# Extract Identity from remote_node
	eval ${prefix}'_conf="$conf_content"'
	eval ${prefix}'_IdCId_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*IdentityChainID')"
	eval ${prefix}'_IdCId=$(echo $'${prefix}'_IdCId_line | sed -n $SED_ID_SCRIPT)'
	eval ${prefix}'_IdCId_short=$(echo $'${prefix}'_IdCId | cut -c 7-12)'
	eval ${prefix}'_LSPrivK_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*LocalServerPrivKey')"
	eval ${prefix}'_LSPrivK=$(echo $'${prefix}'_LSPrivK_line | sed -n $SED_PRIV_SCRIPT)'
	eval ${prefix}'_LSPubK_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*LocalServerPublicKey')"
	eval ${prefix}'_LSPubK=$(echo $'${prefix}'_LSPubK_line | sed -n $SED_PUB_SCRIPT)'
	eval ${prefix}'_CAH_line=$(echo "$conf_content" | '"grep -i '^[[:space:]]*ChangeAcksHeight')"
	eval ${prefix}'_CAH=$(echo $'${prefix}'_CAH_line | sed -n $SED_CAH_SCRIPT)'
	eval ${prefix}'_CAH=${'${prefix}'_CAH:-0}'

	# Ensure $_IdCId looks like an identity chain Id
	if ! eval echo '$'${prefix}_IdCId | egrep -q "^$|^[0-9a-fA-F]{64}$"; then
		print_error_stack_exit "$node1 Id $node1_IdCId does not look like an identity chain Id."
	fi

	# Ensure $_LSPubK looks like a public key
	if ! eval echo '$'${prefix}_LSPubK | egrep -q "^$|^[0-9a-fA-F]{64}$"; then
		print_error_stack_exit "$node1 Id $node1_IdCId does not look like a public key."
	fi

	# Ensure $_LSPrivK looks like a private key
	if ! eval echo '$'${prefix}_LSPrivK | egrep -q "^$|^[0-9a-fA-F]{64}$"; then
		print_error_stack_exit "$node1 Id $node1_IdCId does not look like a private key."
	fi
	
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

	[ "$QUIET" != 1 ] && echo "Checking $CONF_PATH is writable on $remote_node..." >&2
	
	if ! do_ssh $access_spec $sudo test -w $CONF_PATH; then
		print_error_stack_exit "cannot connect to $remote_node or $CONF_PATH not writable. (try --sudo ?)"
	fi
	
	return 0
}
