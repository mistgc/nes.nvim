---@class nes.Config
---@field api_style string
---@field api_base_url string
---@field api_key string|nil
---@field model string
---@field debounce_ms integer
---@field num_prefix_context_lines integer
---@field num_postfix_context_lines integer
---@field max_tokens integer
---@field reasoning_effort string
---@field keymaps table<string, string>
---@field enable boolean
---@field _config table|nil
local M = {}

_defaults = {
  -- Api Style: openai | anthropic
  api_style = 'openai',
  api_base_url = '	https://api.deepseek.com',
  api_key = nil,
  model = 'deepseek-v4-flash',
  debounce_ms = 800,
  num_prefix_context_lines = 20,
  num_postfix_context_lines = 10,
  max_tokens = 1024,
  reasoning_effort = "low",

  keymaps = {
    accept_suggestion = '<Tab>',
    reject_suggestion = '<Esc>',
    next_suggestion = '<c-n>',
    prev_suggestion = '<c-p>',
  },

  enable = true,
}

M._config = {}

setmetatable(M, {
  __index = function(_, key)
    return M._config[key]
  end,
  __newindex = function(_, key, value)
    M._config[key] = value
  end,
})

function M.setup(cfg)
  cfg = cfg or {}
  M._config = vim.tbl_deep_extend('keep', cfg, _defaults)

  -- Get API key
  if not M._config.api_key then
    if M._config.api_style == 'openai' then
      M._config.api_key = os.getenv('OPENAI_API_KEY')
    elseif M._config.api_style == 'anthropic' then
      M._config.api_key = os.getenv('ANTHROPIC_API_KEY')
    else
      vim.notify('The `api_style` invalid.', vim.log.levels.WARN)
      M._config.enable = false
    end
  end
end

return M
