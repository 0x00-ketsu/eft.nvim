local config = require('eft.config')

---@class Global 'Plugin declared global variables'
---@field vim.g.eft_state table 'Store data for plugin'

local M = {}

---Entrance
---
---@param opts nil | Option
M.setup = function(opts)
  config.setup(opts)
end

return M
