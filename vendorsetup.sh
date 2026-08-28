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
