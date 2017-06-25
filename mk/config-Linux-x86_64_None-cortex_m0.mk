TOOLCHAIN_PREFIX := arm-none-eabi-

ENDIAN := little
OPTIMISE_FOR_SIZE := true
BARE_METAL_TARGET := true

CPU := cortex_m0
OS := None
PLATFORM := stm32f0

include $(MK)/toolchain-gcc.mk

# Any other target specific settings
CPPFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m0 -mthumb-interwork

# nano-lib's definition of wchar_t size conflicts with crtbegin.o/crtend.o
# There is no reason crtbegin/end should export symbols so we can surpress
# this warning.
LDFLAGS += -Wl,--no-wchar-size-warning
