---@class nes.api.Utils
local ApiUtils = {}

local config = require('nes.config')
local prompt = require('nes.prompt')
local logger = require('nes.logger')

function ApiUtils.get_header_for_openai()
  return {
    ['Authorization'] = 'Bearer ' .. config.api_key,
    ['Content-Type'] = 'application/json',
  }
end

function ApiUtils.get_header_for_anthropic()
  return {
    ['Content-Type'] = 'application/json',
    ['x-api-key'] = config.api_key,
    ['anthropic-version'] = '2023-06-01',
  }
end

function ApiUtils.build_messages_for_openai(system_prompt)
  return {
    {
      ['role'] = 'system',
      ['content'] = system_prompt,
    },
  }
end

function ApiUtils.build_messages_for_anthropic(system_prompt)
  return {
    {
      ['role'] = 'user',
      ['content'] = system_prompt,
    },
  }
end

---@param ctx nes.Context
function ApiUtils.get_payload_for_openai(ctx)
  local system_prompt = prompt.build(ctx)
  return {
    ['model'] = config.model,
    ['stream'] = true,
    ['messages'] = ApiUtils.build_messages_for_openai(system_prompt),
    ['reasoning_effort'] = config.reasoning_effort,
    ['max_completion_tokens'] = config.max_tokens,
  }
end

---@param ctx nes.Context
function ApiUtils.get_payload_for_anthropic(ctx)
  local system_prompt = prompt.build(ctx)
  return {
    ['model'] = config.model,
    ['max_tokens'] = config.max_tokens,
    ['stream'] = true,
    ['messages'] = ApiUtils.build_messages_for_anthropic(system_prompt),
    ['system'] = {
      ['text'] = 'You are an expert code editor assistant.',
      ['type'] = 'text',
    },
  }
end

function ApiUtils.get_stream_handle_fn()
  local handle_fn = nil

  if config.api_style == 'openai' then
    handle_fn = function(output, chunk)
      if not chunk or string.len(chunk) == 0 then
        return output
      end

      if vim.startswith(chunk, 'data: ') then
        chunk = string.sub(chunk, 6)
      end

      if vim.endswith(chunk, '[DONE]') then
        return output
      end

      local ok, event = pcall(vim.json.decode, chunk)

      if not ok then
        vim.schedule(function()
          logger.error('Decode the chunk faild: ' .. chunk)
        end)
        return output
      end

      local content = event.choices[1].delta.content

      if content == vim.NIL then
        return output
      end

      return output .. content
    end
  elseif config.api_style == 'anthropic' then
    handle_fn = function(output, chunk) end
  end

  if not handle_fn then
    logger.error('Unknown Api Style: ' .. config.api_style)
  end

  return handle_fn
end

return ApiUtils
