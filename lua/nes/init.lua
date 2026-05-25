---@class nes.Nes
local M = {}

---@param cfg nes.Config
function M.setup(cfg)
  require('nes.config').setup(cfg)
  require('nes.logger').setup()
  local logger = require('nes.logger')

  logger.debug('NES setuped.')
end

return M
