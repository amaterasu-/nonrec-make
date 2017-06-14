TARGETS := passes fails

passes_DEPS := passes.o
fails_DEPS := fails.o

TESTS := passes fails
SCRIPT_TESTS := test.sh

# For now adding unneeded dep on fails to test TEST_DEPS
passes_TEST_DEPS := fails
passes_ARGS := arg1 arg2 arg3

fails_FAILS := true

test.sh_ARGS := script_arg1 script_arg2
