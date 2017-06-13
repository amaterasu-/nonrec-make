# TODO - make specific rules into skeleton for this

# So that we can add rules that dep $(OBJPATH)/foo.sh.test: $(d)/foo.sh

%.test: %
	@rm -f $@
	$(call echo_cmd,RUN $<) $< && touch $@
