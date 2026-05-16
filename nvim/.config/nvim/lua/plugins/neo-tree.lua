return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  lazy = false,
  config = function()
    require("neo-tree").setup({
      window = {
        position = "right",
        width = 35,
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_by_name = {
            "node_modules",
            "vendor",
            ".git",
            "__pycache__",
            ".venv",
            ".terraform",
          },
        },
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
    })

    vim.keymap.set("n", "<C-b>", "<cmd>Neotree toggle<CR>", { desc = "File explorer" })
  end,
}
