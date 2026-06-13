local fn = vim.fn

local M = {}

---Returns true if `char` is a single printable character, including
---multi-byte (e.g. CJK, accented Latin, emoji) characters. C0/C1 control
---characters are rejected.
---
---@param char string
---@return boolean
M.is_printable = function(char)
  if type(char) ~= "string" or #char == 0 then
    return false
  end

  local ok, charnr = pcall(fn.char2nr, char)
  if not ok then
    return false
  end

  if charnr >= 32 and charnr <= 126 then
    return true
  end

  -- exclude the C1 control range (0x80-0x9F); allow any other valid codepoint
  return charnr >= 160 and charnr <= 0x10FFFF
end

---Returns the byte width of the UTF-8 character starting at the 1-based
---byte position `pos` in `str`. Returns `1` for continuation bytes or
---invalid leading bytes so callers can safely advance byte-by-byte.
---
---@param str string
---@param pos integer 1-based byte index
---@return integer
M.utf8_char_width = function(str, pos)
  local byte = str:byte(pos)
  if not byte then
    return 1
  elseif byte >= 0xF0 then
    return 4
  elseif byte >= 0xE0 then
    return 3
  elseif byte >= 0xC0 then
    return 2
  end
  return 1
end

---Returns true if the byte at the 1-based position `pos` in `str` is a
---UTF-8 continuation byte, i.e. not the start of a character.
---
---@param str string
---@param pos integer 1-based byte index
---@return boolean
M.is_utf8_continuation = function(str, pos)
  local byte = str:byte(pos)
  return byte ~= nil and byte >= 0x80 and byte < 0xC0
end

---Gets a single printable character from user input.
---Returns an empty string when the input is missing, non-printable,
---or interrupted (e.g. `<C-c>`).
---
---@return string
M.getchar = function()
  local ok, code = pcall(fn.getchar)
  if not ok or type(code) ~= "number" then
    -- interrupted (`<C-c>`) or a special key returned as a string
    return ""
  end

  local char = fn.nr2char(code)
  if M.is_printable(char) then
    return char
  end

  return ""
end

---Returns true if `mode` is one of the operator-pending modes.
---
---@param mode string
---@return boolean
M.is_operator_pending = function(mode)
  return fn.index({ "no", "nov", "noV", "no\22" }, mode) >= 0
end

return M
