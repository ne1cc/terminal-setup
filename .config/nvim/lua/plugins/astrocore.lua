return {
  "AstroNvim/astrocore",
  ---@type AstroCoreConfig
  opts = {
    -- Configure global Vim settings and flags
    options = {
      opt = {
        relativenumber = true, -- Enable relative line numbers for rapid vertical motion
        number = true,         -- Show the precise line number on the active cursor line
        spell = false,         -- Global spellchecking off by default
        signcolumn = "yes",    -- Keep the gutter open to prevent code layouts from shifting left/right
        scrolloff = 8,         -- Lock cursor context by maintaining 8 lines visible below/above screen boundary
      },
      g = {
        mapleader = " ",      -- Map the Leader key to the Spacebar globally
        maplocalleader = ",", -- Map local leader definitions to a comma
      },
    },

    -- Master Mappings Config: Modal keybindings separated by Normal (n), Visual (v), and Terminal (t) modes
    mappings = {
      n = {
        -- Quickly manage and step through open buffers in your top bar
        ["L"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next Buffer" },
        ["H"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous Buffer" },

        -- Custom horizontal/vertical splitting mappings that load the active buffer directly
        ["<leader>sh"] = { ":split<cr>", desc = "Horizontal split" },
        ["<leader>sv"] = { ":vsplit<cr>", desc = "Vertical split" },

        -- nvim-only window focus (never jumps to tmux panes)
        ["<C-Up>"] = { "<C-w>k", desc = "Focus Window Above" },
        ["<C-Down>"] = { "<C-w>j", desc = "Focus Window Below" },
        ["<C-Left>"] = { "<C-w>h", desc = "Focus Window Left" },
        ["<C-Right>"] = { "<C-w>l", desc = "Focus Window Right" },
      },
    },

    treesitter = {
      auto_install = true,
      ensure_installed = {
        "bash",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "mermaid",
        "python",
        "toml",
        "vim",
        "yaml",
      },
    },
  },
}
