-- Start Claude Code in a folder other than nvim's cwd (sessions are per folder, so this
-- also decides which sessions --resume can see).
--   <leader>aD         pick a folder under cwd -> new Claude there
--   <leader>aR         pick a folder under cwd -> resume a session from that folder
--   :ClaudeIn <dir>    any folder, with tab completion (:ClaudeIn! <dir> to resume)
-- The folder sticks for later <leader>ac toggles until you pick another one.

local function start_claude_in(dir, args)
  dir = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(dir), ":p"))
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("Not a directory: " .. dir, vim.log.levels.ERROR)
    return
  end
  vim.g.claude_cwd = dir
  require("lazy").load({ plugins = { "claudecode.nvim" } }) -- defines :ClaudeCode if not loaded yet
  -- a running Claude keeps its folder, so stop it and start a fresh one
  require("claudecode.terminal").close()
  vim.cmd("ClaudeCode" .. (args and (" " .. args) or ""))
  vim.notify("Claude Code in " .. vim.fn.fnamemodify(dir, ":~"))
end

-- Fuzzy-pick a folder under nvim's cwd (the cwd itself is listed first as "./").
local function pick_folder(args)
  local cwd = vim.fn.getcwd()
  Snacks.picker.pick({
    source = "claude_folders",
    title = (args and "Resume Claude in… " or "Start Claude in… ") .. vim.fn.fnamemodify(cwd, ":~"),
    format = "file",
    finder = function(opts, ctx)
      local proc = require("snacks.picker.source.proc").proc(
        ctx:opts({
          cmd = "fd",
          args = {
            "--type", "d", "--hidden", "--color", "never",
            "-E", ".git", "-E", "node_modules", "-E", ".venv", "-E", "venv", "-E", "__pycache__", "-E", ".cache",
          },
          cwd = cwd,
          transform = function(item)
            item.cwd = cwd
            item.file = item.text
          end,
        }),
        ctx
      )
      return function(cb)
        cb({ text = "./", file = ".", cwd = cwd })
        proc(cb)
      end
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        start_claude_in(Snacks.picker.util.path(item), args)
      end
    end,
  })
end

return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        cwd_provider = function(ctx)
          return vim.g.claude_cwd or ctx.cwd
        end,
      },
    },
    init = function()
      vim.api.nvim_create_user_command("ClaudeIn", function(o)
        start_claude_in(o.args ~= "" and o.args or vim.fn.getcwd(), o.bang and "--resume" or nil)
      end, { nargs = "?", bang = true, complete = "dir", desc = "Start Claude Code in a folder (! = resume)" })
    end,
    keys = {
      { "<leader>aD", function() pick_folder() end, desc = "Claude in Folder…" },
      { "<leader>aR", function() pick_folder("--resume") end, desc = "Resume Claude in Folder…" },
    },
  },
}
