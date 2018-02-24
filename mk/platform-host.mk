# index of platforms for known hosts
KNOWN_PLATFORM_Linux-x86_64 := pc
KNOWN_PLATFORM_Cygwin-x86_64 := pc
KNOWN_PLATFORM_MinGW-x86_64 := pc
KNOWN_PLATFORM_Linux-i686 := pc
KNOWN_PLATFORM_Cygwin-i686 := pc
KNOWN_PLATFORM_MinGW-i686 := pc
KNOWN_PLATFORM_Darwin-x86_64 := mac

OS := $(firstword $(subst -, ,$(HOST_ARCH)))
CPU := $(lastword $(subst -, ,$(HOST_ARCH)))
PLATFORM := $(KNOWN_PLATFORM_$(HOST_ARCH))

# Run tests on this platform natively
PLATFORM_TEST := native
