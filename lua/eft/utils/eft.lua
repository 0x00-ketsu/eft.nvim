local fn = vim.fn

local helper = require("eft.utils.helper")

---Returns the active plugin configuration, falling back to safe defaults
---if `setup()` has not run yet.
---
---@return Option
local function get_config()
  local ok, eft = pcall(require, "eft")
  if ok and eft.config then
    return eft.config
  end

  return { ignore_case = false, highlights = {} }
end

---Returns true if two chars are equal, honoring the `ignore_case` option.
---
---@param char1 string
---@param char2 string
---@return boolean
local function match(char1, char2)
  if get_config()["ignore_case"] then
    return string.lower(char1) == string.lower(char2)
  end

  return char1 == char2
end

local M = {}

---Returns the virtual (screen) column to jump to for `char` in `line`,
---searching `indices` in order. Returns `-1` when no match is found.
---
---The returned column is meant to be consumed by `:normal N|` (or converted
---to a byte column via `virtcol2col()`), so multi-byte characters - which
---occupy more than one screen column - are accounted for.
---
---@param line string
---@param indices integer[] 0-based byte indices to search, in priority order
---@param char string
---@param dir integer positive for forward (`f`/`t`), negative for backward (`F`/`T`)
---@param till boolean
---@return integer
M.compute_col = function(line, indices, char, dir, till)
  if type(char) ~= "string" or #char == 0 then
    return -1
  end

  for _, idx in ipairs(indices) do
    -- `idx == 0` (the very first byte of the line) is intentionally skipped
    if idx ~= 0 and not helper.is_utf8_continuation(line, idx + 1) then
      local width = helper.utf8_char_width(line, idx + 1)
      if match(line:sub(idx + 1, idx + width), char) then
        local prefix_width = fn.strdisplaywidth(line:sub(1, idx))

        if not till then
          -- land on the matched char itself
          return prefix_width + 1
        end

        if dir > 0 then
          -- `t`: land on the char right before the match
          return prefix_width
        end

        -- `T`: land on the char right after the match
        local char_width = fn.strdisplaywidth(line:sub(1, idx + width)) - prefix_width
        return prefix_width + char_width + 1
      end
    end
  end

  return -1
end

---Highlight the candidate chars in `line` at `indices`.
---
---@param line string
---@param indices integer[] 0-based byte indices to consider
---@return integer[] ids of the created highlight matches
M.highlight_chars = function(line, indices)
  local highlights = get_config()["highlights"]
  if vim.tbl_isempty(highlights) or fn.reg_executing() ~= "" then
    return {}
  end

  local seen_counts = {}
  local candidates = {}
  for _, idx in pairs(indices) do
    if not helper.is_utf8_continuation(line, idx + 1) then
      local width = helper.utf8_char_width(line, idx + 1)
      local char = line:sub(idx + 1, idx + width)
      if #char > 0 then
        seen_counts[char] = (seen_counts[char] or 0) + 1

        local highlight = highlights[seen_counts[char]]
        if highlight and (highlight["allow_space"] or char:match("%S")) then
          table.insert(candidates, { name = highlight["name"], col = idx + 1, width = width })
        end
      end
    end
  end

  local ids = {}
  for _, item in ipairs(candidates) do
    local ok, id = pcall(fn.matchaddpos, item.name, { { fn.line("."), item.col, item.width } })
    if ok and id > -1 then
      table.insert(ids, id)
    end
  end

  vim.cmd("redraw")
  return ids
end

---Clear highlighted chars previously created by `highlight_chars`.
---
---@param ids integer[] highlight match ids
M.clear_highlighted_chars = function(ids)
  if not ids or vim.tbl_isempty(ids) then
    return
  end

  for _, id in ipairs(ids) do
    pcall(fn.matchdelete, id)
  end
end

return M
