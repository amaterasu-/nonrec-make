# Clear vars used by this make system
define HEADER
SRCS :=
SRCS_EXCLUDES :=
OBJS :=
CLEAN :=
TARGETS :=
SUBDIRS :=

# Clear user vars
$(foreach v,$(VERB_VARS) $(OBJ_VARS) $(DIR_VARS),$(eval $(v) := ))

MAKEFILE_DEPS := $(if $(filter $(TOP),$(d)),$(d)/Rules.top,$(d)/Rules.mk) $(MAKEFILE_DEPS_$(parent_dir))
endef
