# [
GET_FP_SENSOR_TYPE()
{
    if [[ "$1" == *"ultrasonic"* ]]; then
        echo "ultrasonic"
    elif [[ "$1" == *"optical"* ]]; then
        echo "optical"
    elif [[ "$1" == *"side"* ]]; then
        echo "side"
    else
        LOGE "Unsupported type: \"$1\""
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [[ "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" != "$TARGET_PRODUCT_SHIPPING_API_LEVEL" ]]; then
    LOG_STEP_IN "- Applying MAINLINE_API_LEVEL patches"

    DECODE_APK "system" "system/framework/services.jar"

    FTP="
    system/framework/services.jar/smali/com/android/server/SystemServer.smali
    system/framework/services.jar/smali/com/android/server/enterprise/hdm/HdmVendorController.smali
    system/framework/services.jar/smali/com/android/server/enterprise/hdm/HdmSakManager.smali
    system/framework/services.jar/smali/com/android/server/knox/dar/ddar/ta/TAProxy.smali
    system/framework/services.jar/smali_classes2/com/android/server/power/PowerManagerUtil.smali
    system/framework/services.jar/smali_classes2/com/android/server/sepunion/EngmodeService\$EngmodeTimeThread.smali
    "
    for f in $FTP; do
        sed -i \
            "s/\"MAINLINE_API_LEVEL: $SOURCE_PRODUCT_SHIPPING_API_LEVEL\"/\"MAINLINE_API_LEVEL: $TARGET_PRODUCT_SHIPPING_API_LEVEL\"/g" \
            "$APKTOOL_DIR/$f"
        sed -i "s/\"$SOURCE_PRODUCT_SHIPPING_API_LEVEL\"/\"$TARGET_PRODUCT_SHIPPING_API_LEVEL\"/g" "$APKTOOL_DIR/$f"
    done
    LOG_STEP_OUT
fi

if [[ "$SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" != "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" && "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" != "4" ]]; then
    LOG_STEP_IN "- Applying auto brightness type patches"

    DECODE_APK "system" "system/framework/services.jar"
    DECODE_APK "system" "system/framework/ssrm.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

    FTP="
    system/framework/services.jar/smali_classes2/com/android/server/power/PowerManagerUtil.smali
    system/framework/ssrm.jar/smali/com/android/server/ssrm/PreMonitor.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/Rune.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS\"/\"$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS\"/g" "$APKTOOL_DIR/$f"
    done

    # WORKAROUND: Skip failure on CALIBRATEDLUX
    if [[ "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" == "3" ]]; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libsensorservice.so" "284B009420008052" "284B009400008052"
    fi
    LOG_STEP_OUT
fi

if [[ "$SOURCE_FINGERPRINT_CONFIG_SENSOR" != "$TARGET_FINGERPRINT_CONFIG_SENSOR" ]]; then
    LOG_STEP_IN "- Applying fingerprint sensor patches"

    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/framework/services.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
    DECODE_APK "system" "system/priv-app/BiometricSetting/BiometricSetting.apk"
    DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

    FTP="
    system/framework/framework.jar/smali_classes2/android/hardware/fingerprint/FingerprintManager.smali
    system/framework/framework.jar/smali_classes2/android/hardware/fingerprint/HidlFingerprintSensorConfig.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/bio/fingerprint/SemFingerprintManager.smali
    system/framework/framework.jar/smali_classes5/com/samsung/android/bio/fingerprint/SemFingerprintManager\$Characteristics.smali
    system/framework/framework.jar/smali_classes6/com/samsung/android/rune/InputRune.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/biometrics/fingerprint/FingerprintEntry.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/biometrics/fingerprint/FingerprintLockSettings.smali
    "
    for f in $FTP; do
        sed -i "s/$SOURCE_FINGERPRINT_CONFIG_SENSOR/$TARGET_FINGERPRINT_CONFIG_SENSOR/g" "$APKTOOL_DIR/$f"
    done

    if [[ "$(GET_FP_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "ultrasonic" ]]; then
        ADD_TO_WORK_DIR "e1sxxx" "system" "system/bin/surfaceflinger"
        ADD_TO_WORK_DIR "e1sxxx" "system" "system/lib64/libgui.so"
        ADD_TO_WORK_DIR "e1sxxx" "system" "system/lib64/libui.so"
        APPLY_PATCH "system" "system/framework/services.jar" "$SRC_DIR/unica/patches/product_feature/fingerprint/services.jar/0001-Set-FP_FEATURE_SENSOR_IS_OPTICAL-to-false.patch"
        APPLY_PATCH "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" "$SRC_DIR/unica/patches/product_feature/fingerprint/BiometricSetting.apk/0001-Set-FP_FEATURE_SENSOR_IS_OPTICAL-to-false.patch"
        APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$SRC_DIR/unica/patches/product_feature/fingerprint/SystemUI.apk/0001-Set-SECURITY_FINGERPRINT_IN_DISPLAY_OPTICAL-to-false.patch"
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BIOAUTH_CONFIG_FINGERPRINT_FEATURES" "ultrasonic_display_phone"
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_LOCAL_HBM" "0"
    elif [[ "$(GET_FP_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "optical" ]]; then
        APPLY_PATCH "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" "$SRC_DIR/unica/patches/product_feature/fingerprint/BiometricSetting.apk/0002-Always-use-ultrasonic-FOD-animation.patch"
    elif [[ "$(GET_FP_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "side" ]]; then
        ADD_TO_WORK_DIR "b6qxxx" "system" "."
        DELETE_FROM_WORK_DIR "system" "system/priv-app/BiometricSetting/oat"
        APPLY_PATCH "system" "system/framework/services.jar" "$SRC_DIR/unica/patches/product_feature/fingerprint/services.jar/0001-Set-FP_FEATURE_SENSOR_IS_OPTICAL-to-false.patch"
        APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$SRC_DIR/unica/patches/product_feature/fingerprint/SystemUI.apk/0001-Set-SECURITY_FINGERPRINT_IN_DISPLAY_OPTICAL-to-false.patch"
        APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$SRC_DIR/unica/patches/product_feature/fingerprint/SystemUI.apk/0002-Set-SECURITY_FINGERPRINT_IN_DISPLAY-to-false.patch"
        APPLY_PATCH "system" "system/framework/services.jar" "$SRC_DIR/unica/patches/product_feature/fingerprint/services.jar/0002-Set-FP_FEATURE_SENSOR_IS_IN_DISPLAY_TYPE-to-false.patch"
    fi
    LOG_STEP_OUT
fi

if ! $SOURCE_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        LOG_STEP_IN "- Applying multi resolution patches"

        DECODE_APK "system" "system/framework/framework.jar"
        DECODE_APK "system" "system/framework/gamemanager.jar"
        DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

        ADD_TO_WORK_DIR "e2sxxx" "system" "system/bin/bootanimation"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/bin/surfaceflinger"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/lib64/libgui.so"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/lib64/libui.so"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/lib64/libandroid_runtime.so"
        ADD_TO_WORK_DIR "e2sxxx" "system" "media"
        APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/product_feature/resolution/framework.jar/0001-Enable-dynamic-resolution-control.patch"
        APPLY_PATCH "system" "system/framework/gamemanager.jar" "$SRC_DIR/unica/patches/product_feature/resolution/gamemanager.jar/0001-Enable-dynamic-resolution-control.patch"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/resolution/SecSettings.apk/0001-Enable-dynamic-resolution-control.patch"
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_DYN_RESOLUTION_CONTROL" "WQHD,FHD,HD"
        LOG_STEP_OUT
    fi
fi

if ! $SOURCE_LCD_SUPPORT_MDNIE_HW; then
    if $TARGET_LCD_SUPPORT_MDNIE_HW; then
        LOG_STEP_IN "- Applying HW mDNIe patches"

        DECODE_APK "system" "system/framework/framework.jar"
        DECODE_APK "system" "system/framework/services.jar"
        DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
        DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_SUPPORT_MDNIE_HW" "TRUE"
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_COLOR_LENS" "TRUE"
        APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/product_feature/mdnie/hw/framework.jar/0001-Enable-HW-mDNIe.patch"
        APPLY_PATCH "system" "system/framework/services.jar" "$SRC_DIR/unica/patches/product_feature/mdnie/hw/services.jar/0001-Enable-HW-mDNIe.patch"
        APPLY_PATCH "system" "system/framework/services.jar" "$SRC_DIR/unica/patches/product_feature/mdnie/hw/services.jar/0002-Enable-EAD.patch"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/mdnie/hw/SecSettings.apk/0001-Enable-EAD.patch"
        APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$SRC_DIR/unica/patches/product_feature/mdnie/hw/SystemUI.apk/0001-Enable-EAD.patch"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/bin/mafpc_write" 0 2000 755 "u:object_r:mafpc_write_exec:s0"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sead.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "e2sxxx" "system" "system/priv-app/EnvironmentAdaptiveDisplay"
        LOG_STEP_OUT
    fi
fi

if ! $SOURCE_MDNIE_SUPPORT_HDR_EFFECT; then
    if $TARGET_MDNIE_SUPPORT_HDR_EFFECT; then
        LOG_STEP_IN "- Applying mDNIe HDR effect patches"

        DECODE_APK "system" "system/priv-app/SettingsProvider/SettingsProvider.apk"

        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT" "TRUE"
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_SUPPORT_HW_HDR" "TRUE"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/mdnie/hdr/SecSettings.apk/0001-Enable-HDR-Settings.patch"
        APPLY_PATCH "system" "system/priv-app/SettingsProvider/SettingsProvider.apk" "$SRC_DIR/unica/patches/product_feature/mdnie/hdr/SettingsProvider.apk/0001-Enable-HDR-Settings.patch"
        LOG_STEP_OUT
    fi
fi

if [[ "$SOURCE_COMMON_CONFIG_MDNIE_MODE" != "$TARGET_COMMON_CONFIG_MDNIE_MODE" ]]; then
    LOG_STEP_IN "- Applying mDNIe features patches"

    DECODE_APK "system" "system/framework/services.jar"

    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_MDNIE_MODE" "$TARGET_COMMON_CONFIG_MDNIE_MODE"

    FTP="
    system/framework/services.jar/smali_classes2/com/samsung/android/hardware/display/SemMdnieManagerService.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_COMMON_CONFIG_MDNIE_MODE\"/\"$TARGET_COMMON_CONFIG_MDNIE_MODE\"/g" "$APKTOOL_DIR/$f"
    done
    LOG_STEP_OUT
fi

DECODE_APK "system" "system/framework/framework.jar"

if [[ "$TARGET_LCD_CONFIG_SEAMLESS_BRT" == "none" && "$TARGET_LCD_CONFIG_SEAMLESS_LUX" == "none" ]]; then
    APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/product_feature/hfr/framework.jar/0001-Remove-brightness-threshold-values.patch"
else

    FTP="
    system/framework/framework.jar/smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_LCD_CONFIG_SEAMLESS_BRT\"/\"$TARGET_LCD_CONFIG_SEAMLESS_BRT\"/g" "$APKTOOL_DIR/$f"
        sed -i "s/\"$SOURCE_LCD_CONFIG_SEAMLESS_LUX\"/\"$TARGET_LCD_CONFIG_SEAMLESS_LUX\"/g" "$APKTOOL_DIR/$f"
    done
fi

if [[ "$SOURCE_LCD_CONFIG_HFR_MODE" != "$TARGET_LCD_CONFIG_HFR_MODE" ]]; then
    LOG_STEP_IN "- Applying HFR_MODE patches"

    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/framework/gamemanager.jar"
    DECODE_APK "system" "system/framework/secinputdev-service.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
    DECODE_APK "system" "system/priv-app/SettingsProvider/SettingsProvider.apk"
    DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

    FTP="
    system/framework/framework.jar/smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali
    system/framework/gamemanager.jar/smali/com/samsung/android/game/GameManagerService.smali
    system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputDeviceManagerService.smali
    system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputFeatures.smali
    system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputFeaturesExtra.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
    system/priv-app/SettingsProvider/SettingsProvider.apk/smali/com/android/providers/settings/DatabaseHelper.smali
    system_ext/priv-app/SystemUI/SystemUI.apk/smali/com/android/systemui/LsRune.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_LCD_CONFIG_HFR_MODE\"/\"$TARGET_LCD_CONFIG_HFR_MODE\"/g" "$APKTOOL_DIR/$f"
    done

    if [[ "$TARGET_LCD_CONFIG_HFR_MODE" -eq 0 ]]; then
        REPL=1
    else
        REPL=$TARGET_LCD_CONFIG_HFR_MODE
    fi
    sed -i "s/\"$SOURCE_LCD_CONFIG_HFR_MODE\"/\"$REPL\"/g" "$APKTOOL_DIR/system/framework/framework.jar/smali_classes6/com/samsung/android/rune/CoreRune.smali"
    LOG_STEP_OUT
fi

if [[ "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" != "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" ]]; then
    LOG_STEP_IN "- Applying HFR_SUPPORTED_REFRESH_RATE patches"

    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

    FTP="
    system/framework/framework.jar/smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
    "
    for f in $FTP; do
        if [[ "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" != "none" ]]; then
            sed -i "s/\"$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE\"/\"$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE\"/g" "$APKTOOL_DIR/$f"
        else
            sed -i "s/\"$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE\"/\"\"/g" "$APKTOOL_DIR/$f"
        fi
    done
    LOG_STEP_OUT
fi
if [[ "$SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" != "$TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" ]]; then
    LOG_STEP_IN "- Applying HFR_DEFAULT_REFRESH_RATE patches"

    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
    DECODE_APK "system" "system/priv-app/SettingsProvider/SettingsProvider.apk"

    FTP="
    system/framework/framework.jar/smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
    system/priv-app/SettingsProvider/SettingsProvider.apk/smali/com/android/providers/settings/DatabaseHelper.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE\"/\"$TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE\"/g" "$APKTOOL_DIR/$f"
    done
    LOG_STEP_OUT
fi

if [[ "$TARGET_DISPLAY_CUTOUT_TYPE" == "right" ]]; then
    LOG_STEP_IN "- Applying right cutout patch"
    APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$SRC_DIR/unica/patches/product_feature/cutout/SystemUI.apk/0001-Add-right-cutout-support.patch"
    LOG_STEP_OUT
fi

if [[ "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" != "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" ]]; then
    LOG_STEP_IN "- Applying DVFS patches"

    DECODE_APK "system" "system/framework/ssrm.jar"
    DECODE_APK "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

    FTP="
    system/framework/ssrm.jar/smali/com/android/server/ssrm/Feature.smali
    system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/smali/p1/c.smali
    system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/smali/x1/e.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME\"/\"$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME\"/g" "$APKTOOL_DIR/$f"
    done
    LOG_STEP_OUT
fi

if [[ "$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" != "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" ]]; then
    LOG_STEP_IN "- Applying SIOP patches"

    DECODE_APK "system" "system/framework/ssrm.jar"
    DECODE_APK "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

    FTP="
    system/framework/ssrm.jar/smali/com/android/server/ssrm/Feature.smali
    system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/smali/S1/v.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME\"/\"$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME\"/g" "$APKTOOL_DIR/$f"
    done
    LOG_STEP_OUT
fi

if $SOURCE_COMMON_SUPPORT_EMBEDDED_SIM; then
    if ! $TARGET_COMMON_SUPPORT_EMBEDDED_SIM; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" --delete
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_EMBEDDED_SIM" --delete
    fi
fi

if [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/etc/permissions/com.sec.feature.cover.xml" ]; then
    LOG_STEP_IN "- Adding LED Case Cover support"
    ADD_TO_WORK_DIR "p3sxxx" "system" "system/priv-app/LedCoverService/LedCoverService.apk"
    ADD_TO_WORK_DIR "p3sxxx" "system" "system/etc/permissions/privapp-permissions-com.sec.android.cover.ledcover.xml"
    LOG_STEP_OUT
fi

if [ ! -f "$FW_DIR/${MODEL}_${REGION}/vendor/etc/permissions/android.hardware.strongbox_keystore.xml" ]; then
    LOG_STEP_IN "- Applying strongbox patches"
    APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/product_feature/strongbox/framework.jar/0001-Disable-StrongBox-in-DevRootKeyATCmd.patch"
    LOG_STEP_OUT
fi

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
DECODE_APK "system" "system/framework/semwifi-service.jar"

if $SOURCE_SUPPORT_WIFI_7; then
    if ! $TARGET_SUPPORT_WIFI_7; then
        LOG_STEP_IN "- Applying Wi-Fi 7 patches"
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" "$SRC_DIR/unica/patches/product_feature/wifi/semwifi-service.jar/0001-Disable-Wi-Fi-7-support.patch"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/wifi/SecSettings.apk/0001-Disable-Wi-Fi-7-support.patch"
        LOG_STEP_OUT
    fi
fi

if $SOURCE_SUPPORT_HOTSPOT_DUALAP; then
    if ! $TARGET_SUPPORT_HOTSPOT_DUALAP; then
        LOG_STEP_IN "- Applying Hotspot DualAP patches"
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" "$SRC_DIR/unica/patches/product_feature/wifi/semwifi-service.jar/0002-Disable-DualAP-support.patch"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/wifi/SecSettings.apk/0002-Disable-DualAP-support.patch"
        LOG_STEP_OUT
    fi
fi

if $SOURCE_SUPPORT_HOTSPOT_WPA3; then
    if ! $TARGET_SUPPORT_HOTSPOT_WPA3; then
        LOG_STEP_IN "- Applying Hotspot WPA3 patches"
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" "$SRC_DIR/unica/patches/product_feature/wifi/semwifi-service.jar/0003-Disable-Hotspot-WPA3-support.patch"
        LOG_STEP_OUT
    fi
fi

if $SOURCE_SUPPORT_HOTSPOT_6GHZ; then
    if ! $TARGET_SUPPORT_HOTSPOT_6GHZ; then
        LOG_STEP_IN "- Applying Hotspot 6GHz patches"
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" "$SRC_DIR/unica/patches/product_feature/wifi/semwifi-service.jar/0004-Disable-Hotspot-6GHz-support.patch"
        LOG_STEP_OUT
    fi
fi

if $SOURCE_SUPPORT_HOTSPOT_WIFI_6; then
    if ! $TARGET_SUPPORT_HOTSPOT_WIFI_6; then
        LOG_STEP_IN "- Applying Hotspot Wi-Fi 6 patches"
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" "$SRC_DIR/unica/patches/product_feature/wifi/semwifi-service.jar/0004-Disable-Hotspot-6GHz-support.patch"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/wifi/SecSettings.apk/0003-Disable-Hotspot-Wi-Fi-6.patch"
        LOG_STEP_OUT
    fi
fi

if $SOURCE_SUPPORT_HOTSPOT_ENHANCED_OPEN; then
    if ! $TARGET_SUPPORT_HOTSPOT_ENHANCED_OPEN; then
        LOG_STEP_IN "- Applying Hotspot Enhanced Open patches"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/wifi/SecSettings.apk/0004-Disable-Hotspot-Enhanced-Open.patch"
        LOG_STEP_OUT
    fi
fi

if ! $SOURCE_AUDIO_SUPPORT_ACH_RINGTONE; then
    if $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
        LOG_STEP_IN "- Applying ACH ringtone patches"
        APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/product_feature/audio/framework.jar/0001-Enable-ACH-ringtone-support.patch"
        LOG_STEP_OUT
    fi
fi

if $SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION_SOUND; then
    if ! $TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION_SOUND; then
        LOG_STEP_IN "Applying virtual vibration patches"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$SRC_DIR/unica/patches/product_feature/audio/SecSettings.apk/0002-Disable-Virtual-Vibration-support.patch"
        LOG_STEP_OUT
    fi
fi