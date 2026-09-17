return {
  "AstroNvim/astroui",
  ---@type AstroUIConfig
  opts = {
    -- Declare your active colorscheme palette
    colorscheme = "catppuccin-mocha",
    
    -- Change structural UI window border wrappers to thin elegant graphics
    borders = {
      hover = "rounded",
      preview = "rounded",
    },
    
    -- Toggle modern web-dev icon rendering engines
    icons = {
      ActiveLSP = "⚙️",
      FolderOpen = "📂",
      FolderClosed = "📁",
      GitBranch = "🎛️",
    },
  },
}
