include theos/makefiles/common.mk

TWEAK_NAME = UpdateHider
UpdateHider_FILES = Tweak.xm SA_ActionSheet.m HeaderView.m
UpdateHider_FRAMEWORKS = UIKit CoreGraphics
UpdateHider_PRIVATE_FRAMEWORKS = iTunesStoreUI

SUBPROJECTS = UpdateHiderSettings

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk
