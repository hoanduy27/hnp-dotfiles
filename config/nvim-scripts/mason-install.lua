-- Headless helper for 05-bootstrap-plugins.sh:
--   MASON_PKGS="a b c" nvim --headless "+Lazy! load mason.nvim" "+luafile mason-install.lua"
-- Installs the given packages and waits until every Mason install (including ones LazyVim
-- started on its own) has finished, so nothing is aborted when nvim exits.
local registry = require("mason-registry")
local wanted = vim.split(vim.env.MASON_PKGS or "", "%s+", { trimempty = true })
local failed = {}

local function busy()
  for _, pkg in ipairs(registry.get_all_packages()) do
    if pkg:is_installing() then
      return true
    end
  end
  return false
end

local refreshed = false
registry.refresh(function() refreshed = true end)
vim.wait(60000, function() return refreshed end, 200)

for _, name in ipairs(wanted) do
  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    table.insert(failed, name .. " (unknown package)")
  elseif not pkg:is_installed() and not pkg:is_installing() then
    io.stdout:write("installing " .. name .. "\n")
    pkg:install({}, function(success)
      if not success then table.insert(failed, name) end
    end)
  end
end

vim.wait(20 * 60 * 1000, function() return not busy() end, 1000)

if #failed > 0 then
  io.stdout:write("FAILED: " .. table.concat(failed, ", ") .. "\n")
  vim.cmd("cq")
end
io.stdout:write("mason: all packages installed\n")
vim.cmd("qa!")
