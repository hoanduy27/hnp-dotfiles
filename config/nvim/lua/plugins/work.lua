-- Work-machine profile: keep anything that opens a local server, drives a headless browser or
-- sends code to a third-party service out of the config.
--   removed: coder/claudecode.nvim, Browsh web browsing, kevalin/mermaid.nvim, mermaid-cli/Chrome rendering
return {
  -- the markdown extra pulls this in; it builds with npm and serves a local HTTP server
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- inline images/diagrams shell out to mmdc (headless Chrome) and ImageMagick
  { "folke/snacks.nvim", opts = { image = { enabled = false } } },
}
