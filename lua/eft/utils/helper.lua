local fn = vim.fn

local M = {}

---Returns true if a char in printable
---
---@param char string
---@return boolean
M.is_printable = function (char)
  local charnr = fn.char2nr(char)
  if charnr >= 32 and charnr <= 126 then
    return true
  end

  return false
end

---Gets a single printable or blank character from the user input.
---Returns empty string for oterwise.
---
---@return string
M.getchar = function()
  local char = fn.nr2char(fn.getchar())
  if M.is_printable(char) then
    return char
  end

  return ''
end

---Returns true if `mode` is operator pending.
---
---@param mode string
---@return boolean
M.is_operator_pending = function(mode)
  return fn.index({'no', 'nov', 'noV', 'no<C-v>'}, mode) >= 0
end

return M
