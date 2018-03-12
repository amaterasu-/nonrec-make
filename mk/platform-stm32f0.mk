HOST_ARCH := None-cortex_m0

OS := None
CPU := cortex_m0
PLATFORM := stm32f0

# For this test repository - need to set SEMIHOSTING to true so
# we can link printf et al in bare-metal

# Real projects will want to write their own C-library-hosting
#ARM_SEMIHOSTING := true

# Require directories to actually ask for this target
# - match using OPT_IN_PLATFORMS on OS/CPU/PLATFORM
PLATFORM_OPT_IN := true

ifneq ($(ARM_SEMIHOSTING),true)
# Can't yet handle openocd debug with ARM_SEMIHOSTING
PLATFORM_TEST := openocd
# TODO = move this definition to a board-specific location
OPENOCD_BOARD = board/stm32f0discovery.cfg
endif
