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
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Extras replacing your VS Code extensions (see README "What maps to what").
    -- Browse/toggle more at runtime with :LazyExtras.

    -- languages
    { import = "lazyvim.plugins.extras.lang.python" }, -- ms-python.*, pylance, debugpy
    { import = "lazyvim.plugins.extras.lang.go" }, -- golang.go
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.yaml" }, -- redhat.vscode-yaml (+ k8s/compose/GHA schemas)
    { import = "lazyvim.plugins.extras.lang.docker" }, -- vscode-containers
    { import = "lazyvim.plugins.extras.lang.helm" }, -- vscode-kubernetes-tools
    { import = "lazyvim.plugins.extras.lang.markdown" }, -- markdown (markdown-preview disabled in plugins/work.lua)
    { import = "lazyvim.plugins.extras.lang.tex" }, -- latex-workshop
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.git" },
    { import = "lazyvim.plugins.extras.lang.sql" }, -- postgres/mysql/sqlite browser (dadbod-ui), <leader>D

    -- debugging / testing
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.test.core" },

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
