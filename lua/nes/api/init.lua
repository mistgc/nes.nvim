---@class nes.Api
local Api = {
  nvim_version = vim.version(),
}

local config = require('nes.config')
local logger = require('nes.logger')
local curl = require('plenary.curl')
local api_util = require('nes.api.utils')

function Api.get_headers()
  local header = nil
  if config.api_style == 'openai' then
    header = api_util.get_header_for_openai()
  elseif config.api_style == 'anthropic' then
    header = api_util.get_header_for_anthropic()
  end

  if not header then
    logger.error('Unknown Api Style: ' .. config.api_style .. '\n' .. 'Unknown Base Url: ' .. config.api_base_url)
  end

  return header
end

function Api.get_url()
  local url = nil
  if config.api_style == 'openai' then
    url = config.api_base_url .. '/chat/completions'
  elseif config.api_style == 'anthropic' then
    url = config.api_base_url .. '/messages'
  end

  if not url then
    logger.error('Unknown Api Style: ' .. config.api_style .. '\n' .. 'Unknown Base Url: ' .. config.api_base_url)
  end

  return url
end

---@param ctx nes.Context
---@return nil
function Api.get_payload(ctx)
  local payload = nil
  if config.api_style == 'openai' then
    payload = api_util.get_payload_for_openai(ctx)
  elseif config.api_style == 'anthropic' then
    payload = api_util.get_payload_for_anthropic(ctx)
  end

  if not payload then
    logger.error('Unknown Api Style: ' .. config.api_style)
  end

  return payload
end

function Api.call_llm(ctx, callback)
  local url = Api.get_url()
  local headers = Api.get_headers()
  local payload = Api.get_payload(ctx)
  local stream_handle_fn = api_util.get_stream_handle_fn()
  local output = ''

  logger.debug(vim.json.encode(payload, { indent = '  ', sort_key = true }))

  curl.post(url, {
    headers = headers,
    body = vim.json.encode(payload),
    on_error = function(err)
      logger.error('Api request error ' .. err)
    end,
    stream = function(_, chunk)
      output = stream_handle_fn(output, chunk)
    end,
    callback = function()
      logger.debug(output)
      callback(output)
    end,
  })
end

return Api
