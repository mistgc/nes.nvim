---@class nes.Context
---@field bufnr number
---@field cursor [integer, integer]
---@field lines string
---@field filetype string
---@field filename string
---@field timestamp integer
---@field hash integer
---@field type integer
local Context = {}

local logger = require('nes.logger')
local config = require('nes.config')
local PayloadType = require('nes.api.payload_type').PayloadType

local function _djb2_hash(str)
  local hash = 5381
  for i = 1, #str do
    hash = (hash * 33) + string.byte(str, i)
  end
  return hash
end

local function _build_lines(lines, start_line, cursor_row, cursor_col)
  local out = {}

  for index, value in ipairs(lines) do
    local line_num = start_line + index - 1
    if line_num == cursor_row then
      local before = value:sub(1, cursor_col)
      local after = value:sub(cursor_col + 1)
      value = before .. '<|cursor|>' .. after
    end
    out[index] = ('%d: %s').format(line_num, value)
  end

  return table.concat(out, '\n')
end

function Context.new(bufnr, pltype)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local num_lines = vim.api.nvim_buf_line_count(bufnr)
  local start_line, end_line = 0, 0

  if pltype == PayloadType.Suggestion then
    start_line, end_line =
      math.max(row - config.num_prefix_context_lines_for_suggestion, 0),
      math.min(row + config.num_postfix_context_lines_for_suggestion, num_lines - 1)
  elseif pltype == PayloadType.Nes then
    start_line, end_line =
      math.max(row - config.num_prefix_context_lines_for_nes, 0),
      math.min(row + config.num_postfix_context_lines_for_nes, num_lines - 1)
  end

  local cursor_marker_row = pltype == PayloadType.Suggestion and row or nil
  local lines =
    _build_lines(vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false), start_line, cursor_marker_row, col)

  local ctx = {
    bufnr = bufnr,
    cursor = { row, col },
    lines = lines,
    filetype = vim.bo[bufnr].filetype,
    filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':'),
    timestamp = os.time(),
    hash = _djb2_hash(lines),
    type = pltype,
  }

  setmetatable(ctx, Context)

  return ctx
end

Context.PayloadType = PayloadType

return Context
