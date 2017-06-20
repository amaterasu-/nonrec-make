# Working around ancient toolchain on Ubuntu 14.04 by selecting
# the hard float toolchain which is newer for some reason
TOOLCHAIN_PREFIX := arm-linux-gnueabihf-

ENDIAN := little

include $(MK)/toolchain-gcc.mk

# Any other target specific settings
CPPFLAGS += -march=armv7-a
