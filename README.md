# shiglet

Turn text into ASCII art, figlet-style.

The ASCII arts are inspired by [OpenCode font](https://opencode.ai/font/).

```bash
# Usage:
.\shiglet.ps1 [-Gap <n>] [-Width <n>] <text ...>

    -Gap <n>      # Spaces between character (default 1).
    -Width <n>    # Wrap banners at this column; 0 disables wrapping (default 0).
    -List         # List the characters that have glyph files.

# Supported characters:
# _ - , ! ? . 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z

# Examples:

.\shiglet.ps1 hello
# ▄         ▄ ▄
# █▀▀▄ █▀▀█ █ █ █▀▀█
# █  █ █▀▀▀ █ █ █  █
# ▀  ▀ ▀▀▀▀ ▀ ▀ ▀▀▀▀

.\shiglet.ps1 Hello, World 2026
# ▄         ▄ ▄                           ▄    ▄
# █▀▀▄ █▀▀█ █ █ █▀▀█      █   █ █▀▀█ ▄▀▀▀ █ █▀▀█    ▀▀▀█ █▀▀█ ▀▀▀█ █▀▀▀
# █  █ █▀▀▀ █ █ █  █      █ ▄ █ █  █ █    █ █  █    █▀▀▀ █  █ █▀▀▀ █▀▀█
# ▀  ▀ ▀▀▀▀ ▀ ▀ ▀▀▀▀ █    ▀▀ ▀▀ ▀▀▀▀ ▀    ▀ ▀▀▀▀    ▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀

.\shiglet.ps1 Wait... what?
#                                  ▄              ▄▄▄▄
# █   █ ▀▀▀▄ █ █▄▄           █   █ █▀▀▄ ▀▀▀▄ █▄▄  ▀  █
# █ ▄ █ █▀▀█ █ █  ▄          █ ▄ █ █  █ █▀▀█ █  ▄  ▀▀
# ▀▀ ▀▀ ▀▀▀▀ ▀ ▀▀▀▀ ▀ ▀ ▀    ▀▀ ▀▀ ▀  ▀ ▀▀▀▀ ▀▀▀▀  ▀

.\shiglet.ps1 -Width 60 the quick brown fox
# Wrapping characters at 60 columns.
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
