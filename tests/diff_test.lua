local Diff = require('nes.diff')

local passed = 0
local failed = 0

local function assert_eq(a, b, msg)
  if a == b then
    passed = passed + 1
    print('  PASS: ' .. msg)
  else
    failed = failed + 1
    print('  FAIL: ' .. msg)
    print('    expected: ' .. vim.inspect(b))
    print('    got:      ' .. vim.inspect(a))
  end
end

-- Test 1: Simple add
print('\n--- Test: simple add ---')
local old = 'line1\nline2\nline3\n'
local diff = [[--- a/test.txt
+++ b/test.txt
@@ -1,3 +1,4 @@
 line1
+inserted
 line2
 line3
]]
local result = Diff.patch(diff, old)
assert_eq(result, 'line1\ninserted\nline2\nline3\n', 'simple add')

-- Test 2: Simple remove
print('\n--- Test: simple remove ---')
old = 'line1\nremove_me\nline3\n'
diff = [[--- a/test.txt
+++ b/test.txt
@@ -1,3 +1,2 @@
 line1
-remove_me
 line3
]]
result = Diff.patch(diff, old)
assert_eq(result, 'line1\nline3\n', 'simple remove')

-- Test 3: Replace (remove + add)
print('\n--- Test: replace ---')
old = 'line1\nold_line\nline3\n'
diff = [[--- a/test.txt
+++ b/test.txt
@@ -1,3 +1,3 @@
 line1
-old_line
+new_line
 line3
]]
result = Diff.patch(diff, old)
assert_eq(result, 'line1\nnew_line\nline3\n', 'replace')

-- Test 4: Multiple hunks
print('\n--- Test: multiple hunks ---')
old = 'a\nb\nc\nd\ne\nf\ng\nh\n'
diff = [[--- a/test.txt
+++ b/test.txt
@@ -1,4 +1,4 @@
 a
-b
+c
 c
 d
@@ -5,4 +5,5 @@
 e
 f
+inserted
 g
 h
]]
result = Diff.patch(diff, old)
assert_eq(result, 'a\nc\nc\nd\ne\nf\ninserted\ng\nh\n', 'multiple hunks')

-- Test 5: Parse only
print('\n--- Test: parse structure ---')
diff = [[diff --git a/src/foo.lua b/src/foo.lua
index abc123..def456 100644
--- a/src/foo.lua
+++ b/src/foo.lua
@@ -5,3 +5,4 @@
 old
+new
 context
]]
local files = Diff.parse(diff)
assert_eq(#files, 1, 'parse returns one file')
assert_eq(files[1].old_path, 'src/foo.lua', 'old_path stripped a/')
assert_eq(files[1].new_path, 'src/foo.lua', 'new_path stripped b/')
assert_eq(#files[1].hunks, 1, 'one hunk parsed')
assert_eq(files[1].hunks[1].old_start, 5, 'hunk old_start')
assert_eq(files[1].hunks[1].new_start, 5, 'hunk new_start')
assert_eq(#files[1].hunks[1].lines, 3, 'hunk has 3 diff lines')

-- Test 6: Empty file (new file)
print('\n--- Test: new file ---')
diff = [[diff --git a/new.txt b/new.txt
new file mode 100644
--- /dev/null
+++ b/new.txt
@@ -0,0 +1,2 @@
+first line
+second line
]]
result = Diff.patch(diff, '', 'new.txt')
assert_eq(result, 'first line\nsecond line\n', 'new file from empty')

-- Test 7: No trailing newline
print('\n--- Test: no trailing newline ---')
old = 'line1\nline2'
diff = [[--- a/test.txt
+++ b/test.txt
@@ -1,2 +1,2 @@
 line1
-line2
+line2_fixed
]]
result = Diff.patch(diff, old)
assert_eq(result, 'line1\nline2_fixed', 'no trailing newline preserved')

-- Summary
print('\n============================')
print(string.format('Results: %d passed, %d failed', passed, failed))
if failed > 0 then
  print('FAILED')
else
  print('ALL TESTS PASSED')
end
