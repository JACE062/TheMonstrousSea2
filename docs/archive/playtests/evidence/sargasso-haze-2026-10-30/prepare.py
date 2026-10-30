from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd(); audit=root/'.dart_tool/sargasso-haze-audit'
new='      currentMonster!.obscuredAcMod = max(currentMonster!.obscuredAcMod, 10);\r\n'
old=''
manifest={}
for version in ['before','after']:
    base=audit/version
    for package in ['monstrous_core','monstrous_sim']:
        src=root/'packages'/package; dest=base/package
        if dest.exists(): raise RuntimeError('Snapshot already exists: '+str(dest))
        shutil.copytree(src/'lib',dest/'lib')
        shutil.copy2(src/'pubspec.yaml',dest/'pubspec.yaml')
        (dest/'.dart_tool').mkdir()
        conf=json.loads((src/'.dart_tool/package_config.json').read_text())
        for item in conf['packages']:
            if item['name'] in ['monstrous_core','monstrous_sim']:
                item['rootUri']=(base/item['name']).as_uri()+'/'
        (dest/'.dart_tool/package_config.json').write_text(json.dumps(conf,indent=2))
    if version=='before':
        target=base/'monstrous_core/lib/src/session/game_session.dart'
        raw=target.read_bytes(); assert raw.count(new.encode())==1
        target.write_bytes(raw.replace(new.encode(),old.encode(),1))
    manifest[version]={f.relative_to(base).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in base.rglob('*') if f.is_file() and '.dart_tool' not in f.parts[len(base.parts):]}
b=(audit/'before/monstrous_core/lib/src/session/game_session.dart').read_bytes();a=(audit/'after/monstrous_core/lib/src/session/game_session.dart').read_bytes()
assert a.replace(new.encode(),b'',1)==b
changed=[k for k,v in manifest['after'].items() if manifest['before'][k]!=v]
assert changed==['monstrous_core/lib/src/session/game_session.dart'],changed
(audit/'source-diff.patch').write_text(''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile='after',tofile='before')))
(audit/'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print('Verified only source difference is the one Sargasso haze assignment; '+str(len(manifest['after']))+' source/pubspec files per version.')
