-- '#' comments. '#x' right after code is lua's length and gets a pointed error

local function compiles(src) return load(src) != nil end

local function err(src)
  local f, msg = load(src, "=src")
  assert(f == nil, "expected an error: " .. src)
  return msg
end

do
  assert(compiles("# a comment\nx = 1"), "line comment")
  assert(compiles("x = 1 # trailing"), "trailing comment")
  assert(compiles("x = 1 #"), "empty comment at eof")
  assert(compiles("#print(x)\nx = 1"), "commented-out code at line start")
  assert(compiles("  #print(x)"), "indented commented-out code")
  assert(compiles("#[[ long\ncomment ]] x = 1"), "long comment")
  assert(compiles("x = 1 #[==[ a ]] b ]==] y = 2"), "long comment with level")
  assert(compiles("x = 1 # (not code)"), "space after '#' then anything")
  assert(compiles("-- still a comment"), "-- comments stay")
  assert(load("return '#x', \"#\"")() == "#x", "'#' in strings is text")
  assert(load("return 1 #[[ c ]] + 1")() == 2, "long comment mid expression")
end

do
  local msg = err("local n = #t")
  assert(string.find(msg, "len(t)", 0, true), "names len(t): " .. msg)
  assert(string.find(msg, "'# t'", 0, true), "shows the comment spelling: " .. msg)
  assert(string.find(msg, "src:1:", 0, true), "points at the line: " .. msg)
  assert(string.find(err("x = 1\nprint(#list)"), "src:2:", 0, true), "line of the '#'")
  for _, tail in ipairs({"(t)", "{1}", "\"abc\"", "'abc'"}) do
    assert(string.find(err("x = #" .. tail), "len(...)", 0, true), "#" .. tail)
  end
end
