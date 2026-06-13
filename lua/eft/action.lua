local api = vim.api
local fn = vim.fn

local helper = require("eft.utils.helper")
local utils = require("eft.utils.eft")

---@class State
---@field till boolean
---@field direction integer
---@field char string
---@field mode string current mode
---@field curpos table position of the cursor, see `getcurpos()`
vim.g.eft_state = {}

---@enum Direction
local DIRECTIONS = { prev = -1, next = 1 }

local AUGROUP_NAME = "EFT_ACTION"

---@return State
local function get_state()
  return vim.g.eft_state or {}
end

---@param state State
local function set_state(state)
  vim.g.eft_state = state
end

---Re-arm the `CursorMoved` watcher used by `M.reset`, tracking the
---cursor position right after a jump.
local function watch_cursor()
  local state = get_state()
  state["curpos"] = fn.getcurpos()
  set_state(state)

  local group = api.nvim_create_augroup(AUGROUP_NAME, { clear = true })
  api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = 0,
    callback = function()
      require("eft.action").reset()
    end,
  })
end

---Returns true if the saved state can be repeated for `;`.
---
---@param dir Direction
---@param till boolean
---@param is_repeat boolean
---@return boolean
local function can_repeat(dir, till, is_repeat)
  if not is_repeat then
    return false
  end

  local state = get_state()
  if vim.tbl_isempty(state) then
    return false
  end

  local mode = api.nvim_get_mode().mode
  return state["direction"] == dir
    and state["till"] == till
    and state["mode"] == mode
    and not helper.is_operator_pending(mode)
end

---Compute the 0-based byte indices to search for a char in `line`,
---starting next to the cursor and moving towards `dir`.
---
---@param line string
---@param curcol integer 1-based cursor column, see `getcurpos()[3]`
---@param dir Direction
---@param till boolean
---@return integer[]|nil `nil` when there is nothing to search
local function search_indices(line, curcol, dir, till)
  local tilloff = till and 1 or 0

  if dir == DIRECTIONS.next then
    if #line == 0 then
      return nil
    end
    return fn.range(curcol + tilloff, #line)
  end

  if curcol - (2 + tilloff) == -1 then
    return nil
  end
  return fn.range(curcol - (2 + tilloff), 0, -1)
end

---Move the cursor to `jump_col` (1-based virtual/screen column).
---
---@param jump_col integer
---@param mode string
local function move_cursor(jump_col, mode)
  local ok, has_inlay_hints = pcall(function()
    return fn.has("nvim-0.10") == 1 and vim.lsp.inlay_hint.is_enabled()
  end)

  if ok and has_inlay_hints then
    local win = api.nvim_get_current_win()
    local row = api.nvim_win_get_cursor(win)[1]
    local byte_col = fn.virtcol2col(win, row, jump_col)
    api.nvim_win_set_cursor(win, { row, byte_col - 1 })
  else
    local expr = "normal! " .. (helper.is_operator_pending(mode) and "v" or "") .. jump_col .. "|"
    vim.cmd(expr)
  end
end

local M = {}

---Works for `;`
---
M.eft_repeat = function()
  local state = get_state()
  local dir, till = state["direction"], state["till"]
  if not vim.tbl_isempty(state) and can_repeat(dir, till, true) then
    M.jump(dir, till, true)
  else
    vim.cmd("normal! ;")
  end
end

---Works for operator `f`
---
M.eft_f = function()
  M._eft_forward(false, false)
end

---Works for operator `F`
---
M.eft_F = function()
  M._eft_backward(false, false)
end

---Works for operator `t`
---
M.eft_t = function()
  M._eft_forward(true, false)
end

---Works for operator `T`
---
M.eft_T = function()
  M._eft_backward(true, false)
end

---Forward
---
---@param till boolean
---@param is_repeat boolean
M._eft_forward = function(till, is_repeat)
  is_repeat = can_repeat(DIRECTIONS.next, till, is_repeat)
  M.jump(DIRECTIONS.next, till, is_repeat)
end

---Backward
---
---@param till boolean
---@param is_repeat boolean
M._eft_backward = function(till, is_repeat)
  is_repeat = can_repeat(DIRECTIONS.prev, till, is_repeat)
  M.jump(DIRECTIONS.prev, till, is_repeat)
end

---Jump to the position of the pressed character
---
---@param dir Direction
---@param till boolean
---@param is_repeat boolean
M.jump = function(dir, till, is_repeat)
  local mode = api.nvim_get_mode().mode
  local curpos = fn.getcurpos()
  local line = fn.getline(curpos[2])
  local curcol = curpos[3]

  local indices = search_indices(line, curcol, dir, till)
  if not indices then
    return
  end

  local char
  if is_repeat then
    char = get_state()["char"]
  else
    local ids = utils.highlight_chars(line, indices)
    char = helper.getchar()
    utils.clear_highlighted_chars(ids)
  end

  if type(char) == "string" and #char > 0 then
    local jump_col = utils.compute_col(line, indices, char, dir, till)
    if jump_col ~= -1 then
      move_cursor(jump_col, mode)

      set_state({
        direction = dir,
        till = till,
        char = char,
        mode = mode,
        curpos = fn.getcurpos(),
      })
      return
    end
  end

  if helper.is_operator_pending(mode) then
    api.nvim_feedkeys("<Cmd>normal! u<CR>", "in", true)
  end
end

---Refresh the saved state when the cursor moves away from the jump target.
---
M.reset = function()
  local state = get_state()
  if vim.tbl_isempty(state) then
    return
  end

  if
    not vim.deep_equal(state["curpos"], fn.getcurpos())
    and not helper.is_operator_pending(state["mode"])
  then
    watch_cursor()
  end
end

return M
