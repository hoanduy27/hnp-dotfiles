-- Minimal work-machine profile: only Neovim plugins (Lua/Vimscript) and the plugins they depend on.
-- Nothing here may download or build a program: no Mason (LSP servers, formatters, debuggers),
-- no treesitter parser installs, no runtime binary downloads (blink.cmp's library is installed
-- from a pinned hash by scripts/25-blink-cmp.sh), no browser/Chrome/npm servers.
--   removed: coder/claudecode.nvim, Browsh, kevalin/mermaid.nvim, mermaid-cli, markdown-preview.nvim
return {
  -- Mason downloads prebuilt binaries/npm/PyPI packages. LazyVim runs fine without it
  -- (servers/formatters you already have on PATH still work; add them in nvim-lspconfig opts.servers).
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },

  -- nvim-treesitter (main) fetches grammar repos and compiles them with the tree-sitter CLI.
  -- Install no parsers; the ones bundled in Neovim (c, lua, vim, vimdoc, query, markdown) still highlight.
  {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },

  -- blink.cmp: use the Rust fuzzy matcher, but never let the plugin download it at runtime.
  -- scripts/25-blink-cmp.sh installs the pinned, sha256-verified library; until then (or if it is
  -- missing) blink falls back to its Lua matcher with a warning.
  {
    "saghen/blink.cmp",
    opts = {
      fuzzy = {
        implementation = "prefer_rust_with_warning",
        prebuilt_binaries = { download = false },
      },
    },
  },

  -- inline images/diagrams shell out to external converters (ImageMagick, mermaid-cli)
  { "folke/snacks.nvim", opts = { image = { enabled = false } } },
}
