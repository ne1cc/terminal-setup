return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    init = function()
      -- Let terminal blur/transparency show through instead of Neovim-owned alpha
      vim.opt.pumblend = 0
      vim.opt.winblend = 0
    end,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = {
        transparent = true,
        solid = false,
      },
      term_colors = true,
      custom_highlights = function(colors)
        return {
          Normal = { bg = "NONE" },
          NormalNC = { bg = "NONE" },
          NormalFloat = { bg = "NONE" },
          FloatBorder = { bg = "NONE", fg = colors.blue },
          FloatTitle = { bg = "NONE", fg = colors.lavender },
          WinSeparator = { bg = "NONE", fg = colors.surface1 },
          SignColumn = { bg = "NONE" },
          LineNr = { fg = colors.surface2 },
          CursorLineNr = { fg = colors.sapphire, bold = true },
          EndOfBuffer = { bg = "NONE" },
          NeoTreeNormal = { bg = "NONE" },
          NeoTreeNormalNC = { bg = "NONE" },
          NeoTreeEndOfBuffer = { bg = "NONE" },
          NeoTreeWinSeparator = { bg = "NONE", fg = colors.surface1 },
          TelescopeNormal = { bg = "NONE" },
          TelescopeBorder = { bg = "NONE", fg = colors.blue },
          DiagnosticVirtualTextError = { bg = "NONE" },
          DiagnosticVirtualTextWarn = { bg = "NONE" },
          DiagnosticVirtualTextInfo = { bg = "NONE" },
          DiagnosticVirtualTextHint = { bg = "NONE" },
        }
      end,
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        gitsigns = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        mini = true,
        native_lsp = { enabled = true },
        navic = { enabled = true, custom_bg = "NONE" },
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
}
