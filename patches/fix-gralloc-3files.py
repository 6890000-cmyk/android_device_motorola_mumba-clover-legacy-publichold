import re, sys, glob

base = '/home/builder/evox/hardware/qcom-caf/sm8450-6.6/display'
files = [
    base + '/hal/gralloc/gr_buf_mgr.cpp',
    base + '/core/snapalloc/SnapMetadataManager.cpp',
    base + '/core/snapalloc/SnapAllocCore.cpp',
]

FIELDS = ['reserved_size', 'custom_content_md_reserved_size']
OBJ = r'(?:hnd|handle|snap_hnd|src|dst)'

total = 0
for path in files:
    try:
        s = open(path).read()
    except FileNotFoundError:
        print('skip (missing):', path)
        continue
    if 'MFIX_NORESERVED' in s:
        print('already patched:', path)
        continue
    orig = s
    for f in FIELDS:
        # 1) 赋值语句：整行改成空操作
        s = re.sub(r'^([ \t]*)' + OBJ + r'->' + f + r'\s*=\s*[^;]+;',
                   r'\1/* MFIX_NORESERVED: 头文件无此字段 */ (void)0;', s, flags=re.M)
        # 2) 其余读取引用：替换为 0
        s = re.sub(OBJ + r'->' + f + r'\b', '0ULL /* MFIX_NORESERVED */', s)
    if s != orig:
        open(path, 'w').write(s)
        n = len(re.findall('MFIX_NORESERVED', s))
        total += n
        print('patched:', path, '->', n, 'sites')

print('total sites:', total)
