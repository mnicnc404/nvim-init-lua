vim.g.mapleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = false -- absolute lines only
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

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require("lazy").setup({
  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Statusline
  { "nvim-lualine/lualine.nvim",       opts = {} },

  -- notify
  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")   -- 👈 Redirect all :lua vim.notify(...) calls
      require("notify").setup({
        background_colour = "#000000", -- avoids transparency glitches
        stages = "fade",               -- or "slide", "fade_in_slide_out"
        timeout = 3000,                -- auto close after 3 seconds
      })
    end
  },

  -- Telescope + FZF
  { "nvim-telescope/telescope.nvim",    dependencies = { "nvim-lua/plenary.nvim" } },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = function() return vim.fn.executable("make") == 1 end,
    config = function() require("telescope").load_extension("fzf") end,
  },

  -- File explorer
  { "nvim-tree/nvim-tree.lua",          dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },

  -- Git
  { "lewis6991/gitsigns.nvim",          config = true },
  { "tpope/vim-fugitive" },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim",          build = ":MasonUpdate",                           config = true },
  { "williamboman/mason-lspconfig.nvim" },

  -- Copilot
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {}
  },

  -- Colorscheme
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = { background = "dark" } },

  -- VimTeX
  { "lervag/vimtex" },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  },

  -- Motion
  { "ggandor/leap.nvim" },

  -- flake8 linting
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "flake8" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        callback = function() lint.try_lint() end,
      })
    end
  },

  -- isort formatting (on save)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "isort" }, -- Only isort, no black
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },

  -- Auto activate Conda envs if available
  {
    "linux-cultist/venv-selector.nvim",
    cond = function()
      return vim.fn.executable("conda") == 1
    end,
    opts = {
      auto_refresh = true,
      anaconda_base_path = os.getenv("CONDA_PREFIX") or "",
      name = { ".venv", "env", "venv" },
    },
    cmd = "VenvSelect",
    keys = {
      { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },
})

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', '<Plug>(leap-forward)')
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>S', '<Plug>(leap-backward)')
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>gs', '<Plug>(leap-from-window)')
vim.notify = require("notify")

-- Color scheme
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

-- Lualine
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
    lualine_c = {
      "filename",
      first_diagnostic_location, -- 👈 shows Ln/Col of first diagnostic
    },
    lualine_x = {
      conda_env,     -- 👈 shows current conda env
      "diagnostics", -- shows E/W count
      "encoding",
      "fileformat",
      "filetype",
    },
  }
})

vim.keymap.set("n", "<leader>dj", function()
  local diags = vim.diagnostic.get(0)
  if #diags > 0 then
    vim.api.nvim_win_set_cursor(0, { diags[1].lnum + 1, diags[1].col })
  end
end, { desc = "Jump to first diagnostic" })

-- Setup Mason + LSPs
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "pyright" },
  automatic_installation = true,
})

-- Setup all LSPs with default config
local lspconfig = require("lspconfig")
require("mason-lspconfig").setup_handlers({
  function(server_name)
    if server_name == "lua_ls" then
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT", -- Neovim uses LuaJIT
            },
            diagnostics = {
              globals = { "vim" }, -- Recognize `vim` as a global
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true), -- Make LSP aware of Neovim runtime files
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
    else
      lspconfig[server_name].setup({})
    end
  end,
})

-- Keymaps
vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help" })
vim.keymap.set("n", "<leader>z", "za", { desc = "Toggle fold" })

-- Global diagnostic config
vim.diagnostic.config({
  virtual_text = false,     -- Disable inline text
  signs = true,             -- Show signs in gutter
  underline = true,         -- Underline diagnostics in code
  update_in_insert = false, -- Don't show diagnostics while typing
  severity_sort = true,     -- Sort by severity
  float = {
    border = "rounded",
    source = true,
    prefix = "", -- No symbol prefix
  },
})

vim.api.nvim_set_hl(0, "Flake8Error", { fg = "#ff6c6b", bg = "NONE" })
vim.api.nvim_set_hl(0, "Flake8Warn", { fg = "#ECBE7B", bg = "NONE" })
vim.api.nvim_set_hl(0, "Flake8Hint", { fg = "#ffffff", bg = "NONE" })

-- Show diagnostic popup on CursorHold (respects global float config)
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false })
  end
})

-- Echo current line's first diagnostic in the command area on CursorMoved
vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    local function echo_clean_message(message, code_str, hl)
      local win_width = vim.api.nvim_win_get_width(0)
      local full_msg = (message or ""):gsub("\n", ";") .. code_str
      if #full_msg > win_width - 1 then
        full_msg = full_msg:sub(1, win_width - 15) .. "..."
      end
      vim.api.nvim_echo({ { full_msg, hl } }, false, {})
    end

    local line = vim.fn.line(".") - 1
    local diagnostics = vim.diagnostic.get(0, { lnum = line })

    local fallback = nil

    for _, d in ipairs(diagnostics) do
      if d.source == "flake8" then
        local code = d.code or ""
        local hl = "Normal"

        if code:match("^F") or code:match("^E") then
          hl = "Flake8Error"
        elseif code:match("^[WBCNS]") then
          hl = "Flake8Warn"
        elseif code:match("^[DQA]") then
          hl = "Flake8Hint"
        end

        local code_str = code ~= "" and (" [" .. code .. "]") or ""
        echo_clean_message(d.message, code_str, hl)
        return
      elseif not fallback then
        fallback = d
      end
    end

    if fallback then
      local hl = ({
        [vim.diagnostic.severity.ERROR] = "Flake8Error",
        [vim.diagnostic.severity.WARN]  = "Flake8Warn",
        [vim.diagnostic.severity.INFO]  = "Flake8Hint",
        [vim.diagnostic.severity.HINT]  = "Flake8Hint",
      })[fallback.severity] or "Normal"

      local code_str = fallback.code and (" [" .. fallback.code .. "]") or ""
      echo_clean_message(fallback.message, code_str, hl)
    else
      vim.api.nvim_echo({}, false, {})
    end
  end
})
