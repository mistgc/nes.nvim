local Prompt = {}

---@param ctx nes.Context
---@return string
function Prompt.build(ctx)
    return string.format([[
You are an expert code editor assistant. Predict the NEXT logical edit based on the developer's just-completed edit.

This is NOT inline completion at the cursor. Predict a different location.

## File: %s (%s)

## Context (line: content)
```
%s
```

Return ONLY valid JSON:
{
  "line": <1-indexed line>,
  "start_col": <0-indexed start column>,
  "end_col": <0-indexed end column>,
  "old_text": "<exact existing text to replace>",
  "new_text": "<replacement text>",
  "reason": "<brief explanation>"
}
If no reasonable prediction: {"line":0,"old_text":"","new_text":"","reason":"no prediction"}
]], ctx.filename, ctx.filename, ctx.lines)
end

return Prompt
