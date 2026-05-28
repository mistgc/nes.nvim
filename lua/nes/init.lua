---@class nes.Nes
local M = {}

---@param cfg nes.Config
function M.setup(cfg)
  require('nes.config').setup(cfg)
  require('nes.logger').setup()

  local logger = require('nes.logger')
  local config = require('nes.config')
  local call_suggestion = require('nes.api').call_suggestion
  local debounce = require('nes.api.utils').debounce

  local group = vim.api.nvim_create_augroup('NesGroup', { clear = true })
  vim.api.nvim_create_autocmd({ 'InsertEnter', 'CursorMovedI', 'TextChangedI', 'TextChangedP' }, {
    group = group,
    callback = vim.schedule_wrap(function()
      debounce(call_suggestion, config.debounce_ms)
    end),
  })

  logger.debug('NES setuped.')
end

return M
