-- Audio preview: opening an audio file shows its info, a waveform and a spectrogram
-- (images need kitty), and plays it with ffplay in the background.
--
-- In an audio buffer:
--   <Space> play / pause     s stop     0 play from start     r play a range (e.g. 1.2-3.5)
--   h / l  (← / →) seek 2s    H / L seek 10s                   q close
-- Anywhere:
--   <leader>mp  play: this audio buffer, the audio path under the cursor (e.g. in a
--               manifest/CSV), or the file selected in neo-tree
--   <leader>mr  play a range of it       <leader>ms  stop       :AudioPlay [file] [range]
-- In the file picker / neo-tree: <M-a> plays the highlighted file; the picker preview
-- shows the audio info.
local M = {}

M.exts = { "wav", "mp3", "flac", "ogg", "opus", "m4a", "aac", "aiff", "aif", "wma" }
local ext_set = {}
for _, e in ipairs(M.exts) do
  ext_set[e] = true
end

local cache = vim.fn.stdpath("cache") .. "/audio-preview"
local ns = vim.api.nvim_create_namespace("user_audio")
local info_cache = {} ---@type table<string, table>

function M.is_audio(path)
  return path and ext_set[(vim.fn.fnamemodify(path, ":e") or ""):lower()] or false
end

local function fmt_time(t)
  t = math.max(0, t or 0)
  if t >= 60 then
    return string.format("%d:%04.1f", math.floor(t / 60), t % 60)
  end
  return string.format("%.1fs", t)
end

-- "1.2-3.5", "1.2 3.5", "1:02.5-1:10", "1.2" (from), "-3.5" (until)
local function to_seconds(s)
  if not s or s == "" then
    return nil
  end
  local m, sec = s:match("^(%d+):(%d+%.?%d*)$")
  if m then
    return tonumber(m) * 60 + tonumber(sec)
  end
  return tonumber((s:gsub("s$", "")))
end

function M.parse_range(text)
  text = vim.trim(text or "")
  local a, b = text:match("^([%d:.]*s?)%s*[-–,%s]%s*([%d:.]+s?)$")
  if not a then
    a = text
  end
  return to_seconds(a) or 0, to_seconds(b)
end

-- ffprobe metadata (cached per path+mtime) --------------------------------------
function M.info(path)
  local key = path .. vim.fn.getftime(path)
  if info_cache[key] then
    return info_cache[key]
  end
  local r = vim.system({
    "ffprobe", "-v", "error", "-select_streams", "a:0", "-of", "json",
    "-show_entries", "format=duration,bit_rate,size,format_name:stream=codec_name,sample_rate,channels,channel_layout",
    path,
  }, { text = true }):wait()
  local ok, data = pcall(vim.json.decode, r.stdout or "")
  if not ok or type(data) ~= "table" then
    return nil
  end
  local st = (data.streams or {})[1] or {}
  local fmt = data.format or {}
  local info = {
    duration = tonumber(fmt.duration),
    bit_rate = tonumber(fmt.bit_rate),
    size = tonumber(fmt.size) or vim.fn.getfsize(path),
    format = fmt.format_name,
    codec = st.codec_name,
    sample_rate = tonumber(st.sample_rate),
    channels = tonumber(st.channels),
    layout = st.channel_layout,
  }
  info_cache[key] = info
  return info
end

function M.info_lines(path)
  local i = M.info(path)
  if not i then
    return { "  Could not read audio info (is ffprobe installed?)" }
  end
  local ch = i.channels == 1 and "mono" or i.channels == 2 and "stereo" or ((i.channels or "?") .. " ch")
  local size = i.size and (i.size >= 1048576 and string.format("%.1f MB", i.size / 1048576) or string.format("%.1f KB", i.size / 1024)) or "?"
  return {
    string.format("  Duration     %s", i.duration and string.format("%.2f s (%s)", i.duration, fmt_time(i.duration)) or "?"),
    string.format("  Format       %s · %s", i.format or "?", i.codec or "?"),
    string.format("  Audio        %s Hz · %s%s", i.sample_rate or "?", ch, i.bit_rate and string.format(" · %d kb/s", i.bit_rate / 1000) or ""),
    string.format("  Size         %s", size),
  }
end

-- Player (one at a time) -----------------------------------------------------------
local player = nil ---@type {job:integer, pid:integer, file:string, from:number, to:number?, t0:number, paused:number?, paused_total:number}?
local timer = nil ---@type uv.uv_timer_t?

function M.position()
  if not player then
    return nil
  end
  local now = player.paused or vim.uv.hrtime()
  return player.from + (now - player.t0 - player.paused_total) / 1e9
end

local function refresh_status()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.b[buf].audio_file then
      M.render_status(buf)
    end
  end
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

function M.stop()
  if player then
    local p = player
    player = nil
    pcall(vim.uv.kill, p.pid, "sigcont") -- a stopped process can't handle SIGTERM
    pcall(vim.fn.jobstop, p.job)
  end
  stop_timer()
  refresh_status()
end

function M.play(file, from, to)
  file = vim.fn.fnamemodify(file, ":p")
  if vim.fn.filereadable(file) == 0 then
    return vim.notify("No such audio file: " .. file, vim.log.levels.ERROR)
  end
  M.stop()
  from = math.max(0, from or 0)
  local dur = M.info(file) and M.info(file).duration
  if dur and from >= dur then
    return -- seeking past the end just stops
  end
  local cmd = { "ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", "-ss", tostring(from) }
  if to and to > from then
    vim.list_extend(cmd, { "-t", tostring(to - from) })
  end
  table.insert(cmd, file)
  local job
  job = vim.fn.jobstart(cmd, {
    on_exit = vim.schedule_wrap(function()
      if player and player.job == job then
        player = nil
        stop_timer()
        refresh_status()
      end
    end),
  })
  if job <= 0 then
    return vim.notify("Could not start ffplay", vim.log.levels.ERROR)
  end
  player = { job = job, pid = vim.fn.jobpid(job), file = file, from = from, to = to, t0 = vim.uv.hrtime(), paused_total = 0 }
  timer = vim.uv.new_timer()
  timer:start(0, 200, vim.schedule_wrap(refresh_status))
  if not vim.b.audio_file or vim.b.audio_file ~= file then
    vim.notify(string.format("▶ %s  %s%s", vim.fn.fnamemodify(file, ":t"), fmt_time(from), to and (" → " .. fmt_time(to)) or ""), vim.log.levels.INFO, { title = "Audio" })
  end
end

function M.toggle_pause(file)
  if not player or (file and player.file ~= file) then
    return M.play(file or vim.b.audio_file, vim.b.audio_resume or 0)
  end
  if player.paused then
    vim.uv.kill(player.pid, "sigcont")
    player.paused_total = player.paused_total + (vim.uv.hrtime() - player.paused)
    player.paused = nil
  else
    vim.uv.kill(player.pid, "sigstop")
    player.paused = vim.uv.hrtime()
  end
  refresh_status()
end

function M.seek(delta)
  local file = vim.b.audio_file or (player and player.file)
  if not file then
    return
  end
  local pos = (player and player.file == file and M.position()) or vim.b.audio_resume or 0
  local to = player and player.file == file and player.to or nil
  M.play(file, math.max(0, pos + delta), to)
end

function M.play_range_prompt(file)
  file = file or M.target()
  if not file then
    return vim.notify("No audio file here", vim.log.levels.WARN)
  end
  vim.ui.input({ prompt = "Play range (e.g. 1.2-3.5, 1:05, -2.0): " }, function(text)
    if text then
      M.play(file, M.parse_range(text))
    end
  end)
end

-- The audio file the cursor "means": audio buffer, neo-tree node, or path under cursor
function M.target()
  if vim.b.audio_file then
    return vim.b.audio_file
  end
  if vim.bo.filetype == "neo-tree" then
    local ok, state = pcall(function()
      return require("neo-tree.sources.manager").get_state("filesystem")
    end)
    local node = ok and state and state.tree and state.tree:get_node()
    if node and M.is_audio(node.path) then
      return node.path
    end
  end
  -- audio paths on the current line (CSV/TSV/JSONL manifests, logs…): prefer the one under
  -- the cursor, else the first one. <cfile> alone would swallow commas.
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  local candidates = {}
  local init = 1
  while true do
    local s, e = line:find("[^%s,;\t\"'()%[%]{}|=]+%.%w+", init)
    if not s then
      break
    end
    local path = line:sub(s, e)
    if M.is_audio(path) then
      table.insert(candidates, (s <= col and col <= e) and 1 or #candidates + 1, path)
    end
    init = e + 1
  end
  for _, c in ipairs(candidates) do
    c = vim.fn.expand(c)
    for _, p in ipairs({ c, vim.fn.expand("%:p:h") .. "/" .. c, vim.fn.getcwd() .. "/" .. c }) do
      if vim.fn.filereadable(p) == 1 then
        return vim.fn.fnamemodify(p, ":p")
      end
    end
  end
end

-- Images (waveform + spectrogram via ffmpeg) ---------------------------------------
local function image_paths(file)
  vim.fn.mkdir(cache, "p")
  local key = vim.fn.sha256(file .. vim.fn.getftime(file)):sub(1, 16)
  return cache .. "/" .. key .. "-wave.png", cache .. "/" .. key .. "-spec.png"
end

local function make_images(file, cb)
  local wave, spec = image_paths(file)
  local todo = {}
  if vim.fn.filereadable(wave) == 0 then
    todo[#todo + 1] = { "ffmpeg", "-v", "error", "-y", "-i", file, "-filter_complex",
      "aformat=channel_layouts=mono,showwavespic=s=1800x280:colors=#80CBC4", "-frames:v", "1", wave }
  end
  if vim.fn.filereadable(spec) == 0 then
    todo[#todo + 1] = { "ffmpeg", "-v", "error", "-y", "-i", file, "-lavfi",
      "showspectrumpic=s=1600x480:legend=1:scale=log:color=intensity", "-frames:v", "1", spec }
  end
  local left = #todo
  if left == 0 then
    return cb(wave, spec)
  end
  for _, cmd in ipairs(todo) do
    vim.system(cmd, {}, vim.schedule_wrap(function()
      left = left - 1
      if left == 0 then
        cb(wave, spec)
      end
    end))
  end
end

-- Audio buffer ------------------------------------------------------------------------
local STATUS_LINE = 7 -- 1-based line that shows play state

function M.render_status(buf)
  local file = vim.b[buf].audio_file
  local dur = M.info(file) and M.info(file).duration or 0
  local text, hl
  if player and player.file == file then
    local pos = M.position()
    local width = 30
    local frac = dur > 0 and math.min(1, pos / dur) or 0
    local bar = string.rep("━", math.floor(frac * width)) .. "●" .. string.rep("─", width - math.floor(frac * width))
    text = string.format("  %s %s  %s / %s%s", player.paused and "⏸" or "▶", bar, fmt_time(pos), fmt_time(dur),
      player.to and ("  (until " .. fmt_time(player.to) .. ")") or "")
    hl = player.paused and "DiagnosticWarn" or "DiagnosticOk"
    vim.b[buf].audio_resume = pos
  else
    text, hl = "  ⏹ stopped   <Space> to play", "Comment"
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, STATUS_LINE - 1, STATUS_LINE)
  vim.api.nvim_buf_set_extmark(buf, ns, STATUS_LINE - 1, 0, { virt_text = { { text, hl } }, virt_text_pos = "overlay" })
end

function M.open_buffer(buf, file)
  file = vim.fn.fnamemodify(file, ":p")
  vim.b[buf].audio_file = file
  local bo = vim.bo[buf]
  bo.buftype, bo.swapfile, bo.bufhidden = "nofile", false, "wipe"
  local lines = { "  󰎈 " .. vim.fn.fnamemodify(file, ":t"), "" }
  vim.list_extend(lines, M.info_lines(file))
  vim.list_extend(lines, {
    "",
    "", -- STATUS_LINE (7)
    "",
    "  <Space> play/pause · s stop · 0 from start · h/l ←/→ ±2s · H/L ±10s · r range · q close",
    "",
    "  Waveform",
    "", -- 12: waveform image
    "  Spectrogram",
    "", -- 14: spectrogram image
  })
  bo.modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  bo.modifiable, bo.modified = false, false
  bo.filetype = "audio"
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { end_col = #lines[1], hl_group = "Title" })
  for _, l in ipairs({ 11, 13 }) do
    vim.api.nvim_buf_set_extmark(buf, ns, l - 1, 0, { end_col = #lines[l], hl_group = "Special" })
  end
  M.render_status(buf)

  local o = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<Space>", function() M.toggle_pause(file) end, o)
  vim.keymap.set("n", "s", M.stop, o)
  vim.keymap.set("n", "0", function() M.play(file, 0) end, o)
  vim.keymap.set("n", "r", function() M.play_range_prompt(file) end, o)
  for key, d in pairs({ h = -2, l = 2, ["<Left>"] = -2, ["<Right>"] = 2, H = -10, L = 10 }) do
    vim.keymap.set("n", key, function() M.seek(d) end, o)
  end
  vim.keymap.set("n", "q", function()
    if player and player.file == file then
      M.stop()
    end
    Snacks.bufdelete(buf)
  end, o)

  if not (Snacks and Snacks.image and Snacks.image.supports_terminal()) then
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 11, 12, false, { "  (images need a kitty-graphics terminal: run nvim in kitty)" })
    vim.bo[buf].modifiable, vim.bo[buf].modified = false, false
    return
  end
  make_images(file, function(wave, spec)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local win = vim.fn.bufwinid(buf)
    local width = win ~= -1 and vim.api.nvim_win_get_width(win) - 4 or 100
    local placements = {}
    for _, p in ipairs({ { wave, 12, 8 }, { spec, 14, 16 } }) do
      if vim.fn.filereadable(p[1]) == 1 then
        placements[#placements + 1] = Snacks.image.placement.new(buf, p[1], {
          pos = { p[2], 2 }, inline = true, max_width = width, max_height = p[3],
        })
      end
    end
    vim.b[buf].audio_images = #placements
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_audio", { clear = true })
  local patterns = {}
  for _, e in ipairs(M.exts) do
    vim.list_extend(patterns, { "*." .. e, "*." .. e:upper() })
  end
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = patterns,
    callback = function(ev)
      M.open_buffer(ev.buf, ev.match)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })

  vim.api.nvim_create_user_command("AudioPlay", function(o)
    local file, range = o.fargs[1], table.concat(vim.list_slice(o.fargs, 2), " ")
    if file and not M.is_audio(file) then
      file, range = nil, o.args -- only a range given
    end
    file = file or M.target()
    if not file then
      return vim.notify("No audio file given or under the cursor", vim.log.levels.WARN)
    end
    M.play(file, M.parse_range(range))
  end, { nargs = "*", complete = "file", desc = "Play audio: [file] [from-to]" })
  vim.api.nvim_create_user_command("AudioStop", M.stop, { desc = "Stop audio" })

  vim.keymap.set("n", "<leader>mp", function()
    local file = M.target()
    if not file then
      return vim.notify("No audio file here", vim.log.levels.WARN)
    end
    if player and player.file == file then
      M.toggle_pause(file)
    else
      M.play(file, 0)
    end
  end, { desc = "Play/Pause Audio" })
  vim.keymap.set("n", "<leader>mr", function() M.play_range_prompt() end, { desc = "Play Audio Range" })
  vim.keymap.set("n", "<leader>ms", M.stop, { desc = "Stop Audio" })
end

return M
