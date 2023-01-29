local function define_highlight(options)
  local highlights = options['highlights']
  for _, highlight in pairs(highlights) do
    local name = highlight['name']
    local color = highlight['color']
    local expr = ''
    for key, value in pairs(color) do
      if #value == 0 then
        value = 'NONE'
      end
      expr = expr .. ' ' .. key .. '=' .. value .. ''
    end
    vim.cmd("hi! default " .. name .. expr)
  end
end

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
  define_highlight(M.opts)
end

M.setup()

return M
