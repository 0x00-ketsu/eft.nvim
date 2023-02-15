local fn = vim.fn

local config = require('eft.config')
local tbl = require('eft.utils.tbl')
local helper = require('eft.utils.helper')

local options = config.opts

---Returns true if two chars is equal, works with option: `ignore_case`
---
---@param char1 string
---@param char2 string
---@return boolean
local function match(char1, char2)
  if options['ignore_case'] then
    return string.lower(char1) == string.lower(char2)
  end

  return char1 == char2
end

local M = {}

---Return column number of char in line
---
---@param line string
---@param indices table
---@return integer
M.compute_col = function(line, indices, char)
  local count = 1
  for _, idx in ipairs(indices) do
    if idx ~= 0 and M.can_index(line, idx) and match(line:sub(idx + 1, idx + 1), char) then
      count = count - 1
      if count == 0 then
        local ret = fn.strdisplaywidth(line:sub(1, idx + 1))
        return ret
      end
    end
  end

  return -1
end

---Highlight char(s) in line
---
---@param line string
---@param indices table
---@return table
M.highlight_chars = function(line, indices)
  local highlights = options['highlights']
  if vim.tbl_isempty(highlights) or fn.reg_executing() ~= '' then
    return {}
  end

  local cnt = 1
  local chars, highs = {}, {}
  for _, idx in pairs(indices) do
    -- print(M.can_index(line, idx + 1), line:sub(idx+1, idx+1))

    if M.can_index(line, idx + 1) then
      local char = line:sub(idx + 1, idx + 1)
      if #char < 1 then
        goto continue
      end

      if not tbl.haskey(chars, char) then
        chars[char] = 0
      end
      chars[char] = chars[char] + 1

      local count = (chars[char] - cnt) + 1
      if count < 0 then
        goto continue
      end

      local match_highlight = highlights[count]

      local ok = true
      ok = ok and match_highlight
      ok = ok and (match_highlight['allow_space'] or char:match('%S'))
      if ok then
        table.insert(highs, {match_highlight['name'], idx + 1, char})
      end
    end

    ::continue::
  end

  -- draw color for char
  local highlighted_ids = {}
  for _, item in pairs(highs) do
    ---@diagnostic disable-next-line
    local highlighted_id = fn.matchaddpos(item[1], {{fn.line('.'), item[2]}})
    if highlighted_id > -1 then
      table.insert(highlighted_ids, highlighted_id)
    end
  end
  vim.cmd('redraw')
  return highlighted_ids
end

---Works with function `highlight_chars`
---Clear highlighted chars
---
---@param ids table 'highlighted ids'
M.clear_highlighted_chars = function(ids)
  if not ids or vim.tbl_isempty(ids) then
    return
  end

  for _, id in ipairs(ids) do
    fn.matchdelete(id)
  end
end

---Returns true if index of char can be found in line
---
---@param line string
---@param index integer
---@return boolean
M.can_index = function(line, index)
  -- ignore chars to adjacent to cursor
  if index == 0 or (#line - 1 == index) then
    return true
  end

  local funcs = {M.is_character}
  for _, func in ipairs(funcs) do
    if func(line, index) then
      return true
    end
  end

  return false
end

---Returns true if character is printable
---
---@param line string
---@param index integer
---@return boolean
M.is_printable = function(line, index)
  local char = line:sub(index, index)
  -- return char:match('%g')
  return helper.is_printable(char)
end

---Returns true if character is a character
---
---@param line string
---@param index integer
---@return boolean
M.is_character = function (line, index)
  local char = line:sub(index, index)
  return char:match('.-')
end

---Returns true if character is a letter (case insensitive)
---
---@param line string
---@param index integer
---@return boolean
M.is_letter = function(line, index)
  local char = line:sub(index, index)
  return char:match('%a')
end

---Returns true if character is a digit
---
---@param line string
---@param index integer
---@return boolean
M.is_digit = function(line, index)
  local char = line:sub(index, index)
  return char:match('%d')
end

---Returns true if character is a space
---
---@param line string
---@param index integer
---@return boolean
M.is_space = function(line, index)
  local char = line:sub(index, index)
  return char:match('%s')
end

return M
