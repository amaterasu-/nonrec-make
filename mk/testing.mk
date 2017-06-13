# TODO - make specific rules into skeleton for this

# So that we can add rules that dep $(OBJPATH)/foo.sh.test: $(d)/foo.sh

# $(1) dir
# $(2) binary
# $(3) test-deps
# $(4) test arguments
define compiled_test
$(1)/$(2).test: $(1)/$(2) $(3)
	@rm -f $$@
	$$(call echo_cmd,RUN $$< $(4)) cd $$(dir $$@) && $$< $(4) && touch $$@

endef
