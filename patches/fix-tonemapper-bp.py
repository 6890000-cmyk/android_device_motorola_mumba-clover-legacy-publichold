import sys

p = '/home/builder/evox/hardware/qcom-caf/sm8450-6.6/display/hal/gpu_tonemapper/Android.bp'
s = open(p).read()

bad = ('    // MFIX_INTF_HEADERS: 源码用到 display_intf_headers / display_headers 导出的头文件\n'
       '    header_libs: [\n'
       '        "display_intf_headers",\n'
       '    ],\n')
if bad not in s:
    sys.exit('inserted block not found')
s = s.replace(bad, '', 1)

old = '    header_libs: ["display_headers"],'
new = ('    // MFIX_INTF_HEADERS: 源码用到 display_intf_headers 导出的头文件\n'
       '    header_libs: [\n'
       '        "display_headers",\n'
       '        "display_intf_headers",\n'
       '    ],')
if old not in s:
    sys.exit('existing header_libs not found')
s = s.replace(old, new, 1)

open(p, 'w').write(s)
print('gpu_tonemapper 修正完成')
