-- Audio preview (logic in lua/config/audio.lua): opening audio files, the file picker
-- preview, and <M-a> to play from the picker / neo-tree.
local function audio()
  return require("config.audio")
end

-- picker preview: audio info for audio files, the normal file preview otherwise
local function preview(ctx)
  local path = ctx.item and (ctx.item.file and Snacks.picker.util.path(ctx.item))
  if path and audio().is_audio(path) then
    ctx.preview:reset()
    local lines = { "  󰎈 " .. vim.fn.fnamemodify(path, ":t"), "" }
    vim.list_extend(lines, audio().info_lines(path))
    vim.list_extend(lines, { "", "  <M-a> play · <CR> open (waveform + spectrogram)" })
    ctx.preview:set_lines(lines)
    ctx.preview:set_title(vim.fn.fnamemodify(path, ":t"))
    return
  end
  return Snacks.picker.preview.file(ctx)
end

local play_key = { "audio_play", mode = { "n", "i" } }
local file_sources = {}
for _, name in ipairs({ "files", "smart", "recent", "git_files", "buffers" }) do
  file_sources[name] = { preview = preview }
end

return {
  -- own (virtual) spec: an `init` on the shared snacks spec would replace other files' inits
  {
    "user/audio-preview",
    virtual = true,
    lazy = false,
    init = function()
      audio().setup() -- early, so `nvim song.wav` is caught by the BufReadCmd
    end,
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = file_sources,
        actions = {
          audio_play = function(_, item)
            local path = item and item.file and Snacks.picker.util.path(item)
            if path and audio().is_audio(path) then
              audio().play(path, 0)
            else
              vim.notify("Not an audio file", vim.log.levels.WARN)
            end
          end,
        },
        win = {
          input = { keys = { ["<a-a>"] = play_key } },
          list = { keys = { ["<a-a>"] = play_key } },
        },
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        mappings = {
          ["<M-a>"] = {
            function(state)
              local node = state.tree:get_node()
              if node and audio().is_audio(node.path) then
                audio().play(node.path, 0)
              end
            end,
            desc = "play audio",
          },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>m", group = "audio", icon = "󰎈" } } },
  },
}
