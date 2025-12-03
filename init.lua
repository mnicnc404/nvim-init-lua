vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.hlsearch = true
vim.opt.updatetime = 500

vim.cmd("autocmd FileType yaml setlocal shiftwidth=2 softtabstop=2 expandtab")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "nvim-lualine/lualine.nvim",       opts = {} },
  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
      require("notify").setup({
        background_colour = "#000000",
        stages = "fade",
        timeout = 3000,
      })
    end
  },
  { "nvim-telescope/telescope.nvim",    dependencies = { "nvim-lua/plenary.nvim" } },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = function() return vim.fn.executable("make") == 1 end,
    config = function() require("telescope").load_extension("fzf") end,
  },
  { "nvim-tree/nvim-tree.lua",          dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },
  { "lewis6991/gitsigns.nvim",          config = true },
  { "tpope/vim-fugitive" },
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim",          build = ":MasonUpdate",                           config = true },
  { "williamboman/mason-lspconfig.nvim" },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      context = {
        include_buffer = true,
        include_filetypes = { "python", "lua", "go", "javascript", "typescript" },
      },
    }
  },
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = { background = "dark" } },
  { "lervag/vimtex" },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  },
  { "ggandor/leap.nvim" },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ruff_fix = {
          prepend_args = { "check", "--extend-select", "I" },
        },
      },
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },
})

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', '<Plug>(leap-forward)')
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>S', '<Plug>(leap-backward)')
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>gs', '<Plug>(leap-from-window)')
vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help" })
vim.keymap.set("n", "<leader>z", "za", { desc = "Toggle fold" })
vim.keymap.set("n", "<leader>fn", "<cmd>Telescope notify<CR>", { desc = "Notification History" })

vim.keymap.set("n", "<leader>dj", function()
  local diags = vim.diagnostic.get(0)
  if #diags > 0 then
    vim.api.nvim_win_set_cursor(0, { diags[1].lnum + 1, diags[1].col })
  end
end, { desc = "Jump to first diagnostic" })

vim.notify = require("notify")

require("gruvbox").setup({
  terminal_colors = true,
  undercurl = true,
  underline = true,
  bold = true,
  italic = {
    strings = true,
    emphasis = true,
    comments = true,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  contrast = "",
  dim_inactive = false,
  transparent_mode = false,
})
vim.cmd("colorscheme gruvbox")

local function conda_env()
  return vim.env.CONDA_DEFAULT_ENV and ("󰢩 " .. vim.env.CONDA_DEFAULT_ENV) or ""
end

local function first_diagnostic_location()
  local diags = vim.diagnostic.get(0)
  if #diags == 0 then return "" end
  table.sort(diags, function(a, b)
    return a.lnum < b.lnum or (a.lnum == b.lnum and a.col < b.col)
  end)
  local first = diags[1]
  return string.format("Ln %d, Col %d", first.lnum + 1, first.col + 1)
end

require("lualine").setup({
  sections = {
    lualine_b = { "branch" },
    lualine_c = { "filename", "diagnostics", first_diagnostic_location },
    lualine_x = { conda_env, "encoding", "fileformat", "filetype" },
  }
})

require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ruff" },
  automatic_enable = { exclude = { "lua_ls" } },
})

local lua_settings = {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
}

if vim.fn.has("nvim-0.11") == 1 then
  vim.lsp.config("lua_ls", lua_settings)
  vim.lsp.enable("lua_ls")
else
  pcall(function()
    require("lspconfig").lua_ls.setup(lua_settings)
  end)
end

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
    prefix = "",
  },
})

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false })
  end
})
