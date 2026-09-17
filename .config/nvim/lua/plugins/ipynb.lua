return {
  {
    "goerz/jupytext.vim",
    lazy = false,
    init = function()
      -- Open .ipynb files formatted as real Markdown (so render-markdown.nvim renders tables/headers/links)
      vim.g.jupytext_fmt = "markdown"
    end,
  },
}
