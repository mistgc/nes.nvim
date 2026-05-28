---@class Suggestion
---@field text string The text to insert at the cursor
---@field raw string The raw LLM response (for debugging)
local Suggestion = {}

---Parse LLM response into a Suggestion.
---@param raw string Raw LLM response
---@return Suggestion?
function Suggestion.parse(raw)
    local start_marker = '<<<SUGGESTION'
    local end_marker = '<<<END'

    local start_idx = raw:find(start_marker, 1, true)
    if not start_idx then
        return nil
    end

    local end_idx = raw:find(end_marker, start_idx + #start_marker, true)
    if not end_idx then
        return nil
    end

    local text = raw:sub(start_idx + #start_marker, end_idx - 1)
    -- Strip leading/trailing single newline from the extracted block
    if text:sub(1, 1) == '\n' then
        text = text:sub(2)
    end
    if text:sub(-1) == '\n' then
        text = text:sub(1, -2)
    end

    if text == '' then
        return nil
    end

    return setmetatable({ text = text, raw = raw }, { __index = Suggestion })
end

return Suggestion
