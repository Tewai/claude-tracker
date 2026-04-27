# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['src/design_b.py'],
    pathex=['src'],
    binaries=[],
    datas=[],
    hiddenimports=['rumps', 'objc', 'Foundation', 'AppKit'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='ClaudeTrackerAura',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='ClaudeTrackerAura',
)

app = BUNDLE(
    coll,
    name='ClaudeTrackerAura.app',
    icon=None,
    bundle_identifier='com.claudetracker.aura',
    info_plist={
        'LSUIElement': True,
        'CFBundleName': 'ClaudeTrackerAura',
        'CFBundleDisplayName': 'Claude Tracker — Aura',
        'CFBundleVersion': '1.0.0',
        'CFBundleShortVersionString': '1.0.0',
    },
)
