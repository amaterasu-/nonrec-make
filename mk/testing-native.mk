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
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $(_TESTING_FAILING_PREFIX) $$< $(4) $(_TESTING_FAILING_SUFFIX)
	$(_TESTING_FAILING_REASSURANCE)
	@touch $$@

.PHONY: $(1)/$(OBJDIR)/$(2).run
$(1)/$(OBJDIR)/$(2).run: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $$< $(4)

.PHONY: $(1)/$(OBJDIR)/$(2).debug
$(1)/$(OBJDIR)/$(2).debug: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1))
	$(GDB) -ex "break main" -ex "run" \
		$$(addprefix -x=,$(wildcard $(1)/$(2).debug)) \
		--args $(1)/$(OBJDIR)/$(2) $(4)

endef

RUN.sh := sh
RUN.py := python
RUN.rb := ruby
RUN.bash := bash
RUN.bats := $(or $(BATS),bats)

# TODO - emit different failure

# $(1) $(d)
# $(2) script
# $(3) test-deps
# $(4) test arguments
# $(5) fails
define script_test
$(1)/$(OBJDIR)/$(2).test: $(1)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	@rm -f $$@
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $(_TESTING_FAILING_PREFIX) $(RUN$(suffix $(2))) $$< $(4) $(_TESTING_FAILING_SUFFIX)
	$(_TESTING_FAILING_REASSURANCE)
	@touch $$@

.PHONY: $(1)/$(OBJDIR)/$(2).run
$(1)/$(OBJDIR)/$(2).run: $(1)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $(RUN$(suffix $(2))) $$< $(4)

endef
