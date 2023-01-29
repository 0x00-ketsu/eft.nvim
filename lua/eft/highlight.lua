local config = require('eft.config')
local options = config.opts

local M = {}

M.define_highlight = function()
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

M.define_highlight()
