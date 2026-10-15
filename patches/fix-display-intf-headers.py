import os, re, sys

ROOT = '/home/builder/evox/hardware/qcom-caf/sm8450-6.6/display/hal'
TARGETS = ['libqdutils', 'gpu_tonemapper', 'composer', 'composer_test_service']

for name in TARGETS:
    bp = os.path.join(ROOT, name, 'Android.bp')
    if not os.path.isfile(bp):
        print('skip (no bp):', name)
        continue
    s = open(bp).read()
    if 'MFIX_INTF_HEADERS' in s or ('display_intf_headers' in s and 'display_headers' in s):
        print('already ok:', name)
        continue
    add = []
    if 'display_headers' not in s:
        add.append('display_headers')
    if 'display_intf_headers' not in s:
        add.append('display_intf_headers')
    if not add:
        print('nothing to add:', name)
        continue
    entry = ''.join(['        "%s",\n' % x for x in add])

    m = re.search(r'(\n(\s*)header_libs:\s*\[\n)', s)
    if m:
        s = s[:m.end(1)] + entry + s[m.end(1):]
    else:
        m2 = re.search(r'\{\n', s)
        if not m2:
            print('cannot patch:', name)
            continue
        block = ('    // MFIX_INTF_HEADERS: 源码用到 display_intf_headers / display_headers 导出的头文件\n'
                 '    header_libs: [\n' + entry + '    ],\n')
        s = s[:m2.end()] + block + s[m2.end():]
    open(bp, 'w').write(s)
    print('patched:', name, '->', add)
