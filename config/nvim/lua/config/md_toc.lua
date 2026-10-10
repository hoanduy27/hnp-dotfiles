-- Small floating table of contents for markdown, pinned to the window's top-right corner.
-- It highlights the section the cursor is in and follows your edits.
--   <leader>ct  toggle it on/off
--   <leader>cT  focus it; then <CR> (or a mouse click) jumps to a heading, q / <Esc> goes back
local M = {}

local config = {
  enabled = true, -- shown automatically in markdown buffers
  min_headings = 2, -- don't bother for files with fewer headings
  max_width = 40,
  max_height = 15,
}

local ns = vim.api.nvim_create_namespace("user_md_toc")
local toc = { buf = nil, win = nil, src_win = nil, src_buf = nil, items = {} }

local function is_md_win(win)
  if not (win and vim.api.nvim_win_is_valid(win)) or win == toc.win then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].filetype == "markdown"
    and vim.bo[buf].buftype == ""
    and vim.api.nvim_win_get_config(win).relative == "" -- skip floats (hover, pickers…)
end

-- ATX headings (# …), ignoring fenced code blocks
local function parse(buf)
  local items, fence = {}, nil
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local f = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
    if f then
      if not fence then
        fence = f:sub(1, 1)
      elseif f:sub(1, 1) == fence then
        fence = nil
      end
    elseif not fence then
      local hashes, text = line:match("^(#+)%s+(.-)%s*#*%s*$")
      if hashes and #hashes <= 6 and text ~= "" then
        text = text:gsub("%[(.-)%]%b()", "%1"):gsub("[`*_]", "") -- links -> text, drop emphasis
        items[#items + 1] = { lnum = lnum, level = #hashes, text = text }
      end
    end
  end
  return items
end

local function close()
  if toc.win and vim.api.nvim_win_is_valid(toc.win) then
    vim.api.nvim_win_close(toc.win, true)
  end
  toc.win = nil
end

local function current_index()
  if not (toc.src_win and vim.api.nvim_win_is_valid(toc.src_win)) then
    return nil
  end
  local cur = vim.api.nvim_win_get_cursor(toc.src_win)[1]
  local idx
  for i, item in ipairs(toc.items) do
    if item.lnum > cur then
      break
    end
    idx = i
  end
  return idx
end

local function highlight_current()
  if not (toc.win and vim.api.nvim_win_is_valid(toc.win)) then
    return
  end
  vim.api.nvim_buf_clear_namespace(toc.buf, ns, 0, -1)
  for i, item in ipairs(toc.items) do
    vim.api.nvim_buf_set_extmark(toc.buf, ns, i - 1, 0, {
      end_col = #vim.api.nvim_buf_get_lines(toc.buf, i - 1, i, false)[1],
      hl_group = "@markup.heading." .. math.min(item.level, 6) .. ".markdown",
    })
  end
  local idx = current_index()
  if idx then
    vim.api.nvim_buf_set_extmark(toc.buf, ns, idx - 1, 0, { line_hl_group = "Visual", priority = 200 })
    if vim.api.nvim_get_current_win() ~= toc.win then
      vim.api.nvim_win_set_cursor(toc.win, { idx, 0 }) -- keep the current heading in view
    end
  end
end

local function jump()
  local item = toc.items[vim.api.nvim_win_get_cursor(0)[1]]
  if item and toc.src_win and vim.api.nvim_win_is_valid(toc.src_win) then
    vim.api.nvim_set_current_win(toc.src_win)
    vim.api.nvim_win_set_cursor(toc.src_win, { item.lnum, 0 })
    vim.cmd("normal! zt")
  end
end

local function ensure_buf()
  if toc.buf and vim.api.nvim_buf_is_valid(toc.buf) then
    return
  end
  toc.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[toc.buf].bufhidden = "hide"
  vim.bo[toc.buf].filetype = "md_toc"
  local o = { buffer = toc.buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", jump, o)
  vim.keymap.set("n", "<LeftRelease>", jump, o)
  vim.keymap.set("n", "q", function() vim.api.nvim_set_current_win(toc.src_win) end, o)
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_set_current_win(toc.src_win) end, o)
end

function M.update()
  local win = vim.api.nvim_get_current_win()
  if win == toc.win then
    return -- you're inside the ToC
  end
  if not config.enabled or not is_md_win(win) then
    return close()
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local items = parse(buf)
  if #items < config.min_headings then
    return close()
  end
  toc.src_win, toc.src_buf, toc.items = win, buf, items

  local min_level = 6
  for _, item in ipairs(items) do
    min_level = math.min(min_level, item.level)
  end
  local win_w, win_h = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
  local width = math.min(config.max_width, math.floor(win_w * 0.35))
  local lines, longest = {}, 0
  for _, item in ipairs(items) do
    local line = string.rep("  ", item.level - min_level) .. item.text
    if vim.fn.strdisplaywidth(line) > width then
      line = vim.fn.strcharpart(line, 0, width - 1) .. "…"
    end
    lines[#lines + 1] = line
    longest = math.max(longest, vim.fn.strdisplaywidth(line))
  end
  width = math.max(10, math.min(width, longest + 1))
  local height = math.max(1, math.min(#lines, config.max_height, win_h - 3))

  ensure_buf()
  vim.bo[toc.buf].modifiable = true
  vim.api.nvim_buf_set_lines(toc.buf, 0, -1, false, lines)
  vim.bo[toc.buf].modifiable = false

  local cfg = {
    relative = "win",
    win = win,
    anchor = "NE",
    row = 0,
    col = win_w,
    width = width,
    height = height,
    border = "rounded",
    title = " Contents ",
    title_pos = "center",
    style = "minimal",
    focusable = true,
    zindex = 40,
  }
  if toc.win and vim.api.nvim_win_is_valid(toc.win) then
    vim.api.nvim_win_set_config(toc.win, cfg)
  else
    cfg.noautocmd = true
    toc.win = vim.api.nvim_open_win(toc.buf, false, cfg)
    vim.wo[toc.win].wrap = false
    vim.wo[toc.win].cursorline = false
    vim.wo[toc.win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
  end
  highlight_current()
end

function M.toggle()
  config.enabled = not config.enabled
  M.update()
  vim.notify("Markdown ToC " .. (config.enabled and "on" or "off"))
end

function M.focus()
  if not config.enabled then
    config.enabled = true
    M.update()
  end
  if toc.win and vim.api.nvim_win_is_valid(toc.win) then
    vim.api.nvim_set_current_win(toc.win)
    vim.api.nvim_win_set_cursor(toc.win, { current_index() or 1, 0 })
  else
    vim.notify("No headings to show", vim.log.levels.WARN)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_md_toc", { clear = true })
  local update = vim.schedule_wrap(M.update)
  vim.api.nvim_create_autocmd(
    { "BufWinEnter", "WinEnter", "BufEnter", "TextChanged", "InsertLeave", "BufWritePost", "WinResized", "VimResized", "FileType" },
    { group = group, callback = update }
  )
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() == toc.src_win then
        highlight_current()
      end
    end,
  })
  vim.keymap.set("n", "<leader>ct", M.toggle, { desc = "Toggle Markdown ToC" })
  vim.keymap.set("n", "<leader>cT", M.focus, { desc = "Focus Markdown ToC" })
  update() -- a markdown file opened on the command line is already showing
end

return M
