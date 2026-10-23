-- Work-machine profile: keep anything that opens a local server, drives a headless browser or
-- sends code to a third-party service out of the config.
--   removed: coder/claudecode.nvim, Browsh web browsing, kevalin/mermaid.nvim, mermaid-cli/Chrome rendering
return {
  -- the markdown extra pulls this in; it builds with npm and serves a local HTTP server
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- inline images/diagrams shell out to mmdc (headless Chrome) and ImageMagick
  { "folke/snacks.nvim", opts = { image = { enabled = false } } },

  -- Pin the Mason registry: every package version Mason resolves (our list in 23-nvim-bootstrap.sh
  -- and whatever LazyVim extras request) comes from this snapshot instead of "latest".
  -- To bump: use a newer tag from https://github.com/mason-org/mason-registry/releases
  {
    "mason-org/mason.nvim",
    opts = { registries = { "github:mason-org/mason-registry@2026-10-23-joint-wallet" } },
  },
}
