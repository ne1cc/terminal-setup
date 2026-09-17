return {
  {
    "3rd/diagram.nvim",
    dependencies = {
      "3rd/image.nvim",
    },
    ft = { "markdown", "vimwiki", "mermaid", "mmd" },
    opts = {
      renderer_options = {
        mermaid = {
          background = "#1a1b26", -- Opaque matching terminal to prevent code text bleed-through
          theme = "dark",
          scale = 1.2,
        },
        plantuml = {
          charset = "utf-8",
        },
        d2 = {
          theme_id = 200,
        },
      },
      events = {
        -- Do not auto-render in-buffer on open to prevent collisions with code text;
        -- use <leader>md (hover preview) or <leader>mb (toggle in-buffer)
        render_buffer = {},
        clear_buffer = { "BufLeave", "BufWinLeave", "FocusLost" },
      },
    },
    keys = {
      {
        "<leader>md",
        function()
          require("diagram").show_diagram_hover()
        end,
        desc = "Show diagram at cursor (hover window)",
        ft = { "markdown", "vimwiki", "mermaid", "mmd" },
      },
      {
        "<leader>mb",
        function()
          local diag = require("diagram")
          if _G._diagram_in_buffer_rendered then
            diag.clear()
            _G._diagram_in_buffer_rendered = false
            vim.notify("Diagram in-buffer cleared", vim.log.levels.INFO, { title = "Diagram" })
          else
            diag.render()
            _G._diagram_in_buffer_rendered = true
            vim.notify("Diagram rendered in-buffer", vim.log.levels.INFO, { title = "Diagram" })
          end
        end,
        desc = "Toggle diagram in-buffer rendering",
        ft = { "markdown", "vimwiki", "mermaid", "mmd" },
      },
    },
  },
}
