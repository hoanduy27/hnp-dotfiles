-- Browse the web inside Neovim with Browsh (pages rendered by a real, headless Firefox,
-- so JavaScript sites work) in a floating terminal. Install: scripts/07-browsh.sh
--   :Browse <url>          open a page            :Browse <words>  search DuckDuckGo
--   :Browse                prompt (defaults to the URL under the cursor)
--   <leader>fw             same as :Browse
--   <leader>fW             search the web for the word under the cursor / the selection
-- Inside Browsh: mouse click follows links, arrows/PgUp/PgDn scroll, Ctrl+L address bar,
--   Backspace back, Ctrl+R reload, Ctrl+T new tab, Ctrl+W close tab, Ctrl+Q quit.
--   <C-/> hides the window (Browsh keeps running).

local search_url = "https://html.duckduckgo.com/html/?q="
-- Browsh can't drive the Snap Firefox, so 07-browsh.sh installs a private one here
local firefox = vim.fn.expand("~/.local/opt/firefox-browsh/firefox")

local term ---@type snacks.win?

local function to_url(input)
  input = vim.trim(input or "")
  if input:match("^%a[%w+.-]*://") or input:match("^file:") then
    return input
  end
  if input:match("^[%w-]+%.[%w.-]+[/:]?%S*$") and not input:find("%s") then
    return "https://" .. input -- bare domain like neovim.io/doc
  end
  return search_url .. vim.uri_encode(input)
end

local function running()
  local job = term and term:buf_valid() and vim.b[term.buf].terminal_job_id
  return job and vim.fn.jobwait({ job }, 0)[1] == -1 and job or nil
end

local function browse(input)
  if not input or vim.trim(input) == "" then
    return
  end
  if vim.fn.executable("browsh") == 0 or vim.fn.executable(firefox) == 0 then
    return vim.notify("Browsh isn't set up yet: run nvim_migration/scripts/07-browsh.sh", vim.log.levels.ERROR)
  end
  -- only one Browsh can run at a time: quit the current one (Ctrl+Q) before opening a new page
  local job = running()
  if job then
    vim.fn.chansend(job, "\17")
    vim.fn.jobwait({ job }, 5000)
  end
  if term and term:valid() then
    term:close()
  end
  term = Snacks.terminal.open({ "browsh", "--firefox.path", firefox, "--startup-url", to_url(input) }, {
    win = { position = "float", width = 0.95, height = 0.92, border = "rounded", title = " browsh ", title_pos = "center" },
    auto_close = true,
  })
end

local function prompt()
  local cfile = vim.fn.expand("<cfile>")
  vim.ui.input({
    prompt = "Browse (URL or search): ",
    default = cfile:match("^https?://") and cfile or "",
  }, browse)
end

local function search_selection()
  local text
  if vim.fn.mode():find("[vV]") then
    text = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos(".")), " ")
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  else
    text = vim.fn.expand("<cword>")
  end
  browse(search_url .. vim.uri_encode(text))
end

return {
  {
    "user/browse",
    virtual = true,
    lazy = false,
    init = function()
      vim.api.nvim_create_user_command("Browse", function(o)
        if o.args == "" then
          prompt()
        else
          browse(o.args)
        end
      end, { nargs = "*", desc = "Browse the web with Browsh" })
    end,
    keys = {
      { "<leader>fw", prompt, desc = "Browse Web (browsh)" },
      { "<leader>fW", search_selection, mode = { "n", "x" }, desc = "Search Web for Word/Selection" },
    },
  },
}
