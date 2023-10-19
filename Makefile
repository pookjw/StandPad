TARGET := iphone:clang:latest
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += modules/StandPadSpringBoard
SUBPROJECTS += modules/StandPadPosterBoard
SUBPROJECTS += modules/StandPadPreferences

include $(THEOS_MAKE_PATH)/aggregate.mk
