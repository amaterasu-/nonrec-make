TARGETS := passes fails

passes_DEPS := passes.o
fails_DEPS := fails.o

TESTS := passes

# For now adding unneeded dep on fails to test TEST_DEPS
passes_TEST_DEPS := fails
passes_ARGS := arg1 arg2 arg3

# TODO - work out what to do with failing tests
