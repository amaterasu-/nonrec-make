# Common toolchain definitions for gcc toolchains

CC := $(TOOLCHAIN_PREFIX)gcc
CXX := $(TOOLCHAIN_PREFIX)g++
AR := $(TOOLCHAIN_PREFIX)ar
RANLIB := $(TOOLCHAIN_PREFIX)ranlib
OBJDUMP := $(TOOLCHAIN_PREFIX)objdump
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy
SIZE := $(TOOLCHAIN_PREFIX)size
STRIP := $(TOOLCHAIN_PREFIX)strip

ARFLAGS := $(ARFLAGS)D

# You should probably use this by default
CPPFLAGS += -Werror

# Always use gdb debug symbols - we can strip them out separately
CPPFLAGS += -ggdb
LDFLAGS  += -ggdb

# setup release/debug flags
ifeq ($(RELEASE),true)
CPPFLAGS += -DNDEBUG -DRELEASE

ifeq ($(OPTIMISE_FOR_SIZE),true)
CPPFLAGS += -Os
else
CPPFLAGS += -O3
endif

else

# GCC recommends -Og instead of -O0 - use -Og by default
ifeq ($(NO_OPTIMISE),true)
CPPFLAGS += -O0
else
CPPFLAGS += -Og
endif

endif

ifeq ($(ENABLE_PROFILE),true)
CPPFLAGS += -pg
LDFLAGS  += -pg
endif

# Perform stripping of unused code/data.  You can disable this (but you won't want to)
ifneq ($(NO_GC_SECTIONS),true)
CPPFLAGS += -fdata-sections -ffunction-sections
LDFLAGS += -Wl,--gc-sections
endif

# Mark all symbols as hidden (not exported to shared-objects)
ifneq ($(NO_DEFAULT_HIDDEN),true)
CPPFLAGS += -fvisibility=hidden
CXXFLAGS += -fvisibility-inlines-hidden

# This behaviour is similar to windows "dllexport" behaviour
# Mark your exported symbols as follows
#  __attribute__ ((visibility("default")))

# To help you work out importing vs exporting here's a variable based on the
# directory being built:
CPPFLAGS += -DBUILD$(subst -,_,$(subst /,_,$(subst $(TOP),,$(@RD))))

# so you can use the following - eg in this/component/header.h
#
#  #ifdef BUILD_this_component /* export symbols if building in this directory */
#  #define THIS_COMPONENT_EXPORT __attribute__ ((visibility("default")))
#  #else
#  #define THIS_COMPONENT_EXPORT
#  #endif
#
#  int THIS_COMPONENT_EXPORT external_fn(int i);
#  int internal_fn(int i);
#
# When the header is included for .c/.cpp files in the current directory
# the export clause becomes active

endif

ifneq ($(CXX_STD),)
CXXFLAGS += -std=c++$(CXX_STD)
else
CXXFLAGS += -std=c++11
endif

STRIPFLAGS = --strip-unneeded

STRIP_CMD = $(OBJCOPY) --only-keep-debug $@ $@.dbg && $(STRIP) $(STRIPFLAGS) $@ && $(OBJCOPY) --add-gnu-debuglink=$@.dbg $@

ifeq ($(BARE_METAL_TARGET),true)

HEX_CMD = $(OBJCOPY) -O ihex $@ $@.hex
BIN_CMD = $(OBJCOPY) -O binary $@ $@.bin
SIZE_CMD = $(SIZE) $@

# generate map file
MAP_FILE := true

CXXFLAGS += -fno-exceptions -fno-use-cxa-atexit

ifeq ($(ARM_SEMIHOSTING),true)
CPPFLAGS += -DARM_SEMIHOSTING
LDFLAGS +=  --specs=rdimon.specs
endif

LDFLAGS += --specs=nano.specs

else

CPPFLAGS += -D_REENTRANT -D_POSIX_C_SOURCE=200809L
CPPFLAGS += -pthread

endif
