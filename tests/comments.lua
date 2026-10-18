// '//' line comments and nested '/* */' block comments. '--' is not a comment

local function err(src) {
  local f, msg = load(src, "=src")
  assert(f == nil, "expected an error: " .. src)
  return msg
}

local function has(s, part) { return string.find(s, part, 0, true) != nil }

{
  assert(load("// a comment\nreturn 1")() == 1, "line comment")
  assert(load("return 1 // trailing")() == 1, "trailing comment")
  assert(load("return 1 //")() == 1, "empty comment at eof")
  assert(load("return /* inline */ 1")() == 1, "block comment between tokens")
  assert(load("/* two\nlines */ return 2")() == 2, "block comment over lines")
  assert(load("/* outer /* inner */ still outer */ return 3")() == 3, "block comments nest")
  assert(load("/**/ return 4")() == 4, "empty block comment")
  assert(load("return '//', \"/*\"")() == "//", "comment marks in strings are text")
  assert(load("return 6 / 2")() == 3.0 && load("local x = 8 x /= 2 return x")() == 4.0, "/ and /= unchanged")
}

{
  local msg = err("x = 1 /* never\nclosed")
  assert(has(msg, "unfinished '/*' comment (opened at line 1)"), "unfinished block names its line: " .. msg)
  assert(has(err("/* /* */"), "unfinished '/*' comment"), "unbalanced nesting")
  assert(has(err("-- old lua comment"), "lim comments are '//', not '--'"), "-- points to //")
  assert(has(err("--[[ old block ]]"), "lim comments are '//', not '--'"), "--[[ points to //")
}
