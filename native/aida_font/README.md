# AIDA font module

This directory is the self-contained ESP-IDF source for the TrueType/RGB565
Lua module shipped at `package/modules/aida_font.so`. It is kept outside the
device package so the scheduled deployment only copies runtime files to the SD
card.

Build requirements:

- ESP-IDF 5.5.x
- ESP32-S3 target
- network access for the ESP Component Manager to resolve
  `espressif/elf_loader` 1.3.1

Build from an ESP-IDF shell:

```powershell
idf.py set-target esp32s3
idf.py build
```

The checked-in `dependencies.lock` and `sdkconfig.defaults` pin the target and
shared-object loader configuration used by the packaged module. After a module
change, copy the generated `aida_font.so` to `package/modules/aida_font.so` and
repeat the physical-device package test before publishing.
