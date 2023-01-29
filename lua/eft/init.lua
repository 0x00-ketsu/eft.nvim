require('eft.highlight')
local config = require('eft.config')

local M = {}

---Entrance
---
---@param opts nil | Option
M.setup = function(opts)
  config.setup(opts)
end

return M
