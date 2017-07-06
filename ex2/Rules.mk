TARGETS := app$(EXE)
SUBDIRS := a b

app$(EXE)_DEPS = app.o $(call subtree_tgts,$(d)/a) $(TARGETS_$(d)/b)

# This component builds for stm32f0 (an opt-in-only platform)
OPT_IN_PLATFORMS := stm32f0

# Inherit by all sub-dirs
INHERIT_DIR_VARS_$(d) := OPT_IN_PLATFORMS

# TODO - need a language to specify that this dep is specific to
# this platform/os/cpu,...
ifeq ($(PLATFORM),stm32f0)
ifeq ($(ARM_SEMIHOSTING),)
app$(EXE)_DEPS += hosting.o
endif
endif
