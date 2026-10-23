-- Language tweaks (work profile: no LSP servers, no extra treesitter parsers)
return {
  -- latex-workshop: your recipe was lualatex with synctex. --shell-escape is dropped in the work profile
  -- (it lets a .tex file run arbitrary shell commands); add it back per project if you need it.
  -- <localleader>ll compile (continuous), <localleader>lv view, <localleader>lc clean
  {
    "lervag/vimtex",
    -- VimTeX > v2.18 requires Neovim >= 0.12.4; stay on v2.18 until you upgrade (scripts/00-upgrade-neovim.sh)
    tag = vim.fn.has("nvim-0.12.4") == 0 and "v2.18" or nil,
    init = function()
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk_engines = { _ = "-lualatex" }
      vim.g.vimtex_compiler_latexmk = {
        options = { "-synctex=1", "-interaction=nonstopmode", "-file-line-error" },
      }
      -- sioyek: forward/inverse search + highlights; zathura: search only; else default PDF viewer
      vim.g.vimtex_view_method = vim.fn.executable("sioyek") == 1 and "sioyek"
        or vim.fn.executable("zathura") == 1 and "zathura"
        or "general"
    end,
  },

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
