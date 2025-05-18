[ -f "$SRC_DIR/unica/debloat.sh" ] && source "$SRC_DIR/unica/debloat.sh"
[ -f "$SRC_DIR/platform/$TARGET_PLATFORM/debloat.sh" ] && source "$SRC_DIR/platform/$TARGET_PLATFORM/debloat.sh"
[ -f "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh" ] && source "$SRC_DIR/target/$TARGET_CODENAME/debloat.sh"

ODM_DEBLOAT="$(sed "/^$/d" <<< "$ODM_DEBLOAT" | sort)"
PRODUCT_DEBLOAT="$(sed "/^$/d" <<< "$PRODUCT_DEBLOAT" | sort)"
SYSTEM_DEBLOAT="$(sed "/^$/d" <<< "$SYSTEM_DEBLOAT" | sort)"
SYSTEM_EXT_DEBLOAT="$(sed "/^$/d" <<< "$SYSTEM_EXT_DEBLOAT" | sort)"
VENDOR_DEBLOAT="$(sed "/^$/d" <<< "$VENDOR_DEBLOAT" | sort)"
PRISM_DEBLOAT="$(sed "/^$/d" <<< "$PRISM_DEBLOAT" | sort)"
OPTICS_DEBLOAT="$(sed "/^$/d" <<< "$OPTICS_DEBLOAT" | sort)"

[ "$ODM_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "odm" "$1"' "bash" "{}" \
    <<< "$ODM_DEBLOAT"
[ "$PRODUCT_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "product" "$1"' "bash" "{}" \
    <<< "$PRODUCT_DEBLOAT"
[ "$SYSTEM_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system" "$1"' "bash" "{}" \
    <<< "$SYSTEM_DEBLOAT"
[ "$SYSTEM_EXT_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "system_ext" "$1"' "bash" "{}" \
    <<< "$SYSTEM_EXT_DEBLOAT"
[ "$VENDOR_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "vendor" "$1"' "bash" "{}" \
    <<< "$VENDOR_DEBLOAT"
[ "$PRISM_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "prism" "$1"' "bash" "{}" \
    <<< "$PRISM_DEBLOAT"
[ "$OPTICS_DEBLOAT" ] && xargs -I "{}" -P "$(nproc)" \
    bash -c 'source "$SRC_DIR/scripts/utils/module_utils.sh"; DELETE_FROM_WORK_DIR "optics" "$1"' "bash" "{}" \
    <<< "$OPTICS_DEBLOAT"
