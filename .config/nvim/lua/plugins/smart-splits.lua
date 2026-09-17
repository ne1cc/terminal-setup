-- tmux pane + nvim split navigation (pairs with .tmux.conf C-h/j/k/l bindings)
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    multiplexer_integration = "tmux",
    at_edge = "stop",
    disable_multiplexer_nav_when_zoomed = true,
    -- neo-tree is a normal split — must NOT be ignored
    ignored_filetypes = { "nofile", "quickfix", "qf", "prompt" },
    ignored_buftypes = { "nofile" },
  },
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Focus left split/pane" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Focus below split/pane" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Focus above split/pane" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Focus right split/pane" },
    { "<C-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Focus previous split/pane" },
  },
}
