local M = {}

---Checks if a table (dict like) contains key
---
---@param tbl table
---@param key any
---@return boolean
M.haskey = function(tbl, key)
  return tbl[key] ~= nil
end

return M
