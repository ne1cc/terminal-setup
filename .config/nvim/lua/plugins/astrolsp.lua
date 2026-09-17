return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPConfig
  opts = {
    -- Control whether diagnostic messages update actively while you type in insert mode
    diagnostics = {
      update_in_insert = false, -- Prevent visual noise by waiting until you exit insert mode to lint
      virtual_text = true,      -- Render warnings inline at the end of the line
    },
    
    -- Automatic on-save configurations
    formatting = {
      format_on_save = {
        enabled = true,         -- Run auto-formatters instantly whenever you save a file
        allow_filetypes = {     -- Limit auto-formatting strictly to these target environments
          "lua",
          "dart",
          "cpp",
          "html",
        },
      },
      timeout_ms = 2000,        -- Prevent slow language servers from blocking your editing UI thread
    },
    
    -- Register language servers to configure automatically upon project initialization
    servers = {
      -- "lua_ls", "dartls", etc. Left empty to allow Mason to manage baseline server capabilities dynamically
    },
  },
}
