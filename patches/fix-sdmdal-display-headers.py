import sys

p = '/home/builder/evox/hardware/qcom-caf/sm8450-6.6/display/hal/sdm/libs/dal/Android.bp'
s = open(p).read()

if 'MFIX_DISPLAY_HEADERS' in s:
    print('already patched')
    sys.exit(0)

old = '    header_libs: [\n        "qti_display_kernel_headers",\n    ],'
new = ('    // MFIX_DISPLAY_HEADERS: 源码用到 <utils/utils.h> 与 <drm_lib_loader.h>，\n'
       '    // 这两个路径由 display_headers 导出（同级模块都声明了，只有这里漏了）\n'
       '    header_libs: [\n'
       '        "display_headers",\n'
       '        "qti_display_kernel_headers",\n'
       '    ],')

if old not in s:
    sys.exit('pattern not found')

s = s.replace(old, new, 1)
open(p, 'w').write(s)
print('patched libsdmdal Android.bp')
