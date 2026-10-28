# mdcat.yazi

[简体中文](README.md) | **English**

Preview Markdown in [yazi](https://github.com/sxyazi/yazi) with [mdcat](https://github.com/swsnr/mdcat) — colour, zero config, no network access.

> The upstream [GrzegorzKozub/mdcat.yazi](https://github.com/GrzegorzKozub/mdcat.yazi) targets an older yazi Lua API and config schema, so it no longer loads on current yazi.
> This repository is a **rewrite for modern yazi** (not a patched fork), and adds the error handling the upstream version lacks.

## What you get

Put the cursor on any `.md` file and the preview pane renders headings, bold, italic, inline code, blockquotes, lists, tables, fenced code blocks and task lists.

Plain text works too — `--ansi` is passed by default, and the colours are rendered by yazi's own ANSI parser.

## Requirements

| Requirement | Notes |
| --- | --- |
| [yazi](https://github.com/sxyazi/yazi) | Uses the current Lua API (`Command:arg` / `ya.emit` / `ya.preview_widget`). Tested on **26.9.1**; older yazi is not supported |
| [mdcat](https://github.com/swsnr/mdcat) | Tested on **2.19.0** (needs `--columns` / `--ansi` / `--local`) |

Installing mdcat:

```bash
# macOS
brew install mdcat

# or any platform, via cargo
cargo install mdcat
```

## Installation

```bash
ya pkg add isfk/mdcat
```

> `ya pkg add` clones `github.com/<owner>/<name>.yazi`, which is why the repository name must keep the `.yazi` suffix.

Then register the previewer in `~/.config/yazi/yazi.toml`:

```toml
[plugin]
prepend_previewers = [
  { url = "*.md", run = "mdcat" },
]
```

Restart yazi to pick it up.

> Note the field is `url`, not the old `name`. Current yazi only accepts `url` / `mime` / `run` / `sync` in a previewer rule.

### Manual installation

```bash
git clone https://github.com/isfk/mdcat.yazi ~/.config/yazi/plugins/mdcat.yazi
```

## Usage

**Fully automatic — no keybinding to remember for previewing.** Park the cursor on a `.md` file and it renders.

| Key | Action |
| --- | --- |
| `Shift + J` | Scroll the preview down |
| `Shift + K` | Scroll the preview up |

> Lowercase `j` / `k` move the cursor in the file list — don't mix them up. The scroll keys are **uppercase**, i.e. hold Shift.

One press scrolls about half a screen by default. If you prefer the one-line-at-a-time rhythm of yazi's built-in `code` previewer, set `OPT.scroll` to `'line'` (see below).

## Configuration

There is no external config file — edit `OPT` at the top of `main.lua`:

```lua
local OPT = {
	bin = 'mdcat', -- executable name or absolute path
	color = true, -- false → plain text, no --ansi
	local_only = true, -- false → allow fetching remote images (needs network)
	extra = {}, -- extra arguments passed to mdcat
	scroll = 'page', -- 'page' → about half a screen; 'line' → one line at a time
}
```

For example, to switch the colour theme:

```lua
extra = { '--theme', 'dracula' },
```

Available themes are listed in `mdcat --help` (`dark` / `light` / `catppuccin-mocha` / `gruvbox-dark` / `dracula` / `nord` …).

## Previewing more extensions

Each `url` matches a single glob, so just add more entries:

```toml
prepend_previewers = [
  { url = "*.md", run = "mdcat" },
  { url = "*.markdown", run = "mdcat" },
  { url = "*.mdx", run = "mdcat" },
]
```

## Differences from upstream

| | Upstream | This repository |
| --- | --- | --- |
| Previewer rule field | `name` (removed) | `url` |
| Passing arguments | `Command:args{}` (removed) | `Command:arg{}` |
| Requesting a redraw | `ya.manager_emit` (removed) | `ya.emit` |
| Rendering widgets | `ya.preview_widgets` (removed) | `ya.preview_widget` |
| `upper_bound` | `''` (wrong type) | `true` |
| mdcat not installed | Blank preview pane | Explicit error message |
| Empty file | Blank preview pane | Shows `(空文件)` ("empty file") |
| mdcat failure | Silent | Shows stderr |
| Reading output | Accumulates a string line by line | Streams, calls `start_kill` once a screenful is buffered |
| Scrolling past the end | Can go blank | Clamps back to the last page |
| Scroll step | One line | Half a screen by default, `OPT.scroll` switches to one line |

## Known limitations

- Scrolling works on **wrapped** lines, so the total line count changes when the pane width changes.
- `local_only = true` by default, so remote images referenced from Markdown are never downloaded.
- `mdcat` must be on yazi's `PATH`. If you launch yazi from a GUI (Finder / Dock) and `mdcat` is not found, set `OPT.bin` to an absolute path, e.g. `'/opt/homebrew/bin/mdcat'`.

## License

[MIT](LICENSE)
