-- Options are automatically loaded before lazy.nvim startup
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- VS Code had no "editor.formatOnSave", so don't format on every (auto)save.
-- Format manually with <leader>cf, or toggle back on with <leader>uf.
vim.g.autoformat = false

local opt = vim.opt

-- "editor.wordWrap": "on"
opt.wrap = true
opt.linebreak = true -- wrap at word boundaries
opt.breakindent = true -- wrapped lines keep indentation

-- VS Code-ish feel: absolute numbers. Relative numbers make vim motions (5j, 3dk)
-- easier once you're used to them: toggle with <leader>uL.
opt.relativenumber = false

-- autosave writes files frequently; keep undo history across sessions
opt.undofile = true

-- "terminal.integrated.cursorStyle": "line" -> thin cursor in insert mode (LazyVim default already)

-- Diagnostics (LSP errors/warnings) start hidden. Toggle them on/off with <leader>ud.
vim.diagnostic.enable(false)
