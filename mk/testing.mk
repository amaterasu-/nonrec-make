# General points
# since the TEST_ARGS are defined in makefiles the tests must dep on
# the makefiles. Change the makefiles could change the test

# $(1) $(d)
# $(2) binary
# $(3) test-deps
# $(4) test arguments
define compiled_test
$(1)/$(OBJDIR)/$(2).test: $(1)/$(OBJDIR)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES)
	@rm -f $$@
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $$< $(4) && touch $$@

endef

RUN.sh := sh
RUN.py := python
RUN.rb := ruby

# $(1) $(d)
# $(2) script
# $(3) test-deps
# $(4) test arguments
define script_test
$(1)/$(OBJDIR)/$(2).test: $(1)/$(2) $(3) $$(MAKEFILE_DEPS_$(1)) $$(NONREC_MAKEFILES)
	@rm -f $$@
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $(RUN$(suffix $(2))) $$< $(4) && touch $$@

endef
