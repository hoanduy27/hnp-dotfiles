-- Keymaps are automatically loaded on the VeryLazy event
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- Your VS Code bindings and where they went:
--   alt+left / alt+right        -> same keys (jump back / forward)
--   ctrl+k h/j/k/l (pane focus) -> ctrl+h/j/k/l (LazyVim default, no chord needed),
--                                  but j/k are swapped: ctrl+k = down, ctrl+j = up (your preference;
--                                  same in pickers, completion menu, terminals and lazygit)
--   ctrl+shift+alt+k/j (resize) -> ctrl+up/down, ctrl+left/right (LazyVim default)
--   ctrl+l (clear terminal)     -> works as-is in the built-in terminal (shell handles it)
--   ctrl+shift+p / ctrl+`       -> terminals can't send these reliably: use <leader>sC (commands)
--                                  and ctrl+/ (terminal)

local map = vim.keymap.set

-- ctrl+k = lower window, ctrl+j = upper window (LazyVim default is the other way round)
map("n", "<C-k>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-j>", "<C-w>k", { desc = "Go to Upper Window", remap = true })

-- workbench.action.navigateBack / navigateForward
map("n", "<A-Left>", "<C-o>", { desc = "Navigate Back" })
map("n", "<A-Right>", "<C-i>", { desc = "Navigate Forward" })

-- A few VS Code muscle-memory shortcuts
map("n", "<C-p>", function() Snacks.picker.files() end, { desc = "Quick Open (files)" })
map("n", "<F2>", function() return ":IncRename " .. vim.fn.expand("<cword>") end, { expr = true, desc = "Rename Symbol" })
map("n", "<F12>", function() Snacks.picker.lsp_definitions() end, { desc = "Go to Definition" })
map("n", "<C-b>", "<cmd>Neotree toggle<cr>", { desc = "Toggle Sidebar (file tree)" })

-- ctrl+backspace / ctrl+delete: delete word left / right while typing.
-- ctrl+left/right already move by word in insert mode (built in).
-- Some terminals send ctrl+backspace as <C-h>, so map both. "_ keeps the clipboard intact.
map("i", "<C-BS>", "<C-w>", { desc = "Delete Word Left" })
map("i", "<C-h>", "<C-w>", { desc = "Delete Word Left" })
map("i", "<C-Del>", '<C-o>"_dw', { desc = "Delete Word Right" })
