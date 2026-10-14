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

# --- mumba: vendor/lineage 内核头规则补丁（按内核模式自动识别） ---
# 预编译内核模式（当前）: 需要 tar 版补丁
# OSS 源码内核模式        : 必须撤销 tar 版补丁，并另行处理内核头生成（make 被 PATH 白名单禁止）
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
        # ---- 预编译内核模式 ----
        [ "$applied" = 1 ] && return 0
        echo "--- mumba: applying vendor/lineage kernel-header patch (prebuilt-kernel mode) ---"
        if git -C "$repo" apply "$patch" 2>/dev/null || ( cd "$repo" && patch -p1 -N < "$patch" >/dev/null 2>&1 ); then
            echo "--- mumba: vendor/lineage patch applied ---"
        else
            echo "!!! mumba: vendor/lineage 补丁应用失败，内核头规则会报错，请手动检查 !!!"
        fi
    else
        # ---- OSS 源码内核模式 ----
        if [ "$applied" = 1 ]; then
            echo "--- mumba: OSS 内核模式，撤销预编译模式的 tar 补丁 ---"
            git -C "$repo" apply --reverse "$patch" 2>/dev/null \
                || ( cd "$repo" && patch -p1 -R < "$patch" >/dev/null 2>&1 ) \
                || echo "!!! mumba: 撤销失败，请手动检查 vendor/lineage !!!"
        fi
        echo "--- mumba: 提醒：OSS 模式下内核头生成规则需重新处理（make 被 PATH 白名单禁止），见 OSS内核切换备忘.md 第 7.3 节 ---"
    fi
}
apply_mumba_vendor_patch
