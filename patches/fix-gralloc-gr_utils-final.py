import sys

p = '/home/builder/evox/hardware/qcom-caf/sm8450-6.6/display/hal/gralloc/gr_utils.cpp'
s = open(p).read()

old_block = """  // MFIX_METADATA_V2: reserved_size / custom_content_md_reserved_size only exist
  // when METADATA_V2 is enabled; keep 0 otherwise (matches GetMetaDataSize()).
  uint64_t reserved_region_size = 0;
  uint64_t custom_content_md_region_size = 0;
#ifdef METADATA_V2
  reserved_region_size = handle->reserved_size;
  custom_content_md_region_size = handle->custom_content_md_reserved_size;
#endif
"""
new_block = """  // MFIX_METADATA_V2: 本树使用的 private_handle_t 不含 reserved_size /
  // custom_content_md_reserved_size（源码与头文件版本不匹配），这两个尺寸只能取 0，
  // 与 GetMetaDataSize() 在无 METADATA_V2 时的行为一致。
  uint64_t reserved_region_size = 0;
  uint64_t custom_content_md_region_size = 0;
"""

old_block2 = """    uint64_t reserved_region_size = 0;
    uint64_t custom_content_md_region_size = 0;
#ifdef METADATA_V2
    reserved_region_size = handle->reserved_size;
    custom_content_md_region_size = handle->custom_content_md_reserved_size;
#endif
"""
new_block2 = """    // MFIX_METADATA_V2: 同上，头文件无该字段，取 0
    uint64_t reserved_region_size = 0;
    uint64_t custom_content_md_region_size = 0;
"""

if old_block not in s:
    sys.exit('block1 not found')
s = s.replace(old_block, new_block, 1)

if old_block2 not in s:
    sys.exit('block2 not found')
s = s.replace(old_block2, new_block2, 1)

open(p, 'w').write(s)
print('gr_utils.cpp 已改为完全不引用缺失字段')
