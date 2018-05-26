# For the reference here are some automatic variables defined by make.
# There are also their D/F variants e.g. $(<D) - check the manual.
#
# $@ - file name of the target of the rule
# $% - target member name when the target is archive member
# $< - the name of the first dependency
# $? - the names of all dependencies that are newer then the target
# $^ - the names of all dependencies

# Helps avoid makefile parse issues
COMMA = ,

########################################################################
#                        User defined variables                        #
########################################################################

# VERB_VARS is a list of variables that you'd like to record on per
# directory level.  So if you set it to say AUTOTEST then each each
# directory will have it's own AUTOTEST_$(dir) variable with value taken
# from appropriate Rules.mk
VERB_VARS := MAKEFILE_DEPS TESTS SCRIPT_TESTS OPT_IN_PLATFORMS

# OBJ_VARS - like VERB_VARS but all values taken from Rules.mk have
# $(OBJPATH) prepended so instead of saying:
#   INSTALL_$d := $(OBJPATH)/some_target
# you can say simply
#   INSTALL := some_target
OBJ_VARS := INSTALL_BIN INSTALL_LIB

# DIR_VARS - like VERB_VARS but all values taken from Rules.mk have $(d)
# prepended (unless value is an absolute path) so you can say:
#   INSTALL_DOC := Readme.txt
# instead of:
#   INSTALL_DOC_$d := $(d)/Readme.txt
DIR_VARS := INSTALL_DOC INSTALL_INC

# PLATFORM_VARS are variables that are defined per target to accommodate
# cross-platform code
PLATFORM_VARS := OS CPU PLATFORM BOARD

# NOTE: There is generic macro defined below with which you can get all
# values of given variable from some subtree e.g.:
#   $(call get_subtree,INSTALL,dir)
# will give you value of all INSTALL variables from tree starting at
# 'dir'

########################################################################
#                       Directory specific flags                       #
########################################################################

# You just define in Rules.mk say
# INCLUDES_$(d) := ....
# and this will get expanded properly during compilation (see e.g. COMPILE.c)
# Of course you can still use the target specific variables if you want
# to have special setting for just one target and not the whole
# directory.  See below for definition of @RD variable.
DIR_INCLUDES = $(addprefix -I,$(INCLUDES_$(@RD)))
DIR_CPPFLAGS = $(CPPFLAGS_$(@RD))
DIR_CFLAGS = $(CFLAGS_$(@RD))
DIR_CXXFLAGS = $(CXXFLAGS_$(@RD))

# Define platform definitions - eg OS := Linux -> OS_LINUX
PLATFORM_CPPFLAGS = $(foreach var,$(PLATFORM_VARS),$(if $(value $(var)),-D$(shell echo $(var)_$(value $(var)) | tr a-z A-Z )))

########################################################################
#                       Global flags/settings                          #
########################################################################

CFLAGS = -g -W -Wall $(DIR_CFLAGS)
CXXFLAGS = -g -W -Wall $(DIR_CXXFLAGS)

OPT_FLAGS := -O3

# List of includes that all (or at least majority) needs
INCLUDES :=

# Here's an example of settings for preprocessor.  -MMD is to
# automatically build dependency files as a side effect of compilation.
# This has some drawbacks (e.g. when you move/rename a file) but it is
# good enough for me.  You can improve this by using a special script
# that builds the dependency files (one can find examples on the web).
# Note that I'm adding DIR_INCLUDES before INCLUDES so that they have
# precedence.  And DIR_CPPFLAGS after PLATFORM_CPPFLAGS so they can
# override (eg unset).
CPPFLAGS = -MMD \
	   $(PLATFORM_CPPFLAGS) $(DIR_CPPFLAGS) $(DIR_INCLUDES) $(addprefix -I,$(INCLUDES))

# Linker flags.  The values below will use what you've specified for
# particular target or directory but if you have some flags or libraries
# that should be used for all targets/directories just append them at end.
LDFLAGS = $(LDFLAGS_$(@)) $(addprefix -L,$(LIBDIRS_$(@RD)))

# List of libraries that all targets need (either with specific command
# generated by this makefile system or for which make has built in rules
# since LDLIBS is a variable that implicit make rules are using).
# LDLIBS can be either simple or recursive, but simpler version is
# suggested :).
LDLIBS :=

########################################################################
#                       The end of generic flags                       #
########################################################################

# Now we suck in configuration ...

# optional top-level config.mk in host repository
-include $(TOP)/config.mk

include $(MK)/config.mk

# config.mk may define HOSTED_CONFIG_DIR to provide a place to define
# its own build files outside nonrec-make itself.  If the such a
# build-*.mk or config-*.mk is found in $(HOSTED_CONFIG_DIR) it will
# be used in preference to $(MK)/build-*.mk.  Such files can (and
# should) include the original from $(MK) to make their jobs easier

# ... optional build mode specific flags ...
ifdef BUILD_MODE
  -include $(firstword $(wildcard $(addsuffix /build-$(BUILD_MODE).mk,$(HOSTED_CONFIG_DIR) $(MK))))
endif

# ... host and build specific settings ...
ARCH_BUILD_CONFIG_MK := $(firstword $(wildcard $(addsuffix /config-$(BUILD_ARCH)_$(HOST_ARCH).mk,$(HOSTED_CONFIG_DIR) $(MK))))
ifneq ($(ARCH_BUILD_CONFIG_MK),)
  include $(ARCH_BUILD_CONFIG_MK)
else
  include $(MK)/config-default.mk
endif

# ... and here's a good place to translate some of these settings into
# compilation flags/variables.  As an example a preprocessor macro for
# target endianess
ifeq ($(ENDIAN),big)
  CPPFLAGS += -DBIG_ENDIAN
else
  CPPFLAGS += -DLITTLE_ENDIAN
endif

# Use host/build specific config files to override default extension
# for shared libraries 
SOEXT := $(or $(SOEXT),so)

ifeq ($(ENABLE_DAYTONA),true)
VERB_VARS += DAYTONA DEPENDS LIBS LINKORDER NON_TEST
endif

########################################################################
#         A more advanced part - if you change anything below          #
#         you should have at least vague idea how this works :D        #
########################################################################

# I define these for convenience - you can use them in your command for
# updating the target.
DEP_OBJS = $(filter %.o, $^)
DEP_OBJS? = $(filter %.o, $?)
DEP_ARCH = $(filter %.a, $^)
DEP_ARCH? = $(filter %.a, $?)
DEP_LIBS = $(addprefix -L,$(dir $(filter %.$(SOEXT), $^))) $(patsubst lib%.$(SOEXT),-l%,$(notdir $(filter %.$(SOEXT), $^)))
DEP_LD = $(if $(filter %.ld, $^),$(filter %.ld, $^),$(PLATFORM_LD))

# Kept for backward compatibility - you should stop using these since
# I'm now not dependent on $(OBJDIR)/.fake_file any more
?R = $?
^R = $^

# Targets that match this pattern (make pattern) will use rules defined
# in:
# - def_rules.mk included below (explicit or via `skeleton' macro)
# - built in make rules
# Other targets will have to use _DEPS (and so on) variables which are
# saved in `save_vars' and used in `tgt_rule' (see below).
AUTO_TGTS := %.o

# Where to put the compiled objects.  You can e.g. make it different
# depending on the target platform (e.g. for cross-compilation a good
# choice would be OBJDIR := obj/$(HOST_ARCH)) or debugging being on/off.
OBJDIR := $(if $(BUILD_MODE),obj/$(BUILD_MODE),obj)

# Convenience function to convert from a build directory back to the
# "real directory" of a target
define build_to_real_dir
$(if $(strip $(TOP_BUILD_DIR)),$(patsubst $(TOP_BUILD_DIR)%/$(OBJDIR),$(TOP)%,$(1)),$(patsubst %/$(OBJDIR),%,$(1)))
endef

# Convenience function to convert from the "real directory" to the build
# directory
define real_to_build_dir
$(if $(strip $(TOP_BUILD_DIR)),$(TOP_BUILD_DIR)$(subst $(TOP),,$(1))/$(OBJDIR),$(1)/$(OBJDIR))
endef

# By default OBJDIR is relative to the directory of the corresponding Rules.mk
# however you can use TOP_BUILD_DIR to build all objects outside of your
# project tree.  This should be an absolute path.  Note that it can be
# also inside your project like example below.
#TOP_BUILD_DIR := $(TOP)/build_dir
OBJPATH = $(call real_to_build_dir,$(d))
CLEAN_DIR = $(call real_to_build_dir,$(subst clean_,,$@))
DIST_CLEAN_DIR = $(patsubst %/$(OBJDIR),%/$(firstword $(subst /, ,$(OBJDIR))),\
				 $(call real_to_build_dir,$(subst dist_clean_,,$@)))

# This variable contains a list of subdirectories where to look for
# sources.  That is if you have some/dir/Rules.mk where you name object
# say client.o this object will be created in some/dir/$(OBJDIR)/ and
# corresponding source file will be searched in some/dir and in
# some/dir/{x,y,z,...} where "x y z ..." is value of this variable.
SRCS_VPATH := src

# Target "real directory" - this is used above already and is most
# reliable way to refer to "per directory flags".  In theory one could
# use automatic variable already defined by make "<D" but this will not
# work well when somebody uses SRCS_VPATH variable.
@RD = $(call build_to_real_dir,$(@D))

# These are commands that are used to update the target.  If you have
# a target that make handles with built in rules just add its pattern to
# the AUTO_TGTS below.  Otherwise you have to supply the command and you
# can either do it explicitly with _CMD variable or based on the
# target's suffix and corresponding MAKECMD variable.  For example %.a
# are # updated by MAKECMD.a (exemplary setting below).  If the target
# is not filtered out by AUTO_TGTS and there's neither _CMD nor suffix
# specific command to build the target DEFAULT_MAKECMD is used.

# Creating archives gets more complicated if some dependencies are themselves
# archives. In this case, the contents have to be extracted and archived again
# in a larger archive.
EXTRACT_LNAME = $(notdir $(basename $(lib)))
EXTRACT_DIR = $@_extract
MAKECMD.a = $(call echo_cmd,AR $@) \
	$(if $(SHOW_DEPS),echo $@_DEPS=$^ | tr " " "\n" && )\
	rm -f $@ && \
	$(if $(DEP_OBJS), \
		$(AR) $(ARFLAGS) $@ $(DEP_OBJS) \
		&&) \
	$(if $(DEP_ARCH), \
		rm -rf $(EXTRACT_DIR) \
		&& mkdir -p $(EXTRACT_DIR) \
		$(foreach lib,$(DEP_ARCH), && mkdir $(EXTRACT_DIR)/$(EXTRACT_LNAME) && cd $(EXTRACT_DIR)/$(EXTRACT_LNAME) && $(AR) xo $(lib) && (for i in *.o; do mv $$i $(EXTRACT_LNAME)_$$i ; done) && cd - > /dev/null) \
		&& $(AR) $(ARFLAGS) $@ $(foreach lib,$(DEP_ARCH),$(EXTRACT_DIR)/$(EXTRACT_LNAME)/*.o) \
		&& rm -rf $(EXTRACT_DIR) \
		&&) \
	$(if $(strip $(DEP_OBJS?) $(DEP_ARCH)),, \
		$(CC) -x c -c -o $@.empty.o /dev/null \
		&& $(AR) $(ARFLAGS) $@ $@.empty.o \
		&& rm -f $@.empty.o \
		&&) \
	$(RANLIB) $@

MAKECMD.$(SOEXT) = $(LINK.cc) $(DEP_OBJS) $(DEP_ARCH) $(DEP_LIBS) $(LIBS_$(@)) $(LDLIBS) -shared -o $@ \
	$(if $(STRIP_CMD), && $(STRIP_CMD))

DEFAULT_MAKECMD = $(LINK.cc) $(DEP_OBJS) $(DEP_ARCH) $(DEP_LIBS) $(LIBS_$(@)) $(LDLIBS) $(if $(MAP_FILE),-Wl$(COMMA)-Map=$@.map) $(addprefix -T,$(DEP_LD)) -o $@ \
	$(if $(STRIP_CMD), && $(STRIP_CMD)) \
	$(if $(SIZE_CMD), && $(SIZE_CMD)) \
	$(if $(HEX_CMD), && $(HEX_CMD)) \
	$(if $(BIN_CMD), && $(BIN_CMD))

# Add additional dep rules to you can build .dbg, .hex, .bin etc,...
ifneq ($(STRIP_CMD),)
%.dbg: %
	@touch $@
endif

ifneq ($(HEX_CMD),)
%.hex: %
	@touch $@
endif

ifneq ($(BIN_CMD),)
%.bin: %
	@touch $@
endif

########################################################################
# Below is a "Blood sugar sex^H^H^Hmake magik" :) - don't touch it     #
# unless you know what you are doing.                                  #
########################################################################

# This can be useful.  E.g. if you want to set INCLUDES_$(d) for given
# $(d) to the same value as includes for its parent directory plus some
# add ons then: INCLUDES_$(d) := $(INCLUDES_$(parent_dir)) ...
parent_dir = $(patsubst %/,%,$(dir $(d)))

define include_subdir_rules
dir_stack := $(d) $(dir_stack)
d := $(d)/$(1)
$$(eval $$(value HEADER))
include $(addsuffix /Rules.mk,$$(d))
$$(eval $$(value FOOTER))
d := $$(firstword $$(dir_stack))
dir_stack := $$(wordlist 2,$$(words $$(dir_stack)),$$(dir_stack))
endef

define save_vars
DEPS_$(1)$(2) = $(value $(2)_DEPS)
LIBS_$(1)$(2) = $(value $(2)_LIBS)
LDFLAGS_$(1)$(2) = $(value $(2)_LDFLAGS)
CMD_$(1)$(2) = $(value $(2)_CMD)
$(2)_DEPS =
$(2)_LIBS =
$(2)_LDFLAGS =
$(2)_CMD =
endef

define tgt_rule
abs_deps := $$(foreach dep,$$(DEPS_$(1)),$$(if $$(or $$(filter /%,$$(dep)),$$(filter $$$$%,$$(dep))),$$(dep),$$(addprefix $(OBJPATH)/,$$(dep)))) $$(MAKEFILE_DEPS_$$(d)) $$(NONREC_MAKEFILES)
-include $$(addsuffix .d,$$(basename $$(abs_deps)))
$(1): $$(abs_deps) $(if $(findstring $(OBJDIR),$(1)),| $(OBJPATH),)
	$$(or $$(CMD_$(1)),$$(MAKECMD$$(suffix $$@)),$$(DEFAULT_MAKECMD))
endef

# subtree_tgts is now just a special case of a more general get_subtree
# macro since $(call get_subtree,TARGETS,dir) has the same effect but
# I'm keeping it for backward compatibility
define subtree_tgts
$(TARGETS_$(1)) $(foreach sd,$(SUBDIRS_$(1)),$(call subtree_tgts,$(sd)))
endef

define get_subtree
$($(1)_$(2)) $(foreach sd,$(SUBDIRS_$(2)),$(call get_subtree,$(1),$(sd)))
endef

# Define an arbitrary dependency
define define_dep
$(1): $(2)
endef

abs_or_dir = $(filter /%,$(1)) $(addprefix $(2)/,$(filter-out /%,$(1)))

# if we are using out of project build tree then there is no need to
# have dist_clean on per directory level and the one below is enough
ifneq ($(strip $(TOP_BUILD_DIR)),)
dist_clean :
	rm -rf $(TOP_BUILD_DIR)
endif

define daytona_executable
# $(1) - OBJPATH
# $(2) - executable
# $(3) - implicit daytona libs
# $(4) - DEPENDS
# $(5) - LIBS
# $(6) - LINKORDER

#               exe     implicit   items from LINKORDER (in LINKORDER)                                                         remaining items
DEPS_$(1)$(2) = $(2).o  $(3)       $(foreach l,$(filter $(filter-out /%,$(4)),$(6)),$(TOP)/$(l)/$(OBJDIR)/lib$(notdir $(l)).a) $(filter-out $(6),$(4))
LIBS_$(1)$(2) = $(addprefix -l,$(5))
# Allow to be specified
LDFLAGS_$(1)$(2) = $(value $(2)_LDFLAGS)

endef

# Suck in the default rules
include $(MK)/def_rules.mk

# Save the current list of imported makefiles
NONREC_MAKEFILES := $(MAKEFILE_LIST)
