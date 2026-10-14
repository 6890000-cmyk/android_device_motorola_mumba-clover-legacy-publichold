import sys

p = '/home/builder/evox/hardware/qcom-caf/sm8450-6.6/display/hal/gralloc/gr_utils.cpp'
s = open(p).read()

if 'MFIX_METADATA_V2' in s:
    print('already patched')
    sys.exit(0)

old1 = """void UnmapAndReset(private_handle_t *handle) {
  uint64_t reserved_region_size = handle->reserved_size;
  if (private_handle_t::validate(handle) == 0 && handle->base_metadata) {
    munmap(reinterpret_cast<void *>(handle->base_metadata),
           GetMetaDataSize(reserved_region_size, handle->custom_content_md_reserved_size));"""

new1 = """void UnmapAndReset(private_handle_t *handle) {
  // MFIX_METADATA_V2: reserved_size / custom_content_md_reserved_size only exist
  // when METADATA_V2 is enabled; keep 0 otherwise (matches GetMetaDataSize()).
  uint64_t reserved_region_size = 0;
  uint64_t custom_content_md_region_size = 0;
#ifdef METADATA_V2
  reserved_region_size = handle->reserved_size;
  custom_content_md_region_size = handle->custom_content_md_reserved_size;
#endif
  if (private_handle_t::validate(handle) == 0 && handle->base_metadata) {
    munmap(reinterpret_cast<void *>(handle->base_metadata),
           GetMetaDataSize(reserved_region_size, custom_content_md_region_size));"""

old2 = """    uint64_t reserved_region_size = handle->reserved_size;
    uint64_t size = GetMetaDataSize(reserved_region_size, handle->custom_content_md_reserved_size);"""

new2 = """    uint64_t reserved_region_size = 0;
    uint64_t custom_content_md_region_size = 0;
#ifdef METADATA_V2
    reserved_region_size = handle->reserved_size;
    custom_content_md_region_size = handle->custom_content_md_reserved_size;
#endif
    uint64_t size = GetMetaDataSize(reserved_region_size, custom_content_md_region_size);"""

if old1 not in s or old2 not in s:
    sys.exit('pattern not found (file changed?)')

s = s.replace(old1, new1, 1).replace(old2, new2, 1)
open(p, 'w').write(s)
print('patched gr_utils.cpp')
