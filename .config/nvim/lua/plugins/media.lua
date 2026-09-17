local function paste_image_key()
  require("media_paste").paste()
end

return {
  {
    "3rd/image.nvim",
    ft = { "markdown", "vimwiki" },
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_height_window_percentage = 50,
      editor_only_render_when_focused = true,
      tmux_show_only_in_active_window = true,
      window_overlap_clear_enabled = true,
    },
  },

  {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown", "vimwiki" },
    opts = {
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        file_name = "%Y-%m-%d-%H-%M-%S",
        dir_path = "assets",
        drag_and_drop = {
          enabled = true,
          insert_mode = true,
          download_images = true,
        },
        use_absolute_path = true,
        relative_path = "./assets",
        template = "![$FILE_NAME]($FILE_PATH)",
      },
    },
    keys = {
      {
        "<leader>ip",
        paste_image_key,
        desc = "Paste image from clipboard",
        ft = { "markdown", "vimwiki" },
      },
      {
        "<leader>pp",
        paste_image_key,
        desc = "Paste image from clipboard",
        ft = { "markdown", "vimwiki" },
      },
    },
    config = function(_, opts)
      require("img-clip").setup(opts)

      vim.api.nvim_create_user_command("PasteImage", paste_image_key, {})

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("MediaSmartPaste", { clear = true }),
        pattern = { "markdown", "vimwiki" },
        callback = function(event)
          vim.keymap.set("n", "p", function()
            require("media_paste").smart_paste()
          end, { buffer = event.buf, desc = "Paste text or image" })
        end,
      })
    end,
  },
}
