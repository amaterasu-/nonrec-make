DAYTONA := true

LINKORDER := daytona/first \
	daytona/second \
	daytona/third

SUBDIRS := \
	second \
	third \
	first

INCLUDES_$(d) := $(d)
INHERIT_DIR_VARS_$(d) := INCLUDES
