return {
  {
    "declancm/maximize.nvim",
    keys = {
      {
        "<leader>wm",
        function()
          require("maximize").toggle()
        end,
        desc = "Maximize / restore window",
      },
      {
        "<leader>z",
        function()
          require("maximize").toggle()
        end,
        desc = "Maximize / zoom window",
      },
    },
    opts = {},
  },
}
