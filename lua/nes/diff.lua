---Parse and apply unified diff files.
---
---Supported format: unified diff with file headers like `--- a/path` / `+++ b/path`,
---hunk headers `@@ -old_start,old_count +new_start,new_count @@`, context/add/remove lines,
---and `\ No newline at end of file` markers.
---@class nes.Diff
local Diff = {}

---@class nes.DiffFile
---@field old_path string
---@field new_path string
---@field hunks nes.DiffHunk[]

---@class nes.DiffHunk
---@field old_start integer 1-based start line in old file
---@field old_len integer number of lines in old file for this hunk
---@field new_start integer 1-based start line in new file
---@field new_len integer number of lines in new file for this hunk
---@field lines nes.DiffLine[]

---@class nes.DiffLine
---@field type "'context'" | "'add'" | "'remove'" | "'no_newline"'
---@field content string text without the leading prefix
---@field no_newline? boolean

-- ---------------------------------------------------------------------------
-- Parsing
-- ---------------------------------------------------------------------------

---Split text into lines, preserving the final element even if it does not end
---with a newline.
---@param text string
---@return string[]
local function split_lines(text)
  if text == '' then return {} end
  local lines = vim.split(text, '\n')
  if lines[#lines] == '' then table.remove(lines) end
  return lines
end

---Parse a unified diff string into a list of file patches.
---@param diff_text string
---@return nes.DiffFile[]
function Diff.parse(diff_text)
  local lines = split_lines(diff_text)
  local files = {}
  local current_file = nil
  local current_hunk = nil
  local i = 1

  while i <= #lines do
    local line = lines[i]

    -- --- a/ file header
    if line:sub(1, 4) == '--- ' then
      local old_path = line:sub(5):gsub('^a/', '')
      if not current_file then
        current_file = { old_path = old_path, new_path = '', hunks = {} }
      else
        current_file.old_path = old_path
      end
      i = i + 1
      goto continue
    end

    -- +++ b/ file header
    if line:sub(1, 4) == '+++ ' then
      local new_path = line:sub(5):gsub('^b/', '')
      if not current_file then
        current_file = { old_path = '', new_path = new_path, hunks = {} }
      else
        current_file.new_path = new_path
      end
      i = i + 1
      goto continue
    end

    -- @@ hunk header @@
    if line:match('^@@ %-%d+,?%d* %+%d+,?%d* @@') then
      local old_start = tonumber(line:match('^@@ %-(%d+)'))
      local old_len_str = line:match('^@@ -%d+,?(%d*)')
      local new_start = tonumber(line:match('%+(%d+)'))
      local new_len_str = line:match('%+%d+,?(%d*)')

      local hunk = {
        old_start = old_start,
        old_len = old_len_str ~= '' and tonumber(old_len_str) or 1,
        new_start = new_start,
        new_len = new_len_str ~= '' and tonumber(new_len_str) or 1,
        lines = {},
      }

      if current_file then
        table.insert(current_file.hunks, hunk)
        current_hunk = hunk
      end

      i = i + 1
      goto continue
    end

    -- Hunk body lines
    if current_hunk then
      local prefix = line:sub(1, 1)
      if prefix == ' ' then
        table.insert(current_hunk.lines, { type = 'context', content = line:sub(2) })
      elseif prefix == '+' then
        table.insert(current_hunk.lines, { type = 'add', content = line:sub(2) })
      elseif prefix == '-' then
        table.insert(current_hunk.lines, { type = 'remove', content = line:sub(2) })
      elseif line == '\\ No newline at end of file' then
        local last = current_hunk.lines[#current_hunk.lines]
        if last and last.type ~= 'no_newline' then
          last.no_newline = true
        end
      end
      i = i + 1
      goto continue
    end

    -- diff header lines (index, new/deleted file mode, rename, etc.)
    if line:match('^diff ') or line:match('^index ') or line:match('^new file')
      or line:match('^deleted file') or line:match('^old mode') or line:match('^new mode')
      or line:match('^rename from') or line:match('^rename to')
      or line:match('^similarity index') or line:match('^dissimilarity index')
      or line:match('^Binary files') then
      if current_file and #current_file.hunks > 0 then
        table.insert(files, current_file)
        current_file = nil
      end
      current_hunk = nil
      i = i + 1
      goto continue
    end

    i = i + 1
    ::continue::
  end

  if current_file and #current_file.hunks > 0 then
    table.insert(files, current_file)
  end

  return files
end

-- ---------------------------------------------------------------------------
-- Applying
-- ---------------------------------------------------------------------------

---Check whether the hunk's context and remove lines match the file starting at
---`file_pos` (1-based).
---@param file_lines string[]
---@param file_pos integer
---@param hunk nes.DiffHunk
---@return boolean
function Diff._match_hunk(file_lines, file_pos, hunk)
  local fi = file_pos
  for _, dl in ipairs(hunk.lines) do
    if dl.type == 'context' then
      if file_lines[fi] ~= dl.content then
        return false
      end
      fi = fi + 1
    elseif dl.type == 'remove' then
      if file_lines[fi] ~= dl.content then
        return false
      end
      fi = fi + 1
    end
  end
  return true
end

---Apply a list of parsed diff hunks to the given file content.
---Returns the patched content as a string.
---@param file_content string original file content
---@param hunks nes.DiffHunk[] hunks from Diff.parse
---@param opts? {fuzz: integer} optional fuzz factor (context lines to relax)
---@return string new_content
function Diff.apply(file_content, hunks, opts)
  opts = opts or {}
  local fuzz = opts.fuzz or 0

  local orig_lines = split_lines(file_content)
  local has_trailing_newline = file_content:match('\n$') ~= nil or file_content == ''

  local result_lines = {}
  local pos = 1

  for _, hunk in ipairs(hunks) do
    local target = hunk.old_start

    -- Copy lines before the hunk target
    while pos < target do
      table.insert(result_lines, orig_lines[pos])
      pos = pos + 1
    end

    -- Try to match hunk at expected position, with fuzz fallback
    local matched = false
    for delta = 0, fuzz do
      for _, sign in ipairs({ 0, -1, 1 }) do
        local try_pos = target + delta * sign
        if try_pos >= 1 and try_pos <= #orig_lines + 1 then
          if Diff._match_hunk(orig_lines, try_pos, hunk) then
            pos = try_pos
            matched = true
            goto applied
          end
        end
      end
    end

    ::applied::
    if not matched then
      pos = target
    end

    -- Consume old lines and emit new lines
    for _, dl in ipairs(hunk.lines) do
      if dl.type == 'context' then
        if pos <= #orig_lines then
          table.insert(result_lines, orig_lines[pos])
          pos = pos + 1
        end
      elseif dl.type == 'remove' then
        if pos <= #orig_lines then
          pos = pos + 1
        end
      elseif dl.type == 'add' then
        table.insert(result_lines, dl.content)
      end
    end
  end

  while pos <= #orig_lines do
    table.insert(result_lines, orig_lines[pos])
    pos = pos + 1
  end

  local patched = table.concat(result_lines, '\n')
  if has_trailing_newline and patched ~= '' then
    patched = patched .. '\n'
  end
  return patched
end

-- ---------------------------------------------------------------------------
-- Convenience: parse + apply in one call
-- ---------------------------------------------------------------------------

---Parse a diff and apply the hunks affecting `file_path` to the given content.
---If `file_path` is nil, applies the first file found in the diff.
---@param diff_text string
---@param file_content string
---@param file_path? string
---@param opts? {fuzz: integer}
---@return string new_content
function Diff.patch(diff_text, file_content, file_path, opts)
  local files = Diff.parse(diff_text)
  local target
  if file_path then
    for _, f in ipairs(files) do
      if f.new_path == file_path or f.old_path == file_path then
        target = f
        break
      end
    end
  else
    target = files[1]
  end

  if not target then
    return file_content
  end

  return Diff.apply(file_content, target.hunks, opts)
end

return Diff
