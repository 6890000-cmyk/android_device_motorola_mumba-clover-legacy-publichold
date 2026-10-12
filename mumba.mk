#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Evolution X (cnb / Android 17) 产品配置 —— 由 Clover 版 clover_mumba.mk 转换而来
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from mumba device
$(call inherit-product, device/motorola/mumba/device.mk)

# Inherit Evolution X common config
# 注意：Evo X 的 manifest 把 vendor_evolution 仓库 checkout 到 vendor/lineage
#      （snippets/evolution.xml: <project path="vendor/lineage" name="vendor_evolution" .../>）
#      所以这里的路径必须是 vendor/lineage，不要写成 vendor/evolution。
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := mumba
PRODUCT_DEVICE := mumba
PRODUCT_MANUFACTURER := motorola
PRODUCT_BRAND := Motorola
PRODUCT_MODEL := G57 Power

PRODUCT_GMS_CLIENTID_BASE := android-motorola

# 与作者 2026-09-28 发布包一致的 build 身份：
#   BuildDesc        = 摩托原厂描述（保留）
#   BuildFingerprint = Google GSI 指纹（过 Play 完整性用；不想要就换成
#                      motorola/mumba_g/mumba:16/W1WAAS36M.48-12-ST12.1/c557f6:user/release-keys）
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="mumba_g-user 16 W1WAAS36M.48-12-ST12.1 c557f6 release-keys" \
    BuildFingerprint=google/grizzly_beta/grizzly:17/CP41.260828.004.A8/16319058:user/release-keys \
    DeviceName=mumba \
    DeviceProduct=mumba \
    SystemDevice=mumba \
    SystemName=mumba

TARGET_ENABLE_BLUR := true
TARGET_SUPPORTS_QUICK_TAP := true
TARGET_FACE_UNLOCK_SUPPORTED := true
