# Stamp-IT brainswap for factomd

Stamp-IT brainswap uses OpenSSH to brainswap two factomd nodes.

To do this, it calculates the block height at which the brainswap must take effect
and it exchanges the identities of the two nodes in their `factomd.conf`.

To use it, you should first setup OpenSSH so that you can login to your factomd nodes without entering passwords interactively
because, otherwise, OpenSSH will ask them many times during the brainswap process
and it could leave your nodes in an incoherent state if it aborts at the wrong time.
Your SSH user should have write access to 
`/var/lib/docker/volumes/factom_keys/_data/factomd.conf`
or should be able to `sudo`.

## Basic usage

    brainswap [--sudo] [--noswap] [user1@]node1[:port1] [user2@]node2[:port2]

* `node1` must be an authority node
* `node2` should NOT be an authority node

E.g.:
If you can login directly as `root`:

    brainswap root@authoritynodeX root@followernoderY

If `user` must `sudo` to get write access to `factomd.conf`:

    brainswap --sudo user@authoritynodeX user@followernoderY

If SSH runs on a non standard port:

    brainswap --sudo user@authoritynodeX:12345 user@followernoderY:12345

To check that brainswap is possible without brainswaping:

    brainswap --sudo --noswap user@authoritynodeX user@followernoderY

## What are the prerequisites?

On the computer initiating the brainswap:

* bash (GNU Bourne-Again SHell)
* OpenSSH
* GNU sed

On the nodes being brainswaped:

* wget

## Where is the configuration file?

There is no brainswap-specific configuration file.

However, the usual OpenSSH configuration files are useful
to setup login without password
and other options
(`~/.ssh/config`, `~/.ssh/id_rsa`, ...).

## Is it safe?

Stamp-IT brainswap is designed to be safe, but there is always a risk something could go wrong.
There could be network problems during the brainswap or there might be errors not handled properly by the script.
Before using it on mainnet, you should test it with a similar setup on testnet.

Here are the checks made by the script before brainswaping:

* All command-line options are recognized
* SSH access working properly with read and write access to `factomd.conf` on both nodes
* Same Factom network on both nodes
* `factomd.conf` contains a `; BRAINSWAP_ID_BELOW` marker or an `[app]` section on both nodes
* IdentityChainID NOT the same on both nodes
* State information from factomd parses correctly on both nodes
* Same block height for both nodes
* Same minute on both nodes, but not minute 0 (because in this case we cannot tell if the nodes are is following minutes)
* No `<nil>` in the process list, on both nodes
* Calculated brainswap height greater than `ChangeAcksHeight`, if any, on both nodes (i.e. no pending brainswap)
* IdentityChainID, LocalServerPrivKey and LocalServerPublicKey all set in node1 `factomd.conf`
* Node1 is an audit or a leader (otherwise it could indicate that a wrong node has been specified)
* `--noswap` not specified


## Can I control where the identities are inserted in `factomd.conf`?

Sure. Just add a line in your `factomd.conf` to mark the place where the brainswap identity should be inserted.
Just insert a line that reads:

    ; BRAINSWAP_ID_BELOW

Otherwise the identity will be insert at the begining of the `[app]` section.

## Can I use a jumpbox to get to my factomd nodes?

Yes. You can use a SSH jump box to connect to a node by prepending `user@jumphost` to the target node and separating them with a comma.
E.g.:

    brainswap user@jumphost,user@authoritynode user@jumphost,user@followernode


## Does it run on my Android phone?

Probably. It has been successfully tested it using the following procedure:

* Install Termux using Google Play
* Install wget (to download brainswap), OpenSSH and GNU sed:

      pkg install wget
      pkg install openssh
      pkg install sed

* Inside Termux, download brainswap:

      wget https://github.com/Stamp-IT-io/brainswap/raw/master/brainswap
      chmod +x brainswap

* Setup OpenSSH to login without password.
  * For example, you can copy your RSA key to `~/.ssh/id_rsa`

* You can run it on the command line by typing: `./brainswap ...`
