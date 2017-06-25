HOST_ARCH := None-cortex_m0

OS := None
CPU := cortex_m0
PLATFORM := stm32f0

# For this test repository - need to set SEMIHOSTING to true so
# we can link printf et al in bare-metal

# Real projects will want to write their own C-library-hosting
#ARM_SEMIHOSTING := true
