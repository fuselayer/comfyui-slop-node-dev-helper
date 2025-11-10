# Comfy Slop Dev Helper 

PowerShell/Batch utilities for Windows that:

    Print an ASCII file tree of a repo (files first, then folders)
    Save that tree to <foldername>.txt wrapped in Markdown triple backticks
    Interactively collect and export the contents of selected files into a single text file with fenced code blocks
    Exclude noisy directories like __pycache__ and .git
    Show a persistent banner “Comfy Slop Dev Helper” in the console

Ideal for ComfyUI custom-node work where you want a quick tree snapshot plus a neatly bundled text file of selected sources for sharing or debugging.
Contents

    CSDH_script.ps1 — main PowerShell script (the heavy lifting)
    CSDH.bat — optional launcher that handles spaces/parentheses in paths

You can name these files anything. The .bat only needs to point to the .ps1 by name.
Requirements

    Windows 10/11
    Windows PowerShell 5.1 or PowerShell 7+
    Permissions to run local scripts (the .bat launches PowerShell with ExecutionPolicy Bypass for convenience)

## Installation

    Copy the two files into the root of your repo (or any folder you want to capture):
        CSDH_script.ps1
        CSDH.bat
        
## Quick Start

    Double‑click CSDH.bat, or run it in a terminal from your repo folder:

```

    CSDH.bat
```

    When prompted:
        Press Enter to use the current folder as root, or paste a path.
        Review the tree in the console (it’s also saved to <foldername>.txt).
        Enter file names or patterns to export, separated by commas/semicolons/pipes/spaces.

Examples you can type at the prompt:

    By base names:

```

issam, base, nodes

```

By exact file names:

```

nodes.py; requirements.txt

```
With wildcards/paths:

```
    model\*.py | *.md

```

When multiple files match a name (e.g., several base.py), CSDH shows a numbered list and lets you pick specific items, ranges, All, or Skip.
What you get

    A tree file named after the folder (e.g., comfyui-libcom-image-composition.txt) containing:
        The ASCII tree
        Wrapped in triple backticks so it’s Markdown-ready

    A combined export file (default: selected_files_YYYYMMDD_HHMMSS.txt or whatever name you choose) where each selected file is written as:

```
relative\path\to\file.ext
```

```

...file contents...

```
Binary files are detected and skipped with a note:

```

    [[binary or non-text file skipped]]
```

Features and defaults

    Exclusions:
        The tree lists .git and __pycache__ but does not expand them.
        File selection/search excludes anything under .git and __pycache__.
    Tree formatting:
        Files appear before folders at each level.
        ASCII branches (+---, \---) match the familiar Windows tree style.
    Disambiguation:
        If a token matches multiple files, you’ll be prompted to choose by number, pick ranges (e.g., 2-5), A for all, or S to skip.
    Banner:
        The console window title is set to “Comfy Slop Dev Helper”.
        A banner is printed at start and before the file-selection prompt so it’s visible during interaction.

Non‑interactive options

The script supports optional parameters:

    -RootDir <path>: pre-select the root directory (skip the root prompt)
    -OutputDump <file>: pre-set the output filename for the combined export

Example via .bat:

bat

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CSDH_script.ps1" -RootDir "C:\path\to\repo" -OutputDump "selected_files.md"

Note: File selection is interactive by default. If you want a fully non‑interactive mode (e.g., pass a “-Select” list), open an issue or PR and we’ll add it.
Customization

    Change the banner text:
        In Show-Banner, edit the default: '$Text = "Comfy Slop Dev Helper"'.
    Use ASCII banner only:
        Replace Show-Banner calls with Show-Banner -NoClear and set the function to ASCII internally, or pass -Ascii.
    Hide .git from the tree entirely:
        The script already avoids expanding .git. If you’d prefer to also hide the .git line itself, add a continue when the folder name matches .git.

Troubleshooting

    Paths with spaces or parentheses:
        Use the provided CSDH.bat. It avoids CMD parsing issues with () in paths.

    Garbled Unicode (e.g., ‘â”’ characters instead of box lines):
        Save the script as UTF‑8.
        Optionally run chcp 65001 in that console session.
        Or use the ASCII banner.

    “The property ‘Count’ cannot be found…”:
        PowerShell 5.1 sometimes returns a single object instead of an array. The script forces arrays where needed; if you tweak it, wrap results with @(...) before using .Count.

    “Too many )’s” in a regex:
        The script uses a simple, PS‑5.1‑friendly pattern to exclude .git and __pycache__. If you customize it, keep parentheses balanced and test with -match.

    “AddRange requires IEnumerable[string]”:
        On PS 5.1, List[string].AddRange() can be picky. The script adds strings line‑by‑line to be bulletproof.

Security

The .bat launches PowerShell with -ExecutionPolicy Bypass only for this run, to avoid policy friction on developer machines. If you prefer, run the .ps1 directly in a console session where you’ve set a suitable execution policy.
Example session

```

CSDH.bat
[ Banner prints, title set to “Comfy Slop Dev Helper” ]

Enter root directory (Press Enter to use current: C:\repos\my-node):
Generating ASCII tree for: C:\repos\my-node
C:.
|   nodes.py
|   readme.md
+---model
|       base.py
|       issam.py
+---utils
        model_registry.py

Tree saved to: C:\repos\my-node\my-node.txt


Enter file names or patterns (comma/semicolon/pipe/space-separated), or press Enter to skip:
issam, base, model_registry
[ …disambiguation if duplicates… ]
Wrote selected contents to: C:\repos\my-node\selected_files_20251110_193421.txt
```


## Contributing

    Issues and PRs welcome. Please include:
        Your Windows version
        PowerShell version ($PSVersionTable.PSVersion)
        Repro steps and any console output

## License

MIT
