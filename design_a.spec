# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['src/design_a.py'],
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
    name='ClaudeTrackerSpark',
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
    name='ClaudeTrackerSpark',
)

app = BUNDLE(
    coll,
    name='ClaudeTrackerSpark.app',
    icon=None,
    bundle_identifier='com.claudetracker.spark',
    info_plist={
        'LSUIElement': True,
        'CFBundleName': 'ClaudeTrackerSpark',
        'CFBundleDisplayName': 'Claude Tracker — Spark',
        'CFBundleVersion': '1.0.0',
        'CFBundleShortVersionString': '1.0.0',
    },
)
