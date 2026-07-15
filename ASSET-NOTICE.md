# Clawd artwork notice

The generated GIF files in this app use the canonical 12 x 8 sprite and
outline helpers from the local `ClawdMoji` project.

ClawdMoji's render code is MIT licensed, copyright (c) 2026 afspies. Its scope
note states that the license covers the code and build machinery only. The
Clawd character and Anthropic spark mark belong to Anthropic, PBC; ClawdMoji is
an unofficial fan project and grants no rights to the character or mark.

Upstream project and license: <https://github.com/afspies/ClawdMoji>.

# Console font notice

The `package/font/clawd_console.ttf` asset is a static, ASCII-subsetted
derivative of Cascadia Mono. Cascadia Code is copyright (c) 2019-present
Microsoft Corporation and licensed under the SIL Open Font License 1.1, with
Reserved Font Name Cascadia Code. The derivative asset uses the name `Clawd
Console`; the full font license is included at `package/font/CASCADIA-OFL.txt`.

Upstream project: <https://github.com/microsoft/cascadia-code>.

# Native text compositor notice

`package/modules/aida_font.so` is the RGB565 TrueType compositor shared with
AIDA Monitor. Its self-contained source and ESP-IDF build configuration are
included under `native/aida_font`; no external HoloCubic app repository is
required to reproduce the module. It embeds Sean Barrett's `stb_truetype` and
`stb_image`, which are available under the MIT license or public domain
dedication.

# Chinese TrueType font notice

The `package/font/aida_noto_sans_sc.ttf` asset is the bundled CJK-safe
fallback font shared with AIDA Monitor. It is based on Adobe Source Han Sans /
Noto Sans CJK and licensed under the SIL Open Font License 1.1. The full font
license is included at `package/font/AIDA-NOTO-OFL.txt`.
