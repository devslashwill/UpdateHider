#!/bin/sh

rm *.deb
make package
BUILD_NUM=$(cat .theos/packages/com.whomer.UpdateHider-0.0.1)
DEB_FILE="com.whomer.UpdateHider_0.0.1-${BUILD_NUM}_iphoneos-arm.deb"
scp $DEB_FILE root@192.168.2.5:~/
ssh root@192.168.2.5 "dpkg -i $DEB_FILE && rm $DEB_FILE && killall AppStore && killall Preferences"
ssh root@192.168.2.5 "cmdapplauncher com.apple.AppStore"