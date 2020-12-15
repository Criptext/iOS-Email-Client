#!/bin/sh -e
echo "Carthage wrapper"
echo "Applying Xcode 12 workaround..."
xcconfig="/tmp/xc12-carthage.xcconfig"

# Xcode 12.x
echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200 = arm64 arm64e armv7 armv7s armv6 armv8' > $xcconfig

# General stuff
echo 'EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))' >> $xcconfig
echo 'ONLY_ACTIVE_ARCH=NO' >> $xcconfig
echo 'VALID_ARCHS = $(inherited) x86_64' >> $xcconfig
export XCODE_XCCONFIG_FILE="$xcconfig"
echo "Workaround applied. xcconfig here: $XCODE_XCCONFIG_FILE"

carthage $@