# Run only on native platform (not cross testing)
ifneq ($(filter native,$(PLATFORM_TEST)),)

SCRIPT_TESTS := test_completion.bash \
	test_completion_make.sh

endif
