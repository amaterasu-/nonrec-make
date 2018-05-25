SHELL := /bin/bash
RUNDIR := $(CURDIR)
START_TIME := $(shell date +%s%3N)
ifndef TOP
TOP := $(shell \
       top=$(RUNDIR); \
       while [ ! -r "$$top/Rules.top" ] && [ "$$top" != "" ]; do \
           top=$${top%/*}; \
       done; \
       echo $$top)
endif

MK := $(TOP)/mk

.SUFFIXES:
MAKEFLAGS += --no-builtin-rules

.PHONY: dir tree all clean clean_all clean_tree dist_clean

# Default target when nothing is given on the command line.  Reasonable
# options are:
# "dir"  - updates only targets from current directory and its dependencies
# "tree" - updates targets (and their dependencies) in whole subtree
#          starting at current directory
# "all"  - updates all targets in the project
.DEFAULT_GOAL := tree

dir : dir_$(RUNDIR)
tree : tree_$(RUNDIR)

clean : clean_$(RUNDIR)
clean_tree : clean_tree_$(RUNDIR)

# Test support follows the example of clean
# TODO - I hate that test doesn't test everything in subtree
.PHONY: test test_tree
test : test_$(RUNDIR)
test_tree : test_tree_$(RUNDIR)

ifneq ($(SYNTAX_CHECK_MODE),)
.phony: check-syntax

check-syntax: $(addsuffix .check-syntax,$(shell readlink -f $(addprefix $(TOP)/,$(CHK_SOURCES))))
endif

# empty list of completion targets to be filled for completion_list_targets
COMPLETION_TARGET_LIST :=

# $(d) keeps the path of "current" directory during tree traversal and
# $(dir_stack) is used for backtracking during traversal
d := $(TOP)
dir_stack :=

include $(MK)/header.mk
include $(MK)/footer.mk

# Automatic inclusion of the skel.mk at the top level - that way
# Rules.top has exactly the same structure as other Rules.mk
include $(MK)/skel.mk

.SECONDEXPANSION:
$(eval $(value HEADER))
include $(TOP)/Rules.top
$(eval $(value FOOTER))

# Optional final makefile where you can specify additional targets
-include $(TOP)/final.mk

.PHONY: completion_list_targets
completion_list_targets:
	@echo COMPLETION_TARGET_LIST=$(filter $(COMPLETION_FILTER)%,$(COMPLETION_TARGET_LIST))

.PHONY: completion_list_build_dirs
completion_list_build_dirs:
	@echo COMPLETION_BUILD_DIRS_LIST=$(if $(filter $(HOSTED_CONFIG_ONLY),true),$(HOSTED_CONFIG_DIR),$(HOSTED_CONFIG_DIR) $(MK))

# This is just a convenience - to let you know when make has stopped
# interpreting make files and started their execution.
END_TIME := $(shell date +%s%3N)
$(info Rules generated $(if $(BUILD_MODE),for "$(BUILD_MODE)" mode,)... ($(shell expr $(END_TIME) - $(START_TIME))ms))
