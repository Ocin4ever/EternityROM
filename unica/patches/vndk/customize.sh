if [[ "$SOURCE_BOARD_API_LEVEL" != "$TARGET_BOARD_API_LEVEL" ]]; then
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        SYS_EXT_DIR="$WORK_DIR/system_ext"
    else
        SYS_EXT_DIR="$WORK_DIR/system/system/system_ext"
    fi

    NO_APEX=false
    [[ $SOURCE_BOARD_API_LEVEL == "none" ]] && NO_APEX=true

    if [ ! -f "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_BOARD_API_LEVEL.apex" ]; then
        if ! $NO_APEX; then
            DELETE_FROM_WORK_DIR "system_ext" "apex/com.android.vndk.v$SOURCE_BOARD_API_LEVEL.apex"
        fi

        case "$TARGET_BOARD_API_LEVEL" in
            "30")
                ADD_TO_WORK_DIR "a73xqxx" "system_ext" "apex/com.android.vndk.v30.apex" 0 0 644 "u:object_r:system_file:s0"
                ;;
            "31")
                ADD_TO_WORK_DIR "r11sxxx" "system_ext" "apex/com.android.vndk.v31.apex" 0 0 644 "u:object_r:system_file:s0"
                ;;
            "33")
                ADD_TO_WORK_DIR "dm3qxxx" "system_ext" "apex/com.android.vndk.v33.apex" 0 0 644 "u:object_r:system_file:s0"
                ;;
            "34")
                ADD_TO_WORK_DIR "r12sxxx" "system_ext" "apex/com.android.vndk.v34.apex" 0 0 644 "u:object_r:system_file:s0"
                ;;
        esac
        if $NO_APEX; then
            sed -i '$d' "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "    <vendor-ndk>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "        <version>$TARGET_BOARD_API_LEVEL</version>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "    </vendor-ndk>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "</manifest>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
        else
            sed -i "s/version>$SOURCE_BOARD_API_LEVEL/version>$TARGET_BOARD_API_LEVEL/g" "$SYS_EXT_DIR/etc/vintf/manifest.xml"
        fi
    else
        LOG "- VNDK v$TARGET_BOARD_API_LEVEL apex is already in place. Ignoring."
    fi
else
    LOG "- SOURCE_BOARD_API_LEVEL and TARGET_BOARD_API_LEVEL are the same. Ignoring."
fi
