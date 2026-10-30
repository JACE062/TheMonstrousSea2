from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd(); audit=root/'.dart_tool/wait-reload-audit'
addition="    ship!.currentEvasion = min(90, ship!.currentEvasion + 10);\n    events.add(CombatEffectsChanged.capture(ship!));\n"
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
        for p in conf['packages']:
            if p['name'] in ['monstrous_core','monstrous_sim']:
                p['rootUri']=(base/p['name']).as_uri()+'/'
        (dest/'.dart_tool/package_config.json').write_text(json.dumps(conf,indent=2))
    if version=='before':
        target=base/'monstrous_core/lib/src/session/game_session.dart'
        txt=target.read_text()
        start=txt.index('  List<GameEvent> _handleBraceForImpact()')
        idx=txt.index('    events.add(NarrationEvent(',start)
        target.write_text(txt[:idx]+addition+txt[idx:])
    manifest[version]={p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in base.rglob('*') if p.is_file() and '.dart_tool' not in p.parts[len(base.parts):]}
before=audit/'before/monstrous_core/lib/src/session/game_session.dart'; after=audit/'after/monstrous_core/lib/src/session/game_session.dart'
b=before.read_text(); a=after.read_text()
assert b.replace(addition,'',1)==a
changed=[k for k,v in manifest['after'].items() if manifest['before'][k]!=v]
assert changed==['monstrous_core/lib/src/session/game_session.dart'], changed
(audit/'source-diff.patch').write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='after',tofile='before')))
(audit/'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print('Verified only source difference is the two restored Brace statements; '+str(len(manifest['after']))+' source/pubspec files per version.')
