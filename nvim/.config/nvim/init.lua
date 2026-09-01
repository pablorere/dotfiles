-- 1. Bootstrap de lazy.nvim (Instalación automática)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Cargar plugins y configurar LuaSnip
require("lazy").setup({
  {
    "L3MON4D3/LuaSnip",
    config = function()
      -- Le indicamos a LuaSnip dónde buscar tus snippets personalizados
      require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/lua/snippets/"})
    end
  },
})

-- 3. Mapear la tecla <Tab> para expandir el snippet
vim.keymap.set({"i", "s"}, "<Tab>", function()
  if require("luasnip").expand_or_jumpable() then
    require("luasnip").expand_or_jump()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end, {silent = true})
require("class_filler")
