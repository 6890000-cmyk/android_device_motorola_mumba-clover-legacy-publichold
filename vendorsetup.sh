#!/bin/bash

echo "--- Initializing Source Sync ---"

clone_if_missing() {
    local repo_url=$1
    local branch=$2
    local target_dir=$3

    if [ -d "$target_dir/.git" ] || [ -d "$target_dir" ]; then
        echo "Skipping: $target_dir already exists"
        return 0
    fi

    echo "Cloning: $target_dir"

    if [ -n "$branch" ]; then
        git clone --branch "$branch" "$repo_url" "$target_dir"
    else
        git clone "$repo_url" "$target_dir"
    fi

    if [ $? -eq 0 ]; then
        echo "Successfully cloned $target_dir"
    else
        echo "Error: Failed to clone $target_dir"
        return 1
    fi
}

# Repo
clone_if_missing "https://github.com/parmodjiris-source/android_device_motorola_mumba.git" "17" "device/motorola/mumba"
clone_if_missing "https://github.com/parmodjiris-source/android_device_motorola_mumba-kernel.git" "17" "device/motorola/mumba-kernel"
clone_if_missing "https://github.com/parmodjiris-source/proprietary_vendor_motorola_mumba" "17" "vendor/motorola/mumba"
clone_if_missing "https://github.com/LineageOS/android_hardware_motorola" "" "hardware/motorola"
clone_if_missing "https://github.com/parmodjiris-source/android_hardware_dolby.git" "" "hardware/dolby"

echo "--- Source Sync Complete ---"

# --- mumba: 上游仓库补丁自动应用（repo sync 后会重新打上，失败会显式告警） ---

apply_mumba_display_fixes() {
    local top="${ANDROID_BUILD_TOP:-$(pwd)}"
    local d="$top/device/motorola/mumba/patches"
    local dis="$top/hardware/qcom-caf/sm8450-6.6/display"
    [ -d "$dis" ] || return 0
    local g="$dis/hal/gralloc/gr_utils.cpp"
    local b="$dis/hal/sdm/libs/dal/Android.bp"
    local changed=0

    # 1) gr_utils.cpp：两段式（先加 #ifdef，再彻底不引用缺失字段）
    if [ -f "$g" ] && ! grep -q 'MFIX_NORESERVED' "$g"; then
        grep -q 'MFIX_METADATA_V2' "$g" || python3 "$d/fix-gralloc-gr_utils.py" >/dev/null 2>&1
        python3 "$d/fix-gralloc-gr_utils-final.py" >/dev/null 2>&1
        grep -q 'MFIX_NORESERVED' "$g" \
            && changed=1 \
            || echo "!!! mumba: gr_utils.cpp 补丁未生效，display HAL 可能编译失败 !!!"
    fi

    # 2) gr_buf_mgr / SnapMetadataManager / SnapAllocCore：25 处引用
    if ! grep -q 'MFIX_NORESERVED' "$dis/hal/gralloc/gr_buf_mgr.cpp" 2>/dev/null; then
        python3 "$d/fix-gralloc-3files.py" >/dev/null 2>&1
        grep -q 'MFIX_NORESERVED' "$dis/hal/gralloc/gr_buf_mgr.cpp" \
            && changed=1 \
            || echo "!!! mumba: gralloc 三文件补丁未生效，display HAL 可能编译失败 !!!"
    fi

    # 3) libsdmdal 缺 display_headers
    if [ -f "$b" ] && ! grep -q 'MFIX_DISPLAY_HEADERS' "$b"; then
        python3 "$d/fix-sdmdal-display-headers.py" >/dev/null 2>&1
        grep -q 'MFIX_DISPLAY_HEADERS' "$b" \
            && changed=1 \
            || echo "!!! mumba: libsdmdal display_headers 补丁未生效，SDM HAL 会编译失败 !!!"
    fi

    # 4) libqdutils / gpu_tonemapper / composer / composer_test_service 缺 display_intf_headers
    if ! grep -q 'display_intf_headers' "$dis/hal/libqdutils/Android.bp" 2>/dev/null \
       || ! grep -q 'display_intf_headers' "$dis/hal/composer/Android.bp" 2>/dev/null; then
        python3 "$d/fix-display-intf-headers.py" >/dev/null 2>&1
        if grep -q 'display_intf_headers' "$dis/hal/libqdutils/Android.bp" 2>/dev/null \
           && grep -q 'display_intf_headers' "$dis/hal/gpu_tonemapper/Android.bp" 2>/dev/null; then
            changed=1
        else
            echo "!!! mumba: display_intf_headers 补丁未生效，display HAL 会编译失败 !!!"
        fi
    fi
    # gpu_tonemapper 重复 header_libs 键修正（幂等）
    if [ -f "$dis/hal/gpu_tonemapper/Android.bp" ]; then
        if [ "$(grep -c 'header_libs' "$dis/hal/gpu_tonemapper/Android.bp")" != "1" ]; then
            python3 "$d/fix-tonemapper-bp.py" >/dev/null 2>&1
        fi
    fi

    [ "$changed" = 1 ] && echo "--- mumba: display/gralloc 兼容补丁已重新应用 ---"
    return 0
}

apply_mumba_vendor_patch() {
    local top="${ANDROID_BUILD_TOP:-$(pwd)}"
    local repo="$top/vendor/lineage"
    local bc="$top/device/motorola/mumba/BoardConfig.mk"
    local patch="$top/device/motorola/mumba/patches/vendor-lineage-kernel-headers.patch"
    [ -d "$repo/.git" ] || return 0
    [ -f "$patch" ] || return 0

    local applied=0
    if grep -q 'tar -C $(TARGET_KERNEL_SOURCE) -cf - .' "$repo/build/soong/Android.bp" 2>/dev/null \
       && ! grep -q '\.Sbox(' "$repo/build/soong/generator/generator.go" 2>/dev/null; then
        applied=1
    fi

    if grep -q 'TARGET_FORCE_PREBUILT_KERNEL := true' "$bc" 2>/dev/null; then
        [ "$applied" = 1 ] && return 0
        echo "--- mumba: applying vendor/lineage kernel-header patch (prebuilt-kernel mode) ---"
        if git -C "$repo" apply "$patch" 2>/dev/null || ( cd "$repo" && patch -p1 -N < "$patch" >/dev/null 2>&1 ); then
            echo "--- mumba: vendor/lineage patch applied ---"
        else
            echo "!!! mumba: vendor/lineage 补丁应用失败，内核头规则会报错，请手动检查 !!!"
        fi
    else
        if [ "$applied" = 1 ]; then
            echo "--- mumba: OSS 内核模式，撤销预编译模式的 tar 补丁 ---"
            git -C "$repo" apply --reverse "$patch" 2>/dev/null \
                || ( cd "$repo" && patch -p1 -R < "$patch" >/dev/null 2>&1 ) \
                || echo "!!! mumba: 撤销失败，请手动检查 vendor/lineage !!!"
        fi
        echo "--- mumba: 提醒：OSS 模式下内核头生成规则需重新处理（make 被 PATH 白名单禁止）---"
    fi
}

apply_mumba_display_fixes
apply_mumba_vendor_patch
