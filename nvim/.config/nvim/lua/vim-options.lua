-- Logging
local log_dir = vim.fn.stdpath("log")
vim.fn.mkdir(log_dir, "p")
vim.opt.verbosefile = log_dir .. "/nvim.log"

-- Rotate log: truncate if > 5MB
local log_path = log_dir .. "/nvim.log"
local stat = vim.uv.fs_stat(log_path)
if stat and stat.size > 5 * 1024 * 1024 then
  local f = io.open(log_path, "w")
  if f then f:close() end
end

-- Core vim options
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.colorcolumn = "80"
vim.opt.cursorline = true

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Toggle terminal at bottom
vim.keymap.set("n", "<C-j>", function()
  local term_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" then
      term_buf = buf
      break
    end
  end
  -- Check if terminal is already visible in a window
  if term_buf then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        vim.api.nvim_win_close(win, true)
        return
      end
    end
    vim.cmd("botright split")
    vim.api.nvim_win_set_height(0, 15)
    vim.api.nvim_win_set_buf(0, term_buf)
    vim.cmd("startinsert")
    return
  end
  vim.cmd("botright split | resize 15 | terminal")
  vim.cmd("startinsert")
end, { desc = "Toggle terminal" })

-- Escape terminal mode
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><cmd>hide<CR>", { desc = "Hide terminal" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Save/quit shortcuts
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>Q", "<cmd>q!<CR>", { desc = "Force quit" })
vim.keymap.set("n", "<leader>x", "<cmd>x<CR>", { desc = "Save and quit" })

-- Clear search highlight
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")

-- Filetype associations for DevOps
vim.filetype.add({
  filename = {
    [".env"] = "sh",
    [".env.local"] = "sh",
    [".env.example"] = "sh",
    ["Jenkinsfile"] = "groovy",
    ["Tiltfile"] = "starlark",
  },
  pattern = {
    ["%.env%..*"] = "sh",
    [".*/.ssh/config"] = "sshconfig",
    [".*/.kube/config"] = "yaml",
    [".*values.*%.yaml"] = "helm",
    [".*templates/.*%.yaml"] = "helm",
  },
})
