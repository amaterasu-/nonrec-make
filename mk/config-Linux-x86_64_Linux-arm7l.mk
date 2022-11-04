TOOLCHAIN_PREFIX := arm-linux-gnueabi-

ENDIAN := little

include $(MK)/toolchain-gcc.mk

# Any other target specific settings
CPPFLAGS += -march=armv7-a

# On Debian et al,... use common gdb-multiarch
GDB := gdb-multiarch
