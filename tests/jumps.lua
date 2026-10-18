-- continue, and named loops/blocks with 'break name' / 'continue name'

local function err(src) {
  local f, msg = load(src, "=src")
  assert(f == nil, "expected an error: " .. src)
  return msg
}

local function has(s, part) { return string.find(s, part, 0, true) != nil }

-- continue in every loop kind
{
  local odd = {}
  for i = 0, 9 { if i % 2 == 0 { continue } odd[len(odd)] = i }
  assert(table.concat(odd, ",") == "1,3,5,7,9", "numeric for")
  local keys = 0
  for k, v in pairs({a = 1, b = 2, c = 3}) { if k == "b" { continue } keys += 1 }
  assert(keys == 2, "generic for")
  local n, hits = 0, 0
  while n < 10 { n += 1; if n < 8 { continue } hits += 1 }
  assert(hits == 3, "while")
  local k, seen = 0, 0
  repeat { k += 1; if k < 5 { continue } seen += 1 } until k >= 5
  assert(seen == 1, "repeat: continue still checks 'until'")
}

-- named loops
{
  local out = {}
  outer: for i = 0, 3 {
    for j = 0, 3 {
      if j == 2 { continue outer }
      if i == 2 { break outer }
      out[len(out)] = i .. j
    }
  }
  assert(table.concat(out, " ") == "00 01 10 11", "continue/break outer from inner loop")
  local depth = 0
  a: while true { b: repeat { c: for i = 0, 9 { depth = i; if i == 4 { break a } } } until false }
  assert(depth == 4, "break through three named loops")
  local inner = 0
  outer2: for i = 0, 2 { for j = 0, 2 { if j == 1 { continue } inner += 1 } }
  assert(inner == 6, "plain continue targets the innermost loop")
}

-- named blocks
{
  local reached = false
  blk: {
    for i = 0, 9 { if i == 1 { break blk } }
    reached = true
  }
  assert(!reached, "break a block from a loop inside it")
  local after = 0
  for i = 0, 2 { b: { if i == 1 { break b } after += 1 } }
  assert(after == 2, "break a block inside a loop keeps looping")
}

-- jumps close upvalues and <close> variables
{
  local fs = {}
  for i = 0, 2 { local v = i * 10; fs[i] = function() { return v } if i == 1 { continue } }
  assert(fs[0]() == 0 && fs[1]() == 10 && fs[2]() == 20, "fresh local per iteration")
  local closed = 0
  local mt = {__close = function() { closed += 1 }}
  for i = 0, 2 { local c <close> = setmetatable({}, mt); if i < 2 { continue } }
  assert(closed == 3, "<close> runs on continue")
  outer: for i = 0, 1 { for j = 0, 1 { local c <close> = setmetatable({}, mt); break outer } }
  assert(closed == 4, "<close> runs on break outer")
}

-- 'name:' only labels a loop or block; 'obj:m()' is still a call
{
  local t = {v = 0}
  function t:bump() { self.v += 1 }
  t:bump()
  assert(t.v == 1, "method call statement")
  local x = 0
  for i = 0, 1 { if i == 0 { break } }
  { x = 1 }
  assert(x == 1, "break, then a block")
}

-- a name only counts on the same line as break / continue
{
  local f = load("local n = 0\nfor i = 0, 1 { n += 1; if true { break }\nn += 10 }\nreturn n")
  assert(f() == 1, "break alone on its line")
}

-- errors
{
  assert(has(err("x = 1\ncontinue\n\ny = 2"), "src:2: 'continue' outside a loop"), "continue outside, at its line")
  assert(has(err("if x { break }"), "'break' outside a loop"), "break outside (fast path)")
  assert(has(err("for i = 0, 1 { f = function() { break } }"), "'break' outside a loop"), "loops do not cross functions")
  assert(has(err("for i = 0, 1 { continue foo }"), "no enclosing loop or block is named 'foo'"), "unknown name")
  assert(has(err("b: { continue b }"), "'b' is a block, not a loop; use 'break b'"), "continue a block")
  assert(has(err("x: for i = 0, 1 { x: for j = 0, 1 { } }"), "'x' already names an enclosing loop or block"), "shadowed name")
  assert(has(err("repeat { if a { continue } local z = 1 } until z"), "skips local 'z', which 'until' can still see"), "repeat scope")
  assert(has(err("goto continue"), "near 'continue'"), "continue is reserved")
  assert(has(err("goto continued; local z = 1; ::continued:: print(z)"), "<goto continued>"), "user labels keep the goto message")
}
