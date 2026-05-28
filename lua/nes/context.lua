---@class nes.Context
---@field bufnr number
---@field cursor [integer, integer]
---@field lines string[]
---@field filetype string
---@field filename string
---@field timestamp integer
---@field hash integer
local Context = {}

local logger = require('nes.logger')
local config = require('nes.config')
local PayloadType = require('nes.api.utils').PayloadType

local function _djb2_hash(str)
  local hash = 5381
  for i = 1, #str do
    hash = (hash * 33) + string.byte(str, i)
  end
  return hash
end

local function _build_lines(lines, start_line)
  local out = {}
  for index, value in ipairs(lines) do
    out[index] = (start_line + index) .. ': ' .. value
  end
  return table.concat(out, '\n')
end

---@param bufnr integer
---@param pltype nes.api.utils.PayloadType
function Context.new(bufnr, pltype)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local num_lines = vim.api.nvim_buf_line_count(bufnr)
  local start_line, end_line = 0, 0

  if pltype == PayloadType.Suggestion then
    start_line, end_line =
      math.max(row - config.num_prefix_context_lines_for_suggestion, 0),
      math.min(row + config.num_postfix_context_lines_for_suggestion, num_lines + 1)
  elseif pltype == PayloadType.Nes then
    start_line, end_line =
      math.max(row - config.num_prefix_context_lines_for_nes, 0),
      math.min(row + config.num_postfix_context_lines_nes, num_lines + 1)
  end

  local lines = _build_lines(vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false), start_line)
  logger.debug('lines: ', lines)
  local ctx = {
    bufnr = bufnr,
    cursor = { row, col },
    lines = lines,
    filetype = vim.bo[bufnr].filetype,
    filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':'),
    timestamp = os.time(),
    hash = _djb2_hash(lines),
  }

  setmetatable(ctx, Context)

  return ctx
end

return Context
