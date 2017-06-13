TARGETS := passes fails

passes_DEPS := passes.o
fails_DEPS := fails.o

TESTS := passes
SCRIPT_TESTS := test.sh

# For now adding unneeded dep on fails to test TEST_DEPS
passes_TEST_DEPS := fails
passes_ARGS := arg1 arg2 arg3

test.sh_ARGS := script_arg1 script_arg2

# TODO - work out what to do with failing tests
