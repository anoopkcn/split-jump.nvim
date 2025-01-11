if vim.g.loaded_split_jump then
  return
end
vim.g.loaded_split_jump = true

require("split-jump").setup()
