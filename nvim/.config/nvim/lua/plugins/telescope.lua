return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").setup({
      defaults = {
        file_ignore_patterns = {
          "node_modules/",
          "vendor/",
          ".git/",
          "__pycache__/",
          ".venv/",
          "dist/",
          "build/",
          ".terraform/",
          "%.lock",
        },
      },
    })

    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<C-o>", function()
      builtin.find_files({ hidden = true })
    end, { desc = "Open file" })
    vim.keymap.set("n", "<C-f>", builtin.live_grep, { desc = "Search word" })
    vim.keymap.set("n", "<leader><leader>", builtin.oldfiles, { desc = "Recent files" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
  end,
}
