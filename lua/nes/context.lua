---@class nes.Context
---@field bufnr number
---@field cursor [integer, integer]
---@field lines string[]
---@field filetype string
---@field filename string
---@field timestamp integer
---@field hash integer
local Context = {}

local config = require('nes.config')

local function _djb2_hash(str)
  local hash = 5381
  for i = 1, #str do
    hash = (hash * 33) + string.byte(str, i)
  end
  return hash
end

local function _build_lines(lines, start_line)
  local out = ''
  for index, value in ipairs(lines) do
    out = out .. ('%d: %s').format(start_line + index - 1, value)
  end
  return out
end

function Context.new(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(bufnr)
  local row, col = cursor[1] - 1, cursor[2]
  local num_lines = vim.api.nvim_buf_line_count(bufnr)
  local start_line, end_line =
    (row - config.num_prefix_context_lines).max(0), (col + config.num_postfix_context_lines).min(num_lines + 1)
  local lines = _build_lines(vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false), start_line)
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
