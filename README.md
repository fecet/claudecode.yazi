# claudecode.yazi

A Yazi plugin that copies selected files as `@relative_path` format for Claude projects.

## Features

- Automatically detects project root by looking for `.git` or `.claude` directories
- Converts absolute file paths to relative paths from project root
- Formats paths with `@` prefix for Claude AI assistant
- Supports multiple file selection
- Cross-platform clipboard support (Linux X11/Wayland, macOS, Windows)

## Dependencies

### Linux
- **X11**: `xclip`
- **Wayland**: `wl-clipboard` (preferred) or `xclip` (fallback)

### macOS
- `pbcopy` (built-in)

### Windows
- PowerShell (built-in)

## Installation

Copy this plugin to your Yazi plugins directory:

```bash
# Clone or copy the plugin
cp -r claudecode.yazi ~/.config/yazi/plugins/
```

## Configuration

Add the following keymap to your `~/.config/yazi/keymap.toml`:

```toml
[[manager.prepend_keymap]]
on   = [ "c", "c" ]
run  = "plugin claudecode"
desc = "Copy files as Claude paths"
```

Or use a single key:

```toml
[[manager.prepend_keymap]]
on   = "<C-c>"
run  = "plugin claudecode"
desc = "Copy files as Claude paths"
```

## Usage

1. Navigate to a directory within a project that contains `.git` or `.claude` directory
2. Select one or more files (or just hover over a file)
3. Press your configured key combination (e.g., `c` + `c`)
4. The plugin will copy the files as `@relative_path` format to your clipboard

## Example

If you have a project structure like:
```
/home/user/myproject/
├── .git/
├── src/
│   ├── main.py
│   └── utils.py
└── README.md
```

And you select `src/main.py` and `src/utils.py`, the plugin will copy:
```
@src/main.py @src/utils.py
```

## How it works

1. **Project Detection**: The plugin searches upward from the selected file's directory to find a `.git` or `.claude` directory, which indicates the project root. It intelligently handles both files and directories.

2. **Path Conversion**: It converts absolute file paths to relative paths from the detected project root. Special handling for files in the project root directory ensures correct path generation.

3. **Formatting**: Each relative path is prefixed with `@` to match Claude's expected format.

4. **Clipboard**: The formatted paths are copied to the system clipboard using the appropriate command for your platform.

## Recent Improvements

- **Fixed project root detection**: Now correctly handles files and directories at any level
- **Improved path normalization**: Better handling of trailing slashes and edge cases
- **Enhanced relative path calculation**: Correctly processes files in the project root directory

## Error Handling

- If no files are selected or hovered, shows a warning
- If no project root is found (no `.git` or `.claude` directory), shows a warning
- If clipboard copy fails, shows an error message
- Success message shows the number of files copied and the result

## License

This plugin is MIT-licensed.
