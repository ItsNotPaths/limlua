-- len(): every non-nil entry of a table, or the bytes of a string

{
  assert(len({}) == 0, "empty")
  assert(len({1, 2, 3}) == 3, "list")
  assert(len({1, nil, 3}) == 2, "holes are not entries")
  assert(len({a = 1, b = 2}) == 2, "string keys count")
  assert(len({[0] = 1, [-1] = 2, [0.5] = 3, [true] = 4}) == 4, "any key counts")
  assert(len({1, 2, x = "y"}) == 3, "list and map parts together")
}

{
  local t = {}
  for i = 0, 999 { t[i] = i }
  assert(len(t) == 1000, "grown")
  t[500] = nil
  t.name = "x"
  assert(len(t) == 1000, "delete one, add one")
  for i = 0, 999 { t[i] = nil }
  assert(len(t) == 1, "only the string key left")
  t.name = nil
  assert(len(t) == 0, "emptied")
}

{
  local inner = {1, 2, 3}
  assert(len({inner, inner}) == 2, "top layer only")
  local proxy = setmetatable({}, {__index = inner, __len = function() { return 99 }})
  assert(len(proxy) == 0, "metatables are ignored")
}

{
  assert(len("") == 0 and len("abc") == 3, "string bytes")
  assert(len("a\u{3B1}") == 3, "bytes, not characters")
}

local function rejects(v) {
  local ok, msg = pcall(len, v)
  return !ok && string.find(msg, "table or string expected", 0, true) != nil
}
assert(rejects(5) && rejects(nil) && rejects(true) && rejects(print), "only tables and strings")
