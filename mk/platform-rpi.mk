HOST_ARCH := Linux-arm7l

PLATFORM := rpi
OS := Linux
CPU := arm7
# we're considering all rpi boards to be approximately
# equivalent - otherwise we'd consider 3 or B definitions
BOARD := rpi

# Run tests on this platform via ssh
PLATFORM_TEST := ssh
