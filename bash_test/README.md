# bash\_test framework

In this directory, you will find the following files:

bash\_test.sh             | Contains the main logic of the framework, especially functions `run_expect_output` and `run_expect_error`.
run\_bash\_test           | Shell script to run a test file that starts with `#!/usr/bin/env run_bash_test`.
run\_all\_test            | Simple shell script to run all files having a name starting with `test_`; copy it to your test directory.
test\_bash\_test          | Automated tests for the bash\_test framework itself.
test\_bash\_test\_failure | Automated tests for the bash\_test framework itself those tests are expected to fail.
