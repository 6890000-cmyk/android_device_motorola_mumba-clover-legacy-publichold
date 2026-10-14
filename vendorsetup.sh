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

# --- mumba: 自动恢复 vendor/lineage 内核头规则补丁（repo sync 后依然有效） ---
apply_mumba_vendor_patch() {
    local top="${ANDROID_BUILD_TOP:-$(pwd)}"
    local repo="$top/vendor/lineage"
    local patch="$top/device/motorola/mumba/patches/vendor-lineage-kernel-headers.patch"
    [ -d "$repo/.git" ] || return 0
    [ -f "$patch" ] || return 0
    if grep -q 'tar -C $(TARGET_KERNEL_SOURCE) -cf - .' "$repo/build/soong/Android.bp" 2>/dev/null \
       && ! grep -q '\.Sbox(' "$repo/build/soong/generator/generator.go" 2>/dev/null; then
        return 0
    fi
    echo "--- mumba: applying vendor/lineage kernel-header patch ---"
    if git -C "$repo" apply "$patch" 2>/dev/null || ( cd "$repo" && patch -p1 -N < "$patch" >/dev/null 2>&1 ); then
        echo "--- mumba: vendor/lineage patch applied ---"
    else
        echo "!!! mumba: vendor/lineage 补丁应用失败，内核头规则可能报错，请手动检查 !!!"
    fi
}
apply_mumba_vendor_patch
