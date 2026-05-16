return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "tpope/vim-surround" },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
      },
    },
  },
}
