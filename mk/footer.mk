define FOOTER
SUBDIRS_$(d) := $(patsubst %/,%,$(addprefix $(d)/,$(SUBDIRS)))

ifneq ($(strip $(OBJS)),)
OBJS_$(d) := $(addprefix $(OBJPATH)/,$(OBJS))
else # Populate OBJS_ from SRCS

# Expand wildcards in SRCS if they are given
ifneq ($(or $(findstring *,$(SRCS)),$(findstring ?,$(SRCS)),$(findstring ],$(SRCS))),)
  SRCS := $(notdir $(foreach sd,. $(SRCS_VPATH),$(wildcard $(addprefix $(d)/$(sd)/,$(SRCS)))))
  SRCS := $(filter-out $(SRCS_EXCLUDES), $(SRCS))
endif

OBJS_$(d) := $(addprefix $(OBJPATH)/,$(addsuffix .o,$(basename $(SRCS))))
endif

CLEAN_$(d) := $(CLEAN_$(d)) $(filter /%,$(CLEAN) $(TARGETS)) $(addprefix $(d)/,$(filter-out /%,$(CLEAN)))

ifdef TARGETS
abs_tgts := $(filter /%, $(TARGETS))
rel_tgts := $(filter-out /%,$(TARGETS))
TARGETS_$(d) := $(abs_tgts) $(addprefix $(OBJPATH)/,$(rel_tgts))
$(foreach tgt,$(filter-out $(AUTO_TGTS),$(rel_tgts)),$(eval $(call save_vars,$(OBJPATH)/,$(tgt))))
# Absolute targets are entry points for external (sub)projects which
# have their own build system - what is really interesting is only CMD
# and possibly DEPS however I use this general save_vars (two more vars
# that are not going to be used should not be a problem :P).
$(foreach tgt,$(abs_tgts),$(eval $(call save_vars,,$(tgt))))
else
TARGETS_$(d) := $(OBJS_$(d))
endif

# Save user defined vars
$(foreach v,$(VERB_VARS),$(eval $(v)_$(d) := $($v)))
$(foreach v,$(OBJ_VARS),$(eval $(v)_$(d) := $(addprefix $(OBJPATH)/,$($v))))
$(foreach v,$(DIR_VARS),$(eval $(v)_$(d) := $(filter /%,$($v)) $(addprefix $(d)/,$(filter-out /%,$($v)))))

# Update per directory variables that are automatically inherited
ifeq ($(origin INHERIT_DIR_VARS_$(d)),undefined)
  INHERIT_DIR_VARS_$(d) := $(or $(INHERIT_DIR_VARS_$(parent_dir)), $(INHERIT_DIR_VARS))
endif
$(foreach v,$(INHERIT_DIR_VARS_$(d)),$(if $($(v)_$(d)),,$(eval $(v)_$(d) := $($(v)_$(parent_dir)))))

########################################################################
# Daytona
########################################################################

ifeq ($(DAYTONA_$(d)),true)

# LINKORDER is only defined at top-level
ifneq ($(LINKORDER_$(parent_dir)),)
LINKORDER_$(d) := $(LINKORDER_$(parent_dir))
endif

SRCS_$(d) := $(notdir $(wildcard $(addprefix $(d)/,*.c *.cpp *.cc)))
OBJS_$(d) := $(addprefix $(OBJPATH)/,$(addsuffix .o,$(basename $(SRCS_$(d)))))

daytona_lib := lib$(notdir $(d)).a

DEPS_$(OBJPATH)/$(daytona_lib) := $(filter-out _%,$(notdir $(OBJS_$(d))))
ifneq ($(value DEPS_$(OBJPATH)/$(daytona_lib)),)
TARGETS_$(d) := $(OBJPATH)/$(daytona_lib)
else
daytona_lib :=
endif

daytona_test_lib_o := $(filter __%,$(notdir $(OBJS_$(d))))
daytona_executable_o := $(filter-out $(daytona_test_lib_o),$(filter _%,$(notdir $(OBJS_$(d)))))

TARGETS_$(d) += $(addprefix $(OBJPATH)/,$(basename $(daytona_executable_o)))

$(foreach exe,$(daytona_executable_o),\
	$(eval $(call daytona_executable,$(OBJPATH)/,$(basename $(exe)),\
	$(addprefix $(OBJPATH)/,$(daytona_lib) $(daytona_test_lib_o)),\
	$(DEPENDS_$(d)),\
	$(LIBS_$(d)),\
	$(LINKORDER_$(d)))))

TESTS_$(d) += $(filter-out $(NON_TEST_$(d)),$(basename $(daytona_executable_o)))

endif # Daytona

# Completion targets
ifneq ($(filter completion_list_targets,$(MAKECMDGOALS)),)
# Add all targets + when completing in the final directory
# (COMPLETION_FILTER matches OBJPATH) add the test/run/debug targets.
COMPLETION_TARGET_LIST += $(filter-out %.a %.o,$(TARGETS_$(d))) \
	$(addsuffix .test,$(addprefix $(OBJPATH)/,$(SCRIPT_TESTS_$(d)))) \
	$(if $(filter $(dir $(COMPLETION_FILTER)),$(OBJPATH)/), \
		$(addprefix $(OBJPATH)/,$(foreach test,$(TESTS_$(d)),$(test).run $(test).test $(test).debug)) \
		$(addsuffix .run,$(addprefix $(OBJPATH)/,$(SCRIPT_TESTS_$(d)))))
endif

########################################################################
# Testing
########################################################################

ifneq ($(filter native,$(PLATFORM_TEST)),)
# TODO native only supported for now - no cross-testing

# TESTS corresponds to binary/compiled tests
# SCRIPT_TESTS corresponds to non-compiled tests
TEST_$(d) :=  $(addprefix $(OBJPATH)/,$(TESTS_$(d)) $(SCRIPT_TESTS_$(d)))

$(foreach test,$(TESTS_$(d)), $(eval $(call compiled_test,$(d),$(test), $(call abs_or_dir,$($(test)_TEST_DEPS),$(OBJPATH)),$($(test)_ARGS),$($(test)_FAILS))))
$(foreach test,$(SCRIPT_TESTS_$(d)), $(eval $(call script_test,$(d),$(test), $(call abs_or_dir,$($(test)_TEST_DEPS),$(OBJPATH)),$($(test)_ARGS),$($(test)_FAILS))))
endif

########################################################################
# OPT_IN_PLATFORMS
########################################################################

# Disable directory for PLATFORM_OPT_IN=true build targets unless
# specified as OPT_IN_PLATFORMS
ifeq ($(PLATFORM_OPT_IN),true)
ifeq ($(filter $(foreach v,$(PLATFORM_VARS),$(value $(v))),$(OPT_IN_PLATFORMS_$(d))),)
# Disable targets on OPT_IN platforms that are not selected by OPT_IN_PLATFORMS
TARGETS_$(d) :=
SRCS_$(d) :=
OBJS_$(d) :=
TEST_$(d) :=
endif
endif


########################################################################
# Inclusion of subdirectories rules - only after this line one can     #
# refer to subdirectory targets and so on.                             #
########################################################################
$(foreach sd,$(SUBDIRS),$(eval $(call include_subdir_rules,$(sd))))

.PHONY: dir_$(d) clean_$(d) clean_extra_$(d) clean_tree_$(d) dist_clean_$(d) test_$(d) test_tree_$(d)
.SECONDARY: $(OBJPATH)

# Stop processing here for syntax-checking or completion listing
# NOTE: bash completion defines .DEFAULT
ifeq ($(filter check-syntax completion_% .DEFAULT,$(MAKECMDGOALS)),)

# Whole tree targets
all :: $(TARGETS_$(d))

clean_all :: clean_$(d)

# dist_clean is optimized in skel.mk if we are building in out of project tree
ifeq ($(strip $(TOP_BUILD_DIR)),)
dist_clean :: dist_clean_$(d)

# No point to enforce clean_extra dependency if CLEAN is empty
ifeq ($(strip $(CLEAN_$(d))),)
dist_clean_$(d) :
else
dist_clean_$(d) : clean_extra_$(d)
endif
	rm -rf $(DIST_CLEAN_DIR)
endif

########################################################################
#                        Per directory targets                         #
########################################################################

# Again - no point to enforce clean_extra dependency if CLEAN is empty
ifeq ($(strip $(CLEAN_$(d))),)
clean_$(d) :
else
clean_$(d) : clean_extra_$(d)
endif
	rm -f $(CLEAN_DIR)/*

# clean_extra is meant for the extra output that is generated in source
# directory (e.g. generated source from lex/yacc) so I'm not using
# TOP_BUILD_DIR below
clean_extra_$(d) :
	rm -rf $(filter %/,$(CLEAN_$(subst clean_extra_,,$@))); rm -f $(filter-out %/,$(CLEAN_$(subst clean_extra_,,$@)))

clean_tree_$(d) : clean_$(d) $(foreach sd,$(SUBDIRS_$(d)),clean_tree_$(sd))

# Skip the target rules generation and inclusion of the dependencies
# when we just want to clean up things :)
ifeq ($(filter clean clean_% dist_clean,$(MAKECMDGOALS)),)

test_tree_$(d) : test_$(d) $(foreach sd,$(SUBDIRS_$(d)),test_tree_$(sd))

test_$(d): $(foreach test,$(TEST_$(d)),$(test).test)


SUBDIRS_TGTS := $(foreach sd,$(SUBDIRS_$(d)),$(TARGETS_$(sd)))

# Use the skeleton for the "current dir"
$(eval $(call skeleton,$(d)))
# and for each SRCS_VPATH subdirectory of "current dir"
$(foreach vd,$(SRCS_VPATH),$(eval $(call skeleton,$(d)/$(vd))))

# Target rules for all "non automatic" targets
$(foreach tgt,$(filter-out $(AUTO_TGTS),$(TARGETS_$(d))),$(eval $(call tgt_rule,$(tgt))))

# Way to build all targets in given subtree (not just current dir as via
# dir_$(d) - see below)
tree_$(d) : $(TARGETS_$(d)) $(foreach sd,$(SUBDIRS_$(d)),tree_$(sd))

# If the directory is just for grouping its targets will be targets from
# all subdirectories
ifeq ($(strip $(TARGETS_$(d))),)
TARGETS_$(d) := $(SUBDIRS_TGTS)
endif

# This is a default rule - see Makefile
dir_$(d) : $(TARGETS_$(d))

endif
endif # check-syntax
endef
