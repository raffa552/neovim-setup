local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "nvim-tree/nvim-tree.lua" },
  { "nvim-tree/nvim-web-devicons" },
  { "akinsho/bufferline.nvim", dependencies = "nvim-tree/nvim-web-devicons" },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-buffer" },
  { "nvim-neotest/nvim-nio" },
  { "folke/noice.nvim", event = "VeryLazy", dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify", }, config = function()     require("noice").setup({ cmdline = { enabled = true, view = "cmdline", }, }) end, },
  { "L3MON4D3/LuaSnip" },
  { "echasnovski/mini.icons" },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000},
  { "mfussenegger/nvim-dap" },
  { "mfussenegger/nvim-dap-python" },
  { "goolord/alpha-nvim", lazy = false, priority = 900, config = function() require("alpha").setup(require("alpha.themes.startify").config) end },
  { "nvim-telescope/telescope-dap.nvim" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap" } },
  { "akinsho/toggleterm.nvim", version = "*", config = true },
  { "folke/which-key.nvim", config = true },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } }
})

vim.opt.termguicolors = true

require("bufferline").setup {}

vim.notify = function(msg, log_level, _opts)
  if msg:match("which%-key") then
    return
  end
  vim.api.nvim_echo({ { msg, "None" } }, true, {})
end

require("nvim-tree").setup {
  view = {
    float = {
      enable = true,
      open_win_config = function()
        local screen_height = vim.o.lines
        return {
          relative = "editor",
          width = vim.o.columns,
          height = 3,
          row = screen_height - 3,
          col = 0,
          border = "rounded"
        }
      end,
    },
  }
}


require("toggleterm").setup {
  open_mapping = [[<C-t>]],
  direction = "float"
}


require("lspconfig").pyright.setup {}


local cmp = require("cmp")
cmp.setup({
  mapping = {
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" }
  }
})


local luasnip = require("luasnip")


local dap, dapui = require("dap"), require("dapui")
dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

require("dap-python").setup("python")

local wk = require("which-key")
wk.setup { ignore_missing = true }
wk.register({
  ["<leader><Left>"] = { "<cmd>BufferLineCyclePrev<cr>", "Previous Buffer" },
  ["<leader><Right>"] = { "<cmd>BufferLineCycleNext<cr>", "Next Buffer" },
  ["<leader>d"] = { name = "Debug" },
  ["<leader>dB"] = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
  ["<leader>dc"] = { "<cmd>lua require'dap'.continue()<cr>", "Start Debugging" },
  ["<leader>di"] = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
  ["<leader>do"] = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
  ["<leader>dt"] = { "<cmd>lua require'dap'.terminate()<cr>", "Stop Debugging" },
  ["<leader>du"] = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
  ["<leader>dv"] = { "<cmd>lua require('dapui').toggle()<cr>", "Toggle Debug UI" },
  ["<leader>e"] = { "<cmd>NvimTreeToggle<cr>", "File Explorer" },
  ["<leader>t"] = { "<cmd>ToggleTerm<cr>", "Terminal" }
})

local function open_main_menu()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local menu_options = {
    { name = "File Explorer", cmd = "NvimTreeToggle" },
    { name = "Terminal", cmd = "ToggleTerm" },
    { name = "Debug: Toggle Breakpoint", cmd = "DapToggleBreakpoint" },
    { name = "Debug: Start Debugging", cmd = "lua require('dap').continue()" },
    { name = "Debug: Step Over", cmd = "lua require('dap').step_over()" },
    { name = "Debug: Step Into", cmd = "lua require('dap').step_into()" },
    { name = "Debug: Step Out", cmd = "lua require('dap').step_out()" },
    { name = "Debug: Stop Debugging", cmd = "lua require('dap').terminate()" },
    { name = "Debug: Open UI", cmd = "lua require('dapui').toggle()" },
    { name = "Buffer: Next", cmd = "BufferLineCycleNext" },
    { name = "Buffer: Previous", cmd = "BufferLineCyclePrev" },
  }

  pickers.new({}, {
    prompt_title = "Main Menu",
    finder = finders.new_table({
      results = menu_options,
      entry_maker = function(entry)
        return { value = entry, display = entry.name, ordinal = entry.name }
      end
    }),
    sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd(selection.value.cmd)
      end)
      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command("M", open_main_menu, {})

vim.cmd("colorscheme tokyonight")
vim.cmd("autocmd VimEnter * NvimTreeToggle")
