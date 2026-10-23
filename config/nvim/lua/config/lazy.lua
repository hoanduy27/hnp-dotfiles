local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
  -- minimal work profile: check out the commit pinned in lazy-lock.json instead of the moving `stable` branch
  local lock = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(lock), "\n")) end)
  local pin = ok and data["lazy.nvim"] and data["lazy.nvim"].commit
  if pin then
    vim.fn.system({ "git", "-C", lazypath, "checkout", "--quiet", pin })
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Minimal work profile: only plugins (Lua/Vimscript) and the plugins they depend on.
    -- Dropped extras: every lang.* (LSP servers/formatters via Mason), dap.core, test.core,
    -- lang.sql (DB clients), markdown (markdown-preview). Browse with :LazyExtras.

    -- editor
    { import = "lazyvim.plugins.extras.editor.neo-tree" }, -- file tree (on the right, like your sidebar)
    { import = "lazyvim.plugins.extras.editor.illuminate" }, -- word highlight
    { import = "lazyvim.plugins.extras.editor.inc-rename" }, -- F2-style rename with live preview
    { import = "lazyvim.plugins.extras.coding.neogen" }, -- njpwerner.autodocstring
    { import = "lazyvim.plugins.extras.ui.treesitter-context" }, -- editor sticky scroll

    -- your own overrides
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "github_dark_high_contrast", "tokyonight", "habamax" } },
  checker = { enabled = false }, -- work profile: no background update checks; :Lazy update is manual
  performance = {
    rtp = {
      -- "tutor" is intentionally kept enabled: run :Tutor to learn vim
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "zipPlugin" },
    },
  },
})
