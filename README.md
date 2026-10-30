# shiglet

Turn text into ASCII art, figlet-style.

The ASCII arts are inspired by [OpenCode font](https://opencode.ai/font/).

```bash
# Usage:

.\shiglet.ps1 [-Gap <n>] [-Width <n>] <text ...>

    -Gap <n>      # Spaces between character (default 1).
    -Width <n>    # Wrap banners at this column; 0 disables wrapping (default 0).
    -List         # List the characters that have glyph files.

# Examples:

.\shiglet.ps1 hello
# Renders
# ▄         ▄ ▄
# █▀▀▄ █▀▀█ █ █ █▀▀█
# █  █ █▀▀▀ █ █ █  █
# ▀  ▀ ▀▀▀▀ ▀ ▀ ▀▀▀▀

.\shiglet.ps1 "Hello, World!" 2026
# Comma and exclamation mark are skipped since the font only supports letters and digits.
# ▄         ▄ ▄                         ▄    ▄
# █▀▀▄ █▀▀█ █ █ █▀▀█    █   █ █▀▀█ ▄▀▀▀ █ █▀▀█    ▀▀▀█ █▀▀█ ▀▀▀█ █▀▀▀
# █  █ █▀▀▀ █ █ █  █    █ ▄ █ █  █ █    █ █  █    █▀▀▀ █  █ █▀▀▀ █▀▀█
# ▀  ▀ ▀▀▀▀ ▀ ▀ ▀▀▀▀    ▀▀ ▀▀ ▀▀▀▀ ▀    ▀ ▀▀▀▀    ▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀

.\shiglet.ps1 -Width 60 the quick brown fox
# Renders the pangram with no space between glyphs, wrapping at 60 columns.
#      ▄                             ▄
# █▄▄  █▀▀▄ █▀▀█    █▀▀█ █  █ █ █▀▀▀ █ ▄▀
# █  ▄ █  █ █▀▀▀    █  █ █  █ █ █    █▀▄
# ▀▀▀▀ ▀  ▀ ▀▀▀▀    ▀▀▀█ ▀▀▀▀ ▀ ▀▀▀▀ ▀  ▀
# 
# ▄
# █▀▀█ ▄▀▀▀ █▀▀█ █   █ █▀▀▄    ▄▀▀▀ █▀▀█ █  █
# █  █ █    █  █ █ ▄ █ █  █    █▀▀▀ █  █ ▄▀▀▄
# ▀▀▀▀ ▀    ▀▀▀▀ ▀▀ ▀▀ ▀  ▀    ▀    ▀▀▀▀ ▀  ▀
```
