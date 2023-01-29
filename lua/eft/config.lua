---@class Option
---@field ignore_case boolean
---@field highlights table
local defaults = {
  ignore_case = false,
  highlights = {
    {
      name = 'EftChar',
      allow_space = true,
      color = {
        gui = 'bold,underline',
        guifg = 'Orange',
        cterm = 'bold,underline',
        ctermfg = 'Red'
      }
    },
    {
      name = 'EftSubChar',
      allow_space = false,
      color = {
        gui = 'bold,underline',
        guifg = 'Gray',
        cterm = 'bold,underline',
        ctermfg = 'Gray'
      }
    }
  }
}

local M = {plugin_name = 'eft.nvim'}

---@param opts nil | Option
M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts or {})
end

M.setup()

return M
