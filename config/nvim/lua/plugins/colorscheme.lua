-- Recreates your VS Code look:
--   "workbench.colorTheme": "Default High Contrast"  -> github_dark_high_contrast
--   comments "#8f8f8f", teal accents (#00716B / #80CBC4), selection "#ffffff50"
--   transparent editor background -> lets Alacritty's opacity (0.80) + tinted bg show through
-- Switch themes live with <leader>uC (tokyonight is also installed, you had Tokyo Night too);
-- your pick is remembered across restarts.

local default_theme = "catppuccin"
local saved_theme_file = vim.fn.stdpath("state") .. "/colorscheme"

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_save_colorscheme", { clear = true }),
  callback = function(ev)
    pcall(vim.fn.writefile, { ev.match }, saved_theme_file)
  end,
})

local teal = "#00716B"
local teal_light = "#80CBC4"

return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    opts = {
      options = {
        transparent = true,
        styles = { comments = "italic" },
      },
      groups = {
        all = {
          Comment = { fg = "#8f8f8f" },
          ["@comment"] = { link = "Comment" },
          Visual = { bg = "#3d4a49" }, -- ~ "#ffffff50" over your dark teal bg
          CursorLineNr = { fg = teal_light, style = "bold" },
          WinSeparator = { fg = teal },
          FloatBorder = { fg = teal }, -- "widget.border" / "menu.border"
          NormalFloat = { bg = "#0b1716" }, -- floats opaque enough to read
          NeoTreeNormal = { bg = "NONE" },
          NeoTreeNormalNC = { bg = "NONE" },
          IlluminatedWordText = { style = "underline", sp = "#f3dd18" }, -- "editor.wordHighlightBorder"
          IlluminatedWordRead = { style = "underline", sp = "#f3dd18" },
          IlluminatedWordWrite = { style = "underline", sp = "#f3dd18" },
        },
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
    end,
  },
  { "folke/tokyonight.nvim", opts = { transparent = true, styles = { sidebars = "transparent", floats = "transparent" } } },
  -- Remember the last theme you picked (<leader>uC or :colorscheme), like VS Code does.
  -- Saved in ~/.local/state/nvim/colorscheme; delete that file to go back to the default.
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local ok, lines = pcall(vim.fn.readfile, saved_theme_file)
        local name = ok and lines[1] or default_theme
        if not pcall(vim.cmd.colorscheme, name) then
          vim.cmd.colorscheme(default_theme)
        end
      end,
    },
  },

  -- "statusBar.background": "#00716B"
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local theme = require("lualine.themes.auto")
      for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command" }) do
        if theme[mode] and theme[mode].a then
          theme[mode].b = { fg = "#ffffff", bg = teal }
        end
      end
      theme.normal.a = { fg = "#000000", bg = teal_light, gui = "bold" }
      opts.options.theme = theme
    end,
  },
}
