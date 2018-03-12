# General points
# since the TEST_ARGS are defined in makefiles the tests must dep on
# the makefiles. Change the makefiles could change the test

_TESTING_FAILING_PREFIX = $(if $(filter true,$(5)),!)
_TESTING_FAILING_SUFFIX = $(if $(filter true,$(5)), || (echo Expected \"$(2)\" to fail;false))
_TESTING_FAILING_REASSURANCE = $(if $(filter true,$(5)),@echo \"$(2)\" failed as expected ,@:)
_TESTING_SSH_TARGET_CHECK = @[ -n "$(SSH_TARGET_$(BUILD_MODE))" ] || (echo fail; echo "ERROR: Must define SSH_TARGET_$(BUILD_MODE)" ; false)
_TESTING_SSH = ssh -T $(SSH_TARGET_$(BUILD_MODE)) --

SSH_PLATFORM := host
#SSH_PLATFORM := embedded
# on host-like platforms move everything into a temporary directory
_TESTING_SSH_TARGET_DIR := $(if $(filter host,$(SSH_PLATFORM)),/tmp/nr_test$$(hostname),.)

# $(1) $(d)
# $(2) binary
# $(3) test-deps
# $(4) test arguments
# $(5) fails
define compiled_test
$(1)/$(OBJDIR)/$(2).test: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	@rm -f $$@
	$(_TESTING_SSH_TARGET_CHECK)
	$$(call echo_cmd,DEPS $$<) rsync -v $(1)/$(OBJDIR)/$(2) $(3) $(SSH_TARGET_$(BUILD_MODE)):$(_TESTING_SSH_TARGET_DIR)/
	$$(call echo_cmd,RUN $$< $(4)) $(_TESTING_SSH) 'cd $(_TESTING_SSH_TARGET_DIR) && $(_TESTING_FAILING_PREFIX) ./$(2) $(4) $(_TESTING_FAILING_SUFFIX)'
	$(_TESTING_FAILING_REASSURANCE)
	@touch $$@

.PHONY: $(1)/$(OBJDIR)/$(2).run
$(1)/$(OBJDIR)/$(2).run: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	$(_TESTING_SSH_TARGET_CHECK)
	$$(call echo_cmd,DEPS $$<) rsync -v $(1)/$(OBJDIR)/$(2) $(3) $(SSH_TARGET_$(BUILD_MODE)):$(_TESTING_SSH_TARGET_DIR)/
	$$(call echo_cmd,RUN $$< $(4)) $(_TESTING_SSH) 'cd $(_TESTING_SSH_TARGET_DIR) && ./$(2) $(4)'

# TODO - doesn't honour SSH_TARGET_DIR
# TODO - set sysroot for remote symbols
.PHONY: $(1)/$(OBJDIR)/$(2).debug
$(1)/$(OBJDIR)/$(2).debug: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1))
	$(_TESTING_SSH_TARGET_CHECK)
	$$(call echo_cmd,DEPS $$<) rsync -v $(1)/$(OBJDIR)/$(2) $(3) $(SSH_TARGET_$(BUILD_MODE)):~/
	$(GDB) $(1)/$(OBJDIR)/$(2) -ex "target extended-remote | $(_TESTING_SSH) gdbserver --once --wrapper env 'BUILD_MODE=$(BUILD_MODE)' -- - ./$(2) $(4)" \
		$$(addprefix -x=,$(wildcard $(1)/$(2).debug))

endef

# TODO - not all of these may be available on the target
RUN.sh := sh
RUN.py := python
RUN.rb := ruby
RUN.bash := bash

# $(1) $(d)
# $(2) script
# $(3) test-deps
# $(4) test arguments
# $(5) fails
define script_test
$(1)/$(OBJDIR)/$(2).test: $(1)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	@rm -f $$@
	$(_TESTING_SSH_TARGET_CHECK)
	@$(_TESTING_SSH) which $(RUN$(suffix $(2))) > /dev/null || (echo "Skipping $(RUN$(suffix $(2))) as not available on target"; touch $$@)
	$$(call echo_cmd,DEPS $$<) [ -e "$$@" ] || rsync -v $(1)/$(2) $(3) $(SSH_TARGET_$(BUILD_MODE)):$(_TESTING_SSH_TARGET_DIR)/
	$$(call echo_cmd,RUN $$< $(4)) [ -e "$$@" ] || $(_TESTING_SSH) 'cd $(_TESTING_SSH_TARGET_DIR) && $(_TESTING_FAILING_PREFIX) $(RUN$(suffix $(2))) ./$(2) $(4) $(_TESTING_FAILING_SUFFIX)'
	$(_TESTING_FAILING_REASSURANCE)
	@touch $$@

.PHONY: $(1)/$(OBJDIR)/$(2).run
$(1)/$(OBJDIR)/$(2).run: $(1)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES) | $(1)/$(OBJDIR)
	$$(call echo_cmd,DEPS $$<) rsync -v $(1)/$(2) $(3) $(SSH_TARGET_$(BUILD_MODE)):$(_TESTING_SSH_TARGET_DIR)/
	$$(call echo_cmd,RUN $$< $(4)) $(_TESTING_SSH) 'cd $(_TESTING_SSH_TARGET_DIR) && $(RUN$(suffix $(2))) ./$(2) $(4)'

endef
