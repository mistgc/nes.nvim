---@class nes.Api
local Api = {
  nvim_version = vim.version(),
}

local config = require('nes.config')
local logger = require('nes.logger')
local curl = require('plenary.curl')

local function _get_header_for_openai()
  return {
    ['Authorization'] = 'Bearer ' .. config.api_key,
    ['Content-Type'] = 'application/json',
  }
end

local function _get_header_for_anthropic()
  return {
    ['Content-Type'] = 'application/json',
    ['x-api-key'] = config.api_key,
    ['anthropic-version'] = '2023-06-01',
  }
end

function Api.get_headers()
  local header = nil
  if config.api_style == 'openai' then
    header = _get_header_for_openai()
  elseif config.api_style == 'anthropic' then
    header = _get_header_for_anthropic()
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

---@param context nes.Context
---@return nil
function Api.get_payload(context)
    local payload = nil
    return payload
end

function Api.call_llm(context, callback)
  local url = Api.get_url()
  local headers = Api.get_headers()
  local payload = Api.get_payload(context)
  local output = ''

  curl.post(url, {
    headers = headers,
    body = vim.json.encode(payload),
    on_error = function(err)
      logger.error('Api request error ' .. err)
    end,
    stream = function(_, chunk)
      if not chunk then
        return
      end
      if vim.startswith(chunk, 'data: ') then
        chunk = chunk:sub(6)
      end
      if chunk == '[DONE]' then
        return
      end
      local ok, event = pcall(vim.json.decode, chunk)
      if not ok then
        return
      end
      if event and event.choices and event.choices[1] then
        local choice = event.choices[1]
        if choice.delta and choice.delta.content then
          output = output .. choice.delta.content
        end
      end
    end,
    callback = function()
      callback(output)
    end,
  })
end

return Api
