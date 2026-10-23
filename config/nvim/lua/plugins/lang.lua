-- Language tweaks on top of the LazyVim lang extras enabled in config/lazy.lua
return {
  -- latex-workshop: your recipe was lualatex with --shell-escape + synctex
  -- <localleader>ll compile (continuous), <localleader>lv view, <localleader>lc clean
  {
    "lervag/vimtex",
    -- VimTeX > v2.18 requires Neovim >= 0.12.4; stay on v2.18 until you upgrade (scripts/00-upgrade-neovim.sh)
    tag = vim.fn.has("nvim-0.12.4") == 0 and "v2.18" or nil,
    init = function()
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk_engines = { _ = "-lualatex" }
      vim.g.vimtex_compiler_latexmk = {
        options = { "-shell-escape", "-synctex=1", "-interaction=nonstopmode", "-file-line-error" },
      }
      -- sioyek: forward/inverse search + highlights; zathura: search only; else default PDF viewer
      vim.g.vimtex_view_method = vim.fn.executable("sioyek") == 1 and "sioyek"
        or vim.fn.executable("zathura") == 1 and "zathura"
        or "general"
    end,
  },

  -- extra treesitter parsers: drblury.protobuf-vsc, wholroyd.jinja, rainbow-csv, shell
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "proto", "jinja", "jinja_inline", "csv", "tsv", "bash", "htmldjango" } },
  },

  -- protobuf LSP (buf) + django templates
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        buf_ls = {},
      },
    },
  },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "buf" } } },

  -- mechatroner.rainbow-csv / janisdd.vscode-edit-csv: column colors + aligned view
  -- :CsvViewToggle
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    opts = { view = { display_mode = "border" } },
    config = function(_, opts)
      require("csvview").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function() require("csvview").enable() end,
      })
      if vim.tbl_contains({ "csv", "tsv" }, vim.bo.filetype) then
        require("csvview").enable()
      end
    end,
  },
}
