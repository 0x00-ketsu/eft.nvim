local api = vim.api
local fn = vim.fn

local helper = require('eft.utils.helper')
local utils = require('eft.utils.eft')

---@class State
---@field till boolean
---@field direction integer
---@field char string
---@field mode string 'current mode'
---@field curpos table 'position of the cursor'
vim.g.eft_state = {}

---@enum directions
local DIRECTIONS = {prev = -1, next = 1}

---Remove autocmds for autogroup: `EFT_ACTION`
---
local function empty_aug_for_action()
  api.nvim_exec(
      [[
		aug EFT_ACTION
			au!
		aug END
	]], false
  )
end

local function reset()
  local state = vim.g.eft_state
  state['curpos'] = fn.getcurpos()
  vim.g.eft_state = state

  empty_aug_for_action()
  api.nvim_exec(
      [[
		aug EFT_ACTION
			au!
      au CursorMoved <buffer> execute "lua require('eft.action').reset()"
		aug END
	]], false
  )
end

---Valid is can repeatable
---
---@param dir directions
---@param till boolean
---@param is_repeat boolean
---@return boolean
local function can_repeat(dir, till, is_repeat)
  local mode = api.nvim_get_mode().mode
  local state = vim.g.eft_state
  local ok = false
  ok = is_repeat and not vim.tbl_isempty(state)
  ok = ok and state['direction'] == dir
  ok = ok and state['till'] == till
  ok = ok and state['mode'] == mode
  ok = ok and not helper.is_operator_pending(mode)
  return ok
end

local M = {}

---Works for `;`
---
M.eft_repeat = function()
  local state = vim.g.eft_state
  local dir, till = state['direction'], state['till']
  if not vim.tbl_isempty(state) and can_repeat(dir, till, true) then
    M.jump(dir, till, true)
  else
    vim.cmd('normal! ;')
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

---Jump to position of pressed character
---
---@param dir directions
---@param till boolean
---@param is_repeat boolean
M.jump = function(dir, till, is_repeat)
  local mode = api.nvim_get_mode().mode
  local curpos = fn.getcurpos()
  local line = fn.getline(curpos[2])
  local curcol = curpos[3]
  local tilloff = till and 1 or 0

  local indices = {}
  if dir == DIRECTIONS.next then
    indices = fn.range(curcol + tilloff, #line)
  else
    indices = fn.range(curcol - (2 + tilloff), 0, -1)
  end

  char = vim.g.eft_state['char']
  if not is_repeat then
    ---@diagnostic disable-next-line
    local ids = utils.highlight_chars(line, indices)
    char = helper.getchar()
    utils.clear_highlighted_chars(ids)
  end

  if #char > 0 then
    ---@diagnostic disable-next-line
    local jump_col = utils.compute_col(line, indices, char)
    if jump_col ~= -1 then
      if dir == DIRECTIONS.prev and till then
        jump_col = jump_col + 1
      elseif dir == DIRECTIONS.next and till then
        jump_col = jump_col - 1
      end
      -- move cursor to column position
      local expr = 'normal! ' .. (helper.is_operator_pending(mode) and 'v' or '') .. jump_col .. '|'
      vim.cmd(expr)

      local state = {}
      state['direction'] = dir
      state['till'] = till
      state['char'] = char
      state['mode'] = mode
      state['curpos'] = fn.getcurpos()
      vim.g.eft_state = state
      return
    end
  end

  if helper.is_operator_pending(mode) then
    api.nvim_feedkeys('<Cmd>normal! u<CR>', 'in', true)
  end
end

M.reset = function()
  local state = vim.g.eft_state
  if not vim.tbl_isempty(state) then
    if state['curpos'] ~= fn.getcurpos() and not helper.is_operator_pending(state['mode']) then
      reset()
    end
  end
end

return M
