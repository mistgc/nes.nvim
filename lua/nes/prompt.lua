local Prompt = {}

---@param ctx nes.Context
---@return string
function Prompt.build_for_nes(ctx)
    local row, col = ctx.cursor[1], ctx.cursor[2]
    return string.format([[
You are an expert code editor. Provide an inline completion at the cursor position.

## File: %s
## Filetype: %s
## Cursor: line %d, column %d

## Context (line: content)
```
%s
```

Return the completion in the following format:

<<<SUGGESTION
<the exact text to insert at the cursor>
<<<END

Rules:
- Only output the text that should appear AFTER the cursor position on the current line and/or subsequent lines
- Do NOT repeat text already present before the cursor on the current line
- Keep completions concise (1-5 lines typically)
- Match the indentation and style of surrounding code
- If no reasonable prediction, output nothing between the markers
]],
        ctx.filename,
        ctx.filetype,
        row,
        col,
        ctx.lines
    )
end

return Prompt
