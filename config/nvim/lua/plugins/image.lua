-- Inline images in Neovim, incl. ```mermaid blocks in markdown rendered as diagrams.
-- Needs a terminal with the kitty graphics protocol (kitty / ghostty), NOT Alacritty or Terminator.
-- In other terminals this silently does nothing.
-- Requirements (scripts/06-kitty-mermaid.sh): kitty, mermaid-cli (`mmdc`), ImageMagick.
local puppeteer_cfg = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath("config")), ":h") .. "/mermaid/puppeteer.json"

-- Zoom viewer for the diagram/image under the cursor: <leader>cz (in markdown).
-- Inline images are always shrunk to fit the window, so the viewer re-renders mermaid at
-- high resolution and zooms by cropping (ImageMagick), which keeps it sharp.
--   + / =  zoom in      -  zoom out      0  fit
--   h j k l / arrows    pan              o  open in your image viewer (xdg-open)
--   q / <Esc>           close
local zoom_cache = vim.fn.stdpath("cache") .. "/diagram-zoom"

local function hires_png(src, cb)
  vim.fn.mkdir(zoom_cache, "p")
  local key = vim.fn.sha256(src .. vim.fn.getftime(src)):sub(1, 12)
  local out = zoom_cache .. "/" .. key .. ".png"
  if vim.fn.filereadable(out) == 1 then
    return cb(out, key)
  end
  local cmd
  if src:match("%.mmd$") then
    local theme = vim.o.background == "light" and "neutral" or "dark"
    cmd = { "mmdc", "-i", src, "-o", out, "-b", "transparent", "-t", theme, "-s", "4", "-p", puppeteer_cfg }
  else
    cmd = { "magick", src .. "[0]", out }
  end
  vim.notify("Rendering diagram…")
  vim.system(cmd, {}, vim.schedule_wrap(function(r)
    if r.code == 0 and vim.fn.filereadable(out) == 1 then
      cb(out, key)
    else
      vim.notify("Could not render image:\n" .. (r.stderr or ""), vim.log.levels.ERROR)
    end
  end))
end

local function open_zoom_viewer(png, key)
  local dims = vim.split(vim.trim(vim.system({ "magick", "identify", "-format", "%w %h", png .. "[0]" }, { text = true }):wait().stdout or ""), " ")
  local W, H = tonumber(dims[1]), tonumber(dims[2])
  if not (W and H) then
    return vim.notify("Could not read image size: " .. png, vim.log.levels.ERROR)
  end
  local state = { z = 1, cx = 0.5, cy = 0.5 }
  local placement ---@type snacks.image.Placement?
  local win ---@type snacks.win

  local function render()
    local cw, ch = math.floor(W / state.z), math.floor(H / state.z)
    local x = math.max(0, math.min(W - cw, math.floor(state.cx * W - cw / 2)))
    local y = math.max(0, math.min(H - ch, math.floor(state.cy * H - ch / 2)))
    state.cx, state.cy = (x + cw / 2) / W, (y + ch / 2) / H -- clamp the view to the image
    local file = png
    if state.z > 1 then
      file = string.format("%s/%s-%dx%d+%d+%d.png", zoom_cache, key, cw, ch, x, y)
      if vim.fn.filereadable(file) == 0 then
        vim.system({ "magick", png, "-crop", string.format("%dx%d+%d+%d", cw, ch, x, y), "+repage", file }):wait()
      end
    end
    if placement then
      placement:close()
    end
    placement = Snacks.image.placement.new(win.buf, file, {
      pos = { 1, 0 },
      inline = false,
      max_width = vim.api.nvim_win_get_width(win.win),
      max_height = vim.api.nvim_win_get_height(win.win),
    })
    win:set_title(string.format(" %d%%  ·  +/- zoom  ·  hjkl pan  ·  0 fit  ·  o open  ·  q close ", state.z * 100), "center")
  end

  local function zoom(f)
    return function()
      state.z = math.max(1, math.min(16, state.z * f))
      render()
    end
  end
  local function pan(dx, dy)
    return function()
      state.cx, state.cy = state.cx + dx / (4 * state.z), state.cy + dy / (4 * state.z)
      render()
    end
  end

  win = Snacks.win({
    position = "float",
    width = 0.95,
    height = 0.9,
    border = "rounded",
    title = " diagram ",
    title_pos = "center",
    enter = true,
    bo = { filetype = "snacks_image_zoom" },
    keys = {
      q = "close",
      ["<Esc>"] = "close",
      ["+"] = zoom(1.5), ["="] = zoom(1.5), ["-"] = zoom(1 / 1.5),
      ["0"] = function() state.z, state.cx, state.cy = 1, 0.5, 0.5; render() end,
      h = pan(-1, 0), l = pan(1, 0), k = pan(0, -1), j = pan(0, 1),
      ["<Left>"] = pan(-1, 0), ["<Right>"] = pan(1, 0), ["<Up>"] = pan(0, -1), ["<Down>"] = pan(0, 1),
      o = function() vim.ui.open(png) end,
    },
    on_close = function()
      if placement then
        placement:close()
      end
    end,
  })
  render()
end

local function zoom_image_at_cursor()
  Snacks.image.doc.at_cursor(function(src)
    if not src then
      return vim.notify("No image or diagram under the cursor", vim.log.levels.WARN)
    end
    hires_png(src, open_zoom_viewer)
  end)
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>cz", zoom_image_at_cursor, ft = "markdown", desc = "Zoom Diagram/Image" },
    },
    opts = {
      image = {
        enabled = true,
        doc = {
          inline = true, -- draw the diagram right under the code block
          max_width = 100,
          max_height = 40,
        },
        convert = {
          -- Ubuntu 23.10+ blocks Chrome's sandbox (AppArmor), so mmdc's headless Chrome
          -- needs --no-sandbox. It only renders your own local diagram text.
          mermaid = function()
            local theme = vim.o.background == "light" and "neutral" or "dark"
            return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "{scale}", "-p", puppeteer_cfg }
          end,
        },
      },
    },
  },
}
