-- c-style for: for i = 0; cond; step { }

local function err(src) {
  local f, msg = load(src, "=src")
  assert(f == nil, "expected an error: " .. src)
  return msg
}

local function has(s, part) { return string.find(s, part, 0, true) != nil }

local function collect(f) {
  local out = {}
  f(function(v) { out[len(out)] = v })
  return table.concat(out, " ")
}

-- the basic loop, and each part being optional
{
  assert(collect(function(put) { for i = 0; i < 5; i += 1 { put(i) } }) == "0 1 2 3 4", "counts up")
  assert(collect(function(put) { for i = 10; i > 0; i = i // 2 { put(i) } }) == "10 5 2 1", "any step")
  assert(collect(function(put) { for i = 0; i < 0; i += 1 { put(i) } }) == "", "false at the start runs nothing")
  local n = 0
  for i = 0; ; i += 1 { n = i; if i == 7 { break } }
  assert(n == 7, "no condition loops until break")
  for i = 0; i < 3; { n = i; i += 1 }
  assert(n == 2, "no step: the body moves i")
  for i = 0; i < 3; n, i = n + 1, i + 1 { }
  assert(n == 5, "multiple assignment step")
  local t = {}
  for i = 0; i < 3; t[i] = true { i += 1 }
  assert(t[1] && t[2] && t[3], "step may write a table")
}

-- the variable
{
  local fs = {}
  for i = 0; i < 3; i += 1 { fs[i] = function() { return i } }
  assert(fs[0]() == 0 && fs[1]() == 1 && fs[2]() == 2, "closures see their own pass's i")
  assert(collect(function(put) { for i = 0; i < 10; i += 1 { if i == 4 { i += 3 } put(i) } }) == "0 1 2 3 7 8 9",
         "writes in the body carry into the step")
  assert(collect(function(put) { for i = 0; i < 3; i += 1 { local i = 9; put(i) } }) == "9 9 9",
         "a local in the body shadows i")
  local i = "outer"
  for i = 0; i < 2; i += 1 { }
  assert(i == "outer", "i is scoped to the loop")
}

-- steps of any shape run after the body
{
  assert(collect(function(put) { for i = 0; i < 9; i = i < 4 && i + 1 || i + 2 { put(i) } }) == "0 1 2 3 4 6 8",
         "step with and/or")
  assert(collect(function(put) {
    for i = 0; i < 3; i += 1 { for j = 0; j < i; j += 1 { for k = 0; k < 1; k += 1 { put(i .. j) } } }
  }) == "10 20 21", "nested loops")
  local n = 0
  local function each(f) { f() }
  for i = 0; i < 3; each(function() { for j = 0; j < 2; j += 1 { n += 1 } i += 1 }) { }
  assert(n == 6, "a loop inside a function in the step")
  local ok, msg = pcall(load("for i = 0; i < 3;\n  i = i + nil { }", "=src"))
  assert(!ok && has(msg, "src:2:"), "step errors report the step's line: " .. tostring(msg))
}

-- jumps
{
  assert(collect(function(put) { for i = 0; i < 10; i += 1 { if i % 3 != 0 { continue } put(i) } }) == "0 3 6 9",
         "continue runs the step")
  local n = 0
  outer: for i = 0; i < 3; i += 1 {
    for j = 0; j < 3; j += 1 { if j == 1 { continue outer } if i == 2 { break outer } n = i * 10 + j }
  }
  assert(n == 10, "named c-style loops")
  local closed = 0
  local mt = {__close = function() { closed += 1 }}
  for i = 0; i < 3; i += 1 { local c <close> = setmetatable({}, mt); if i < 2 { continue } }
  assert(closed == 3, "<close> runs on continue")
}

-- numeric for is unchanged
{
  assert(collect(function(put) { for i = 0, 2 { put(i) } }) == "0 1 2", "numeric for")
}

-- errors for C habits
{
  assert(has(err("for (i = 0; i < 3; i += 1) { }"), "lim's for has no parentheses"), "for (")
  assert(has(err("for i = 0; i < 3; i++ { }"), "lim has no '++'; use 'i += 1'"), "i++")
  local msg = err("for i = 9; i >= 0; i-- {\n  print(i)\n}")
  assert(has(msg, "src:1:") && has(msg, "'--' starts a comment); use 'i -= 1'"), "i-- at its line: " .. msg)
  assert(has(err("for i = 0 { }"), "',' (numeric for) or ';' (c-style for) expected"), "neither , nor ;")
  assert(has(err("for i = 0; i < 3 { }"), "';' expected: for i = 0; cond; step { }"), "missing second ;")
  assert(has(err("for i = 0; i < 3; local z = 1 { }"), "the step of a for is an assignment or a call"), "bad step")
}

-- '--' after a name with no space is only an error when it reads as a decrement
{
  assert(load("x = 1 -- note") != nil, "spaced comment")
  assert(load("x = y--note") != nil, "comment glued on both sides")
  assert(load("x = y--[[ c ]]") != nil, "long comment")
}
