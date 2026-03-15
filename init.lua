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
vim.opt.updatetime = 250

vim.g.codecompanion_selected_adapter = vim.g.codecompanion_selected_adapter or "codex"

vim.cmd("autocmd FileType yaml setlocal shiftwidth=2 softtabstop=2 expandtab")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  { "nvim-lualine/lualine.nvim",     opts = {} },
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
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
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
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        use_absolute_path = true,
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown", "codecompanion" },
    },
    ft = { "markdown", "codecompanion" },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
      "franco-ruggeri/codecompanion-spinner.nvim",
    },
    opts = {
      opts = {
        log_level = "TRACE",
      },
      display = {
        chat = {
          window = {
            position = "right",
            width = 0.4,
          },
        },
      },
      adapters = {
        acp = {
          gemini_cli = function()
            return require("codecompanion.adapters").extend("gemini_cli", {
              commands = {
                default = {
                  "gemini",
                  "--experimental-acp",
                  "--approval-mode",
                  "yolo",
                  "--model",
                  "gemini-3.1-pro-preview",
                },
              },
              defaults = {
                timeout = 40000,
              },
            })
          end,
          codex = function()
            return require("codecompanion.adapters").extend("codex", {
              defaults = {
                auth_method = "chatgpt",
                timeout = 20000,
              },
              commands = {
                default = { "codex-acp" },
              },
            })
          end,
        },
      },
      strategies = {
        chat = { adapter = vim.g.codecompanion_selected_adapter },
        agent = { adapter = vim.g.codecompanion_selected_adapter },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "gh",
            save_chat_keymap = "sc",
            auto_save = true,
            auto_generate_title = false,
          },
        },
        spinner = {},
      },
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
      pcall(function()
        require("config.codecompanion_async_acp").apply()
      end)
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<Tab>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
        ignore_filetypes = {},
        color = {
          suggestion_color = "#888888",
          cterm = 244,
        }
      })
    end,
  },
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = { background = "dark" } },
  { "lervag/vimtex" },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  },
  {
    "https://codeberg.org/andyg/leap.nvim",
    keys = {
      { "s",  mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "S",  mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "gs", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
    },
    config = function()
      require("leap").add_default_mappings(true)
    end,
  },
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

local function set_codecompanion_adapter(adapter, label)
  vim.g.codecompanion_selected_adapter = adapter

  local lazy_ok, lazy = pcall(require, "lazy")
  if lazy_ok then
    lazy.load({ plugins = { "codecompanion.nvim" } })
  end

  local config_ok, config = pcall(require, "codecompanion.config")
  if config_ok and config.interactions then
    if config.interactions.chat then
      config.interactions.chat.adapter = adapter
    end
    if config.interactions.inline then
      config.interactions.inline.adapter = adapter
    end
  end

  local cc_ok, codecompanion = pcall(require, "codecompanion")
  if cc_ok then
    local chat = codecompanion.last_chat()
    if chat and chat.adapter and chat.adapter.name ~= adapter then
      chat.acp_connection = nil
      chat:change_adapter(adapter)
    end
  end

  vim.notify("CodeCompanion adapter -> " .. label)
end

vim.api.nvim_create_user_command("CCCodex", function()
  set_codecompanion_adapter("codex", "Codex")
end, {})

vim.api.nvim_create_user_command("CCGemini", function()
  set_codecompanion_adapter("gemini_cli", "Gemini CLI")
end, {})

vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>CodeCompanionActions<CR>",
  { noremap = true, silent = true, desc = "CodeCompanion Actions Palette" })
vim.keymap.set({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionChat Toggle<CR>",
  { noremap = true, silent = true, desc = "Toggle CodeCompanion Chat" })
vim.keymap.set("v", "<leader>cd", "<cmd>CodeCompanionChat Add<CR>",
  { noremap = true, silent = true, desc = "Add selection to CodeCompanion Chat" })
vim.keymap.set("n", "<leader>ci", "<cmd>CodeCompanion<CR>",
  { noremap = true, silent = true, desc = "CodeCompanion Inline Assistant" })
vim.keymap.set("n", "<leader>ch", "<cmd>CodeCompanionHistory<CR>",
  { noremap = true, silent = true, desc = "CodeCompanion Chat History" })
vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>CodeCompanionActions<CR>",
  { noremap = true, silent = true, desc = "CodeCompanion Actions Palette" })
vim.cmd([[cab cc CodeCompanion]])

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

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

local codecompanion_frames = {
  "⠋⠀", "⠉⠁", "⠈⠉", "⠀⠙", "⠀⠸", "⠀⠴", "⠠⠤", "⠤⠄", "⠦⠀", "⠇⠀"
}
local codecompanion_state = {}
local CodeCompanionStatus = require("lualine.component"):extend()

local function is_codecompanion()
  return vim.bo.filetype == "codecompanion"
end

local function codecompanion_meta(bufnr)
  local all_meta = rawget(_G, "codecompanion_chat_metadata")
  return all_meta and all_meta[bufnr] or nil
end

local function codecompanion_label()
  local meta = codecompanion_meta(vim.api.nvim_get_current_buf())
  if not meta or not meta.adapter then
    return "CodeCompanion"
  end

  if meta.mode and meta.mode.name then
    return string.format("%s %s", meta.adapter.name, meta.mode.name)
  end

  if meta.adapter.model and meta.adapter.model ~= "" then
    return string.format("%s %s", meta.adapter.name, meta.adapter.model)
  end

  return meta.adapter.name
end

function CodeCompanionStatus:init(options)
  CodeCompanionStatus.super.init(self, options)

  if vim.g.codecompanion_lualine_loaded then
    return
  end
  vim.g.codecompanion_lualine_loaded = true

  local group = vim.api.nvim_create_augroup("CodeCompanionLualine", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = {
      "CodeCompanionRequestStarted",
      "CodeCompanionRequestStreaming",
      "CodeCompanionRequestFinished",
      "CodeCompanionToolsStarted",
      "CodeCompanionToolsFinished",
    },
    callback = function(args)
      local bufnr = args.data and args.data.bufnr
      if not bufnr then
        return
      end

      local state = codecompanion_state[bufnr] or { frame = 1 }

      if args.match == "CodeCompanionRequestStarted" then
        state.phase = "waiting"
      elseif args.match == "CodeCompanionRequestStreaming" then
        state.phase = "streaming"
      elseif args.match == "CodeCompanionToolsStarted" then
        state.phase = "tools"
      else
        state.phase = nil
      end

      codecompanion_state[bufnr] = state
      require("lualine").refresh({ scope = "window", place = { "statusline" } })
    end,
  })
end

function CodeCompanionStatus:update_status()
  if not is_codecompanion() then
    return nil
  end

  local state = codecompanion_state[vim.api.nvim_get_current_buf()]
  if not state or not state.phase then
    return nil
  end

  state.frame = (state.frame % #codecompanion_frames) + 1
  return codecompanion_frames[state.frame]
end

require("lualine").setup({
  options = {
    refresh = {
      statusline = 100,
      tabline = 1000,
      winbar = 1000,
      refresh_time = 16,
    },
  },
  sections = {
    lualine_b = { "branch" },
    lualine_c = {
      { codecompanion_label, cond = is_codecompanion },
      { "filename",          cond = function() return not is_codecompanion() end },
      { CodeCompanionStatus, cond = is_codecompanion,                            color = { fg = "#fabd2f" } },
      "diagnostics",
      first_diagnostic_location,
    },
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
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false })
  end
})
