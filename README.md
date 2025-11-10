# Comfy Slop Dev Helper 

PowerShell/Batch utilities for Windows to help during non-agentic LLM-assisted node development (i.e. lmarena.ai, Google AI studio, Claude or ChatGPT free tiers). 

Specifically, these scripts:

- Print an ASCII file tree of a working directory (files first, then folders)
- Save that tree to <foldername>.txt wrapped in Markdown triple backticks
- Interactively collect and export the contents of selected files into a single text file with fenced code blocks (to be sent to the LLM)
- Exclude noisy directories like __pycache__ and .git


Ideal for ComfyUI custom-node work where you want a quick tree snapshot plus a neatly bundled text file of selected sources for sharing or debugging.
Contents

    CSDH_script.ps1 — main PowerShell script (the heavy lifting)
    CSDH.bat — optional launcher that handles spaces/parentheses in paths

You can name these files anything. The .bat only needs to point to the .ps1 by name.

## Requirements

    Windows 10/11
    Windows PowerShell 5.1 or PowerShell 7+
    Permissions to run local scripts (the .bat launches PowerShell with ExecutionPolicy Bypass for convenience)

## Installation

Copy the two files into the root of your custom node (or any folder you want to capture):
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
    Enter a list of filenames or patterns to export, separated by commas/semicolons/pipes/spaces.

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

What you get:

A tree file named after the folder (e.g., comfyui-libcom-image-composition.txt) containing:
    
The ASCII tree (wrapped in triple backticks so it’s Markdown-ready)
    
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

## Non‑interactive options

The script supports optional parameters:

- RootDir <path>: pre-select the root directory (skip the root prompt)
- OutputDump <file>: pre-set the output filename for the combined export

Example via .bat:

bat

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CSDH_script.ps1" -RootDir "C:\path\to\repo" -OutputDump "selected_files.md"

Note: File selection is interactive by default. If you want a fully non‑interactive mode (e.g., pass a “-Select” list), open an issue or PR and we’ll add it.


Security

The .bat launches PowerShell with -ExecutionPolicy Bypass only for this run, to avoid policy friction on developer machines. If you prefer, run the .ps1 directly in a console session where you’ve set a suitable execution policy.

Example session:

```

CSDH.bat

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
- Your Windows version
- PowerShell version ($PSVersionTable.PSVersion)
- Repro steps and any console output

## License

MIT
