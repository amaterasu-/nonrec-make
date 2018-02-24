# TODO - this is specific to gcc

CC_CHECK_SYNTAX = : && $(filter-out -MMD -MF% -Werror,$(COMPILE.cc)) $(CHECK_SYNTAX_FLAGS) $< -o /dev/null || true
%.cpp.check-syntax: %.cpp
	$(CC_CHECK_SYNTAX)

%.cc.check-syntax: %.cc
	$(CC_CHECK_SYNTAX)

HH_CHECK_SYNTAX = $(filter-out -MMD -MF% -Werror,$(COMPILE.cc)) $(CHECK_SYNTAX_FLAGS) -x c++-header $< -o /dev/null 2>&1 1>/dev/null | grep -v "warning: \#pragma once in main file" || true
%.hpp.check-syntax: %.hpp
	$(HH_CHECK_SYNTAX)
%.hh.check-syntax: %.hh
	$(HH_CHECK_SYNTAX)
%.H.check-syntax: %.H
	$(HH_CHECK_SYNTAX)

%.h.check-syntax: %.h
	$(filter-out -MMD -MF% -Werror,$(COMPILE.c)) $(CHECK_SYNTAX_FLAGS) -x c $< -o /dev/null || true

%.c.check-syntax: %.c
	$(filter-out -MMD -MF% -Werror,$(COMPILE.c)) $(CHECK_SYNTAX_FLAGS) $< -o /dev/null || true
