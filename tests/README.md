# Automated tests for Stamp-IT Brainswap

In this directory and its sub-directories, you will find everything that has been designed specifically to test the brainswap script.

File / directory         | Description
---                      | ---
alpine-dropbear          | Contains a script and a Dockerfile to build a container image with dropbear (SSH server) and a known ssh key
alpine-httpd             | Contains a script and a Dockerfile to build a container image with Busybox HTTPD server and dropbear with a known ssh key
ssh-keys                 | Contains the known SSH key for the container images above
files-test-factomd-conf  | Various files used in tests for the Brainswap scripts (input or expected output)
volume-\*                | Various volumes to be mounted inside containers during the tests to simulate a Factomd node
test\_\*                 | Tests for the brainswap script; they use the container images, files and volumes described above to simulate a Factomd node
run\_all\_tests          | Script to run all the tests

Before running the tests, you must build two docker images:

    ./alpine-dropbear/build
    ./alpine-httpd/build

You must also install the well-known SSH keys for the tests:

    ./ssh-keys/install_ssh_keys

Then you should be able to run all the tests:

    ./run_all_tests
