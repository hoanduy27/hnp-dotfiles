-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- [dockercompose] / yaml: 2-space indent (from your VS Code settings)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_yaml_indent", { clear = true }),
  pattern = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values", "helm" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

-- :Tutor shows ✓/✗ as signs, but LazyVim's statuscolumn (Snacks) picks the tutor's empty
-- line-highlight extmark instead of the ✗ sign, so the marks never appear.
-- Use Neovim's native gutter in tutor windows, and restore it when another file opens there.
local function set_tutor_gutter(win, on)
  -- scope = "local" is :setlocal; vim.wo[win].x = ... would also change the global value
  local function setlocal(name, value)
    vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
  end
  if on then
    vim.w[win].tutor_gutter = true
    setlocal("statuscolumn", "")
    setlocal("signcolumn", "yes")
  elseif vim.w[win].tutor_gutter then
    vim.w[win].tutor_gutter = nil
    setlocal("statuscolumn", vim.go.statuscolumn)
    setlocal("signcolumn", vim.go.signcolumn)
  end
end
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("user_tutor_signs", { clear = true }),
  callback = function(ev)
    set_tutor_gutter(vim.api.nvim_get_current_win(), vim.bo[ev.buf].filetype == "tutor")
  end,
})
-- this file loads on VeryLazy, so `nvim +Tutor` has already opened the tutor by now
for _, win in ipairs(vim.api.nvim_list_wins()) do
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "tutor" then
    set_tutor_gutter(win, true)
  end
end

-- small floating table of contents in markdown files (<leader>ct toggle, <leader>cT focus)
require("config.md_toc").setup()

-- Keep autosave from writing an old copy over files changed outside nvim (Claude edits, git checkout, ...).
-- nvim only noticed disk changes on focus/terminal events, so a buffer could stay stale while Claude
-- ran in a split; the next edit + autosave then hit "file changed since reading, write anyway? (y/n)",
-- and any key answering "y" (or choosing OK at the reload prompt) put the old text back.
-- Now: the disk version always wins, without prompting. If you had unsaved typing in that buffer,
-- `u` right after the reload brings it back (the reload is an undo step).
vim.api.nvim_create_autocmd("FileChangedShell", {
  group = vim.api.nvim_create_augroup("user_disk_wins", { clear = true }),
  callback = function(ev)
    local reason = vim.v.fcs_reason
    if vim.bo[ev.buf].buftype ~= "" or reason == "deleted" then
      vim.v.fcs_choice = ""
      return
    end
    local had_edits = vim.bo[ev.buf].modified
    vim.v.fcs_choice = "reload"
    if had_edits then
      local name = vim.fn.fnamemodify(ev.file, ":~:.")
      vim.schedule(function()
        vim.notify(name .. " changed on disk and was reloaded.\nPress u in it to get your unsaved edits back.", vim.log.levels.WARN)
      end)
    end
  end,
})

local function checktime(buf)
  -- checktime errors in the command-line window; prompts must not pop up mid-command either
  if vim.fn.getcmdwintype() ~= "" or vim.fn.mode():sub(1, 1) == "c" then
    return
  end
  pcall(vim.cmd.checktime, buf)
end

-- re-check the file right before every autosave, so it never writes over a newer version
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("user_autosave_checktime", { clear = true }),
  pattern = "AutoSaveWritePre",
  callback = function(ev)
    checktime(ev.data and ev.data.saved_buffer)
  end,
})

-- notice outside changes within a second, also while you're typing into the Claude terminal
-- (no FocusGained/CursorHold fires there). Skipped in insert mode; the pre-save check covers it.
local disk_timer = vim.uv.new_timer()
disk_timer:start(1000, 1000, vim.schedule_wrap(function()
  if vim.fn.mode():sub(1, 1) ~= "i" then
    checktime()
  end
end))
