local Prompt = {}

---@param ctx nes.Context
---@return string
function Prompt.build_for_nes(ctx)
    return string.format([[
You are an expert code editor assistant. Predict the NEXT logical edit based on the developer's just-completed edit.

This is inline completion at the cursor.

## File: %s

## Context (line: content)
```
%s
```
]])
end

---@param ctx nes.Context
---@return string
function Prompt.build_for_nes(ctx)
  return string.format(
    [[
You are an expert code editor assistant. Predict the NEXT logical edit based on the developer's just-completed edit.

This is NOT inline completion at the cursor. Predict a different location.

## File: %s

## Context (line: content)
```
%s
```

Return ONLY a unified diff patch in standard format. Use the context above to identify the exact location and surrounding lines.

Rules:
- Include the file header: --- a/%s and +++ b/%s
- Include a hunk header: @@ -start,count +start,count @@
- Prefix unchanged context lines with a single space
- Prefix added lines with +
- Prefix removed lines with -
- Include enough context lines (at least 2) so the hunk is unambiguous
- Do NOT include diff --git, index, or file mode lines
- Do NOT include any explanation, markdown, or JSON — only the raw diff

Example output:
--- a/example.lua
+++ b/example.lua
@@ -10,3 +10,4 @@
 existing context
-removed line
+replacement line
 more context
+added line

If no reasonable prediction: (empty response)
]],
    ctx.filename,
    ctx.lines,
    ctx.filename,
    ctx.filename
  )
end

return Prompt
