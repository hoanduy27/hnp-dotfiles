local symbol_kinds = {
  "Class", "Constructor", "Enum", "EnumMember", "Field", "Function", "Interface", "Method",
  "Module", "Namespace", "Package", "Property", "Struct", "Trait", "Variable", "Constant",
}

-- hide locals: a Variable/Constant nested in a function/method is not a class property
local function_kinds = { Function = true, Method = true, Constructor = true }
local function is_local_var(kind, parent)
  if kind ~= "Variable" and kind ~= "Constant" then
    return false
  end
  while parent do
    if function_kinds[parent.kind] then
      return true
    end
    parent = parent.parent
  end
  return false
end

return {
  -- "workbench.sideBar.location": "right"
  -- <leader>e / <C-b> toggles it. Inside the tree press ? for help.
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = { position = "right", width = 35 },
      filesystem = {
        filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
        follow_current_file = { enabled = true },
      },
    },
  },

  -- symbols (<leader>ss, <leader>cs): also list variables/constants/enum members, like VS Code's outline
  -- (pyright reports class attributes / self.x as Variable, which LazyVim hides by default)
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      opts.kind_filter = opts.kind_filter or {}
      opts.kind_filter.default = symbol_kinds
      -- luals reports control-flow blocks as Package, so leave it out for lua (same as LazyVim's default)
      opts.kind_filter.lua = vim.tbl_filter(function(k) return k ~= "Package" end, symbol_kinds)
    end,
  },
  -- <leader>cs outline sidebar (trouble keeps its own kind list)
  {
    "folke/trouble.nvim",
    opts = {
      modes = {
        symbols = {
          filter = {
            any = { kind = symbol_kinds },
            function(item)
              return not is_local_var(item.kind, item.parent)
            end,
          },
        },
      },
    },
  },

  -- find files (<leader><leader>, <leader>ff): show dotfiles (.vscode) and gitignored files (.env),
  -- but keep heavy/generated dirs out. Toggle in the picker: <A-h> hidden, <A-i> ignored.
  {
    "folke/snacks.nvim",
    opts = {
      -- ctrl+k = down, ctrl+j = up in picker lists (snacks default is the other way round)
      picker = {
        win = {
          input = {
            keys = {
              ["<c-k>"] = { "list_down", mode = { "i", "n" } },
              ["<c-j>"] = { "list_up", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<c-k>"] = "list_down",
              ["<c-j>"] = "list_up",
            },
          },
        },
        sources = {
          lsp_symbols = {
            transform = function(item)
              return not is_local_var(item.kind, item.parent)
            end,
          },
          files = {
            hidden = true,
            ignored = true,
            exclude = { ".git", "node_modules", ".venv", "venv", "__pycache__", ".mypy_cache", ".pytest_cache", "dist", "build" },
          },
        },
      },
    },
  },

  -- terminal windows: ctrl+k = lower window, ctrl+j = upper window (matches config/keymaps.lua).
  -- Floating terminals (lazygit, <C-/>) get the key passed through, so lazygit sees your ctrl+j/k.
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local function term_nav(key, dir)
        return function(self)
          return self:is_floating() and key or vim.schedule(function()
            vim.cmd.wincmd(dir)
          end)
        end
      end
      opts.terminal = opts.terminal or {}
      opts.terminal.win = opts.terminal.win or {}
      opts.terminal.win.keys = opts.terminal.win.keys or {}
      opts.terminal.win.keys.nav_j = { "<C-k>", term_nav("<c-k>", "j"), desc = "Go to Lower Window", expr = true, mode = "t" }
      opts.terminal.win.keys.nav_k = { "<C-j>", term_nav("<c-j>", "k"), desc = "Go to Upper Window", expr = true, mode = "t" }
    end,
  },

  -- completion menu: ctrl+k = next, ctrl+j = previous.
  -- With the menu closed, ctrl+k still toggles signature help (blink's default for that key).
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-k>"] = { "select_next", "show_signature", "hide_signature", "fallback" },
        ["<C-j>"] = { "select_prev", "fallback" },
      },
    },
  },

  -- editor.action.peekDefinition (alt+f12): show the definition in a floating window without jumping.
  -- Peeks can be nested (gpd again inside the popup). q closes one popup, gP closes them all.
  {
    "rmagatti/goto-preview",
    event = "LspAttach",
    dependencies = { "rmagatti/logger.nvim" },
    opts = {
      width = 138,
      height = 30,
      references = { provider = "snacks" },
    },
    init = function()
      -- q closes the popup when the cursor is in one, and is normal q (record macro) everywhere else.
      -- A global map instead of goto-preview's open/close hooks: those miss files the peek has to load.
      vim.keymap.set("n", "q", function()
        if vim.w["is-goto-preview-window"] ~= 1 then
          return "q"
        end
        local win = vim.api.nvim_get_current_win()
        vim.schedule(function()
          pcall(vim.api.nvim_win_close, win, false)
        end)
        return ""
      end, { expr = true, desc = "Close Peek / Record Macro" })
    end,
    keys = {
      { "gpd", function() require("goto-preview").goto_preview_definition() end, desc = "Peek Definition" },
      { "<A-F12>", function() require("goto-preview").goto_preview_definition() end, desc = "Peek Definition" },
      -- some terminals send alt+f12 as F60 (xterm: F12 + 48 for the alt modifier)
      { "<F60>", function() require("goto-preview").goto_preview_definition() end, desc = "Peek Definition" },
      { "gpy", function() require("goto-preview").goto_preview_type_definition() end, desc = "Peek Type Definition" },
      { "gpi", function() require("goto-preview").goto_preview_implementation() end, desc = "Peek Implementation" },
      { "gpD", function() require("goto-preview").goto_preview_declaration() end, desc = "Peek Declaration" },
      { "gpr", function() require("goto-preview").goto_preview_references() end, desc = "Peek References" },
      { "gP", function() require("goto-preview").close_all_win() end, desc = "Close All Peeks" },
    },
  },

  -- "files.autoSave": "afterDelay" (VS Code default delay = 1000ms)
  {
    "okuuva/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      debounce_delay = 1000,
      condition = function(buf)
        -- don't autosave special buffers (terminals, git commit messages being written, etc.),
        -- read-only files, or :Tutor (it would save your practice edits into the lesson file)
        local ft = vim.bo[buf].filetype
        return vim.bo[buf].buftype == ""
          and not vim.bo[buf].readonly
          and not vim.tbl_contains({ "gitcommit", "gitrebase", "tutor" }, ft)
      end,
    },
  },

  -- eamodio.gitlens: inline blame on the current line (gitsigns ships with LazyVim;
  -- <leader>gg opens lazygit, <leader>gb blame line, <leader>gv diffview, <leader>gV file history)
  {
    "lewis6991/gitsigns.nvim",
    opts = { current_line_blame = true, current_line_blame_opts = { delay = 500 } },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview (working tree)" },
      { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (GitLens-ish)" },
    },
    opts = function(_, opts)
      -- q closes diffview from any of its windows (diff panes, file list, history list)
      local close = { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } }
      opts.keymaps = opts.keymaps or {}
      for _, section in ipairs({ "view", "file_panel", "file_history_panel" }) do
        opts.keymaps[section] = opts.keymaps[section] or {}
        table.insert(opts.keymaps[section], close)
      end
    end,
  },

  -- "editor.minimap": always on, like VS Code. <leader>um toggles it, <leader>uM jumps into it:
  -- j/k (or click / drag with the mouse) scrolls the file, <CR> stays there, <Esc> goes back.
  {
    "nvim-mini/mini.map",
    version = false,
    event = "LazyFile",
    keys = {
      { "<leader>um", function() require("mini.map").toggle() end, desc = "Toggle Minimap" },
      { "<leader>uM", function() require("mini.map").toggle_focus() end, desc = "Focus Minimap (scroll)" },
    },
    config = function()
      local map = require("mini.map")

      -- git changes as solid colored bars (green added, blue changed, red deleted), like VS Code's minimap
      local function git_hl()
        local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
        for name, src in pairs({ Add = "GitSignsAdd", Change = "GitSignsChange", Delete = "GitSignsDelete" }) do
          vim.api.nvim_set_hl(0, "MiniMapGit" .. name, { bg = vim.api.nvim_get_hl(0, { name = src, link = false }).fg, fg = bg })
        end
      end
      git_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = git_hl })

      map.setup({
        -- first match wins per map line, so git colors take priority over diagnostics and search
        integrations = {
          map.gen_integration.gitsigns({ add = "MiniMapGitAdd", change = "MiniMapGitChange", delete = "MiniMapGitDelete" }),
          map.gen_integration.diagnostic(),
          map.gen_integration.builtin_search(),
        },
        symbols = { encode = map.gen_encode_symbols.dot("4x2") },
        window = { focusable = true }, -- lets the mouse click / drag inside the map
      })
      map.open()
    end,
  },

  -- "mermaid"
  {
    "kevalin/mermaid.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("mermaid").setup()

        -- Install the Tree-sitter parser:
        -- :TSInstall mermaid
    end,
  }
 }
