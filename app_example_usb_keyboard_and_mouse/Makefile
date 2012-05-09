BASE_DIR = .
TARGET = keyboard
APP_NAME = app_example_usb_keyboard_and_mouse
XCC_FLAGS = -Wall -O2 -report -fsubword-select -DUSB_CORE=0

USED_MODULES = module_usb_shared module_xud module_ps2


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common

