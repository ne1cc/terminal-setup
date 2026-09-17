-- ftplugin for mermaid and mmd files
local opts = { silent = true, buffer = true }
local map = vim.keymap.set

-- Browser preview for mermaid
map("n", "<leader>mp", function()
  vim.cmd("MarkdownPreviewToggle")
end, vim.tbl_extend("force", opts, { desc = "Mermaid browser preview" }))

-- Diagram hover preview (clean floating window at cursor)
map("n", "<leader>md", function()
  require("diagram").show_diagram_hover()
end, vim.tbl_extend("force", opts, { desc = "Show diagram hover preview" }))

-- Toggle in-buffer rendering (opaque background)
map("n", "<leader>mb", function()
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
end, vim.tbl_extend("force", opts, { desc = "Toggle diagram in-buffer" }))

-- Clear image overlays
map("n", "<leader>ic", function()
  if pcall(require, "image") then
    require("image").clear()
  end
  if pcall(require, "diagram") then
    require("diagram").clear()
  end
  local clear_seq = "\x1b_Ga=d,d=A\x1b\\"
  if vim.env.TMUX then
    clear_seq = "\x1bPtmux;\x1b\x1b_Ga=d,d=A\x1b\x1b\\\x1b\\"
  end
  io.stdout:write(clear_seq)
  io.stdout:flush()
  vim.cmd("redraw!")
  vim.notify("Cleared all image and diagram overlays", vim.log.levels.INFO, { title = "Image Overlays" })
end, vim.tbl_extend("force", opts, { desc = "Clear image overlays" }))
