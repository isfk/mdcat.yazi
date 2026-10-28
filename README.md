# mdcat.yazi

在 [yazi](https://github.com/sxyazi/yazi) 里用 [mdcat](https://github.com/swsnr/mdcat) 预览 Markdown —— 彩色、零配置、不联网。

> 上游 [GrzegorzKozub/mdcat.yazi](https://github.com/GrzegorzKozub/mdcat.yazi) 的 Lua API 与配置字段已不适用于新版 yazi。
> 本仓库是**针对新版 yazi 重写**的版本（不是 fork 后打补丁），并补上了上游缺失的错误处理。

## 效果

把光标移到任意 `.md` 文件上，预览窗会直接渲染出标题、粗体、斜体、行内代码、引用、列表、表格、代码块、任务列表。

纯文本也可以，因为默认带着 `--ansi`，颜色由 yazi 自己的 ANSI 解析器渲染。

## 依赖

| 依赖 | 要求 |
| --- | --- |
| [yazi](https://github.com/sxyazi/yazi) | 使用新版 Lua API（`Command:arg` / `ya.emit` / `ya.preview_widget`），已在 **26.9.1** 实测；旧版 yazi 不兼容 |
| [mdcat](https://github.com/swsnr/mdcat) | 已在 **2.19.0** 实测（需要 `--columns` / `--ansi` / `--local`） |

装 mdcat：

```bash
# macOS
brew install mdcat

# 或者任意平台用 cargo
cargo install mdcat
```

## 安装

```bash
ya pkg add isfk/mdcat
```

> `ya pkg add` 会去 clone `github.com/<owner>/<name>.yazi`，所以仓库名必须带 `.yazi` 后缀。

然后在 `~/.config/yazi/yazi.toml` 里注册预览器：

```toml
[plugin]
prepend_previewers = [
  { url = "*.md", run = "mdcat" },
]
```

重启 yazi 生效。

> 注意字段是 `url`，不是老版本的 `name`。新版 yazi 的预览器规则只认 `url` / `mime` / `run` / `sync`。

### 手动安装

```bash
git clone https://github.com/isfk/mdcat.yazi ~/.config/yazi/plugins/mdcat.yazi
```

## 用法

**全自动，不需要任何快捷键。** 光标停在 `.md` 文件上就会渲染。

| 按键 | 作用 |
| --- | --- |
| `J` | 向下滚动预览 |
| `K` | 向上滚动预览 |

滚动节奏与 yazi 内置的 `code` 预览器一致（一次一行）。

## 配置

插件本身没有外部配置文件，改 `main.lua` 顶部的 `OPT` 即可：

```lua
local OPT = {
	bin = 'mdcat', -- 可执行文件名或绝对路径
	color = true, -- false → 纯文本，不传 --ansi
	local_only = true, -- false → 允许加载远程图片（会联网）
	extra = {}, -- 追加给 mdcat 的参数
}
```

比如换配色主题：

```lua
extra = { '--theme', 'dracula' },
```

可选主题见 `mdcat --help`（`dark` / `light` / `catppuccin-mocha` / `gruvbox-dark` / `dracula` / `nord` …）。

## 想预览更多扩展名

一个 `url` 只匹配一种 glob，多加几行就行：

```toml
prepend_previewers = [
  { url = "*.md", run = "mdcat" },
  { url = "*.markdown", run = "mdcat" },
  { url = "*.mdx", run = "mdcat" },
]
```

## 与上游的差异

| | 上游 | 本仓库 |
| --- | --- | --- |
| 预览器配置字段 | `name`（已移除） | `url` |
| 传参 | `Command:args{}`（已移除） | `Command:arg{}` |
| 触发重绘 | `ya.manager_emit`（已移除） | `ya.emit` |
| 输出组件 | `ya.preview_widgets`（已移除） | `ya.preview_widget` |
| `upper_bound` | `''`（类型错误） | `true` |
| mdcat 未安装 | 预览窗空白 | 显示明确错误提示 |
| 空文件 | 预览窗空白 | 显示 `(空文件)` |
| mdcat 报错 | 静默 | 显示 stderr |
| 读取方式 | 逐行累积字符串 | 流式，收满一屏即 `start_kill`，大文件不卡 |
| 越界滚动 | 可能空白 | 回退到最后一页 |

## 已知限制

- 预览按**折行后的行**滚动，因此窗口宽度变化时总行数会变。
- 默认 `local_only = true`，Markdown 里的远程图片不会被下载。
- 需要 `mdcat` 在 yazi 的 `PATH` 里。若从图形界面（Finder / Dock）启动 yazi 而找不到 `mdcat`，把 `OPT.bin` 改成绝对路径，例如 `'/opt/homebrew/bin/mdcat'`。

## 许可

[MIT](LICENSE)
