# Bash-test framework  Copyright 2019 Stamp-IT Blockchain Solution inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#
# This file contains the main code for the Bash-test framework
#

function reset_tests_stats () {
        declare -g BASH_TEST_PASSED BASH_TEST_FAILED
        BASH_TEST_PASSED=0
        BASH_TEST_FAILED=0
}

function record_test_passed () {
        declare -g BASH_TEST_PASSED BASH_TEST_FAILED
        BASH_TEST_PASSED="$(($BASH_TEST_PASSED + 1))"
}

function record_test_failed () {
        declare -g BASH_TEST_PASSED BASH_TEST_FAILED
        BASH_TEST_FAILED="$(($BASH_TEST_FAILED + 1))"
}

function show_tests_stats () {
        declare -g BASH_TEST_PASSED BASH_TEST_FAILED
	echo "$BASH_TEST_FAILED tests failed, $BASH_TEST_PASSED passed out of $(($BASH_TEST_PASSED + $BASH_TEST_FAILED))"
}

function run_expect_error ()
{
        local expected_return_value actual_returned_value
	if [ "$1" == "--debug" ]; then
		DEBUG_CMD=1
		shift
	else
		DEBUG_CMD=0
	fi
        expected_return_value="$1"
        shift

        # Using the name of the calling function
        echo -n "Executing test ${FUNCNAME[1]}:${BASH_LINENO[0]}... "
	if [ "$DEBUG_CMD" == "1" ]; then
	       	set -x
		echo "Executing: ---" "$@" "---" >&2
	else
		# Discard output to stderr if not in debug mode
		exec 99>&2
		exec 2>/dev/null
	fi
	("$@") >/dev/null </dev/null
        actual_returned_value="$?"
	set +x
	if [ "$DEBUG_CMD" != "1" ]; then 
		# Restore output to stderr
		exec 2>&99
	fi

        if [ "$actual_returned_value" -eq "$expected_return_value" ]; then
                record_test_passed
                echo "passed"
        else
                record_test_failed
                echo "failed"
                echo -ne "\tAssertion failed at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: "
                echo -e "Expected return value $expected_return_value, got $actual_returned_value"
        fi
}

function run_expect_output ()
{
        local expected_output
        local expected_output actual_output
	if [ "$1" == "--debug" ]; then
		DEBUG_CMD=1
		shift
	else
		DEBUG_CMD=0
	fi
        expected_output="$1"
        shift

        # Using the name of the calling function
        echo -n "Executing test ${FUNCNAME[1]}:${BASH_LINENO[0]}... "
	if [ "$DEBUG_CMD" == "1" ]; then
	       	set -x
	else
		# Discard output tou stderr if not in debug mode
		exec 99>&2
		exec 2>/dev/null
	fi
	actual_output=("$("$@")") </dev/null
        actual_returned_value="$?"
	set +x
	if [ "$DEBUG_CMD" != "1" ]; then 
		# Restore output to stderr
		exec 2>&99
	fi

        if [ "$actual_returned_value" -ne 0 ]; then
                record_test_failed
                echo "failed"
        elif [ "$actual_output" == "$expected_output" ]; then
                record_test_passed
                echo "passed"
        else
                record_test_failed
                echo "failed"
                echo -ne "\tAssertion failed at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: "
                echo -e "Expected output value $expected_output, got $actual_output"
        fi
}
