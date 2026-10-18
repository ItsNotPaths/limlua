-- '#' is not an operator. its error names len() and rawlen()

local function err(src) {
  local f, msg = load(src, "=src")
  assert(f == nil, "expected an error: " .. src)
  return msg
}

local function has(s, part) { return string.find(s, part, 0, true) != nil }

{
  local msg = err("local n = #items")
  assert(has(msg, "len(items)") && has(msg, "rawlen(items)"), "names both, with the operand: " .. msg)
  assert(has(msg, "src:1:"), "points at the line: " .. msg)
  assert(has(err("x = 1\ny = #list + 1"), "src:2:"), "line of the '#'")
  assert(has(err("x = #\"abc\""), "len(x)"), "placeholder when no name follows")
  assert(has(err("x = #(t)"), "len(x)"), "placeholder for '#('")
}

{
  assert(load("return '#x', \"#\"")() == "#x", "'#' in strings is text")
  assert(load("-- #t\nreturn 1")() == 1, "'#' in comments is text")
  assert(select("#", 1, 2) == 2, "select('#') still works")
}
