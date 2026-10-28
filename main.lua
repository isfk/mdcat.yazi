--- mdcat.yazi — 用 `mdcat` 渲染 Markdown 预览（自维护版，适配 yazi 26.x）
--- 依赖：mdcat (https://github.com/swsnr/mdcat)

local M = {}

--- 可调参数，改这里就行
local OPT = {
	bin = 'mdcat', -- mdcat 可执行文件名或绝对路径
	color = true, -- true → 传 --ansi 输出彩色（由 yazi 的 ANSI 解析器渲染）
	local_only = true, -- true → 传 --local，不加载远程图片，预览不联网、更快
	extra = {}, -- 追加给 mdcat 的其它参数，例如 { '--theme', 'dracula' }
	scroll = 'page', -- 'page' → J/K 一次约半屏；'line' → 一次一行（与内置 code 预览器一致）
}

--- 遇到错误时给用户看的提示
local function complain(job, text)
	return ya.preview_widget(
		job,
		ui.Text(text):area(job.area):wrap(ui.Wrap.YES)
	)
end

function M:peek(job)
	local area = job.area
	local skip, limit = job.skip, area.h

	-- 组命令：先设宽度，mdcat 自己负责折行，行号才好数
	local cmd = Command(OPT.bin):arg({ '--columns', tostring(area.w) })
	if OPT.color then
		cmd:arg('--ansi')
	end
	if OPT.local_only then
		cmd:arg('--local')
	end
	cmd:arg(OPT.extra):arg(tostring(job.file.path))
	cmd:stdout(Command.PIPED):stderr(Command.PIPED)

	local child, err = cmd:spawn()
	if not child then
		return complain(job, string.format('无法启动 `%s`：%s\n\n请先安装 mdcat。', OPT.bin, tostring(err)))
	end

	-- 流式读取：只收 [skip, skip+limit) 窗口内的行，够了就掐掉进程
	local lines, n, errbuf = {}, 0, {}
	while true do
		local line, event = child:read_line()
		if event == 0 then
			n = n + 1
			if n > skip and #lines < limit then
				lines[#lines + 1] = line
			end
			if n >= skip + limit then
				break
			end
		elseif event == 1 then
			errbuf[#errbuf + 1] = line
		else
			break -- EOF
		end
	end
	child:start_kill()

	local text = table.concat(lines)
	local errmsg = table.concat(errbuf, '')

	-- mdcat 对空文件也会吐两个换行，所以按“内容全是空白”来判定，而不是看行数
	if skip == 0 and text:match('^%s*$') then
		return complain(job, errmsg ~= '' and errmsg or '(空文件)')
	end

	-- 越界了就回退到最后一页，别让预览窗空白
	if skip > 0 and n < skip + limit then
		return ya.emit('peek', {
			math.max(0, n - limit),
			only_if = job.file.url,
			upper_bound = true,
		})
	end

	-- parse 而不是 Text：这样 --ansi 的颜色才能被吃掉，纯文本也照样正常
	ya.preview_widget(job, {
		ui.Text.parse(text):area(area):wrap(rt.preview.wrap),
	})
end

function M:seek(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end

	local step
	if OPT.scroll == 'page' then
		-- 半屏滚动：job.units 通常是 ±5，换算成约 area.h/2 行
		local mag = math.max(1, math.floor(math.abs(job.units) * job.area.h / 10))
		step = job.units < 0 and -mag or mag
	else
		-- 逐行滚动：与内置 code 预览器一致
		step = ya.clamp(-1, job.units, 1)
	end

	ya.emit('peek', {
		math.max(0, cx.active.preview.skip + step),
		only_if = job.file.url,
	})
end

return M
