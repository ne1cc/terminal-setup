return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "vimwiki" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    opts = {
      enabled = true,
      render_modes = { "n", "c", "t" },
      file_types = { "markdown", "vimwiki" },
      anti_conceal = {
        enabled = true,
        ignore = {
          code_background = true,
          sign = true,
          table_border = true,
        },
      },
      win_options = {
        conceallevel = { default = 0, rendered = 2 },
        concealcursor = { default = "", rendered = "nc" },
      },
      heading = {
        enabled = true,
        sign = true,
        position = "overlay",
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      code = {
        enabled = true,
        sign = false,
        style = "full",
        position = "left",
        width = "full",
        left_pad = 2,
        right_pad = 2,
      },
      dash = { enabled = true, icon = "─", width = "full" },
      bullet = {
        enabled = true,
        icons = { "●", "○", "◆", "◇" },
      },
      checkbox = {
        enabled = true,
        position = "inline",
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      pipe_table = {
        enabled = true,
        style = "full",
        cell = "trimmed",
        alignment_indicator = "━",
        border = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
      },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
      },
      link = {
        enabled = true,
        image = "󰥶 ",
        hyperlink = "󰌹 ",
        custom = {
          web = { pattern = "^http", icon = "󰖟 " },
          file = { pattern = "^file:", icon = "󰈙 " },
        },
      },
      sign = { enabled = true },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("render_markdown_conceal", { clear = true }),
        pattern = { "markdown", "markdown.mdx", "vimwiki" },
        callback = function()
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = "nc"
        end,
      })
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown", "vimwiki", "mermaid", "mmd" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>mv", "<cmd>MarkdownPreviewToggle<cr>", desc = "Mermaid browser preview", ft = { "markdown", "vimwiki", "mermaid", "mmd" } },
      { "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown browser preview", ft = { "markdown", "vimwiki" } },
    },
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {},
      }
    end,
  },

  {
    "mracos/mermaid.vim",
    ft = { "mermaid", "mmd" },
  },
}
