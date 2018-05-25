# General points
# since the TEST_ARGS are defined in makefiles the tests must dep on
# the makefiles. Change the makefiles could change the test

_TESTING_FAILING_PREFIX = $(if $(filter true,$(5)),!)
_TESTING_FAILING_SUFFIX = $(if $(filter true,$(5)), || (echo Expected \"$(2)\" to fail;false))
_TESTING_FAILING_REASSURANCE = $(if $(filter true,$(5)),@echo \"$(2)\" failed as expected ,@:)

# $(1) $(d)
# $(2) binary
# $(3) test-deps
# $(4) test arguments
# $(5) fails
define compiled_test
$(1)/$(OBJDIR)/$(2).test: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	@rm -f $$@
	@echo "Testing not supported on $(PLATFORM_TEST) backend"

# TODO - consider making this a flash rule - stop, load flash, reset
.PHONY: $(1)/$(OBJDIR)/$(2).run
$(1)/$(OBJDIR)/$(2).run: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	@echo "Running not supported on $(PLATFORM_TEST) backend"

.PHONY: $(1)/$(OBJDIR)/$(2).debug
$(1)/$(OBJDIR)/$(2).debug: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1))
	$(GDB) -ex \
		$(if $(filter true,$(ARM_SEMIHOSTING)), \
			"target extended-remote localhost:3333", \
			"target extended-remote | openocd -c \"gdb_port pipe; log_output $(1)/$(OBJDIR)/$(2).openocd.log\" -f $(OPENOCD_BOARD) ") \
		$(if $(filter true,$(ARM_SEMIHOSTING)),-ex "monitor arm semihosting enable" -ex "monitor reset halt") \
		-ex "load" \
		-ex "monitor reset init" \
		$$(addprefix -x=,$(wildcard $(1)/$(2).debug)) \
		--args $(1)/$(OBJDIR)/$(2) $(4)

endef

ifneq ($(filter true,$(ARM_SEMIHOSTING)),)
.PHONY: openocd
openocd:
	openocd -f $(OPENOCD_BOARD)
endif
