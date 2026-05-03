-- =============================================================================
--  SHEOL // init.lua
--  Minimal Neovim entry point. Loads the sheol colorscheme.
--  Users with existing nvim configs: just copy colors/sheol.vim to their
--  own ~/.config/nvim/colors/ and run :colorscheme sheol
-- =============================================================================

vim.opt.termguicolors = true
vim.opt.background = 'dark'

-- Sensible defaults — feel free to remove if you have your own config
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

-- Load the sheol colorscheme
vim.cmd('colorscheme sheol')
