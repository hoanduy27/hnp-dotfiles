-- Options are automatically loaded before lazy.nvim startup
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Pylance-like Python LSP (basedpyright is the open-source fork closest to Pylance)
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

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

-- Open .pdf files in a real reader (sioyek: search + highlights; zathura: search) instead of
-- snacks.image's static page-1 preview. Must be a BufReadCmd (snacks reads PDFs with one, so
-- BufReadPost never fires) and must live here, not autocmds.lua: that loads on VeryLazy, after
-- `nvim file.pdf` has already read the file.
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("user_pdf_viewer", { clear = true }),
  pattern = "*.pdf",
  callback = function(ev)
    local viewer = vim.fn.executable("sioyek") == 1 and "sioyek" or vim.fn.executable("zathura") == 1 and "zathura"
    if not viewer then
      return
    end
    vim.system({ viewer, vim.fn.fnamemodify(ev.file, ":p") }, { detach = true })
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        pcall(vim.cmd.bwipeout, { ev.buf, bang = true })
      end
    end)
  end,
})
