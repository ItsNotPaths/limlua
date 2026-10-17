-- spellings: ! != && ||. != is gone, not/and/or stay

local function syntax_err(src, near)
  local f, msg = load(src)
  if f != nil then return false end
  return near == nil or string.find(msg, near, 0, true) != nil
end


-- Papyrus spellings
do
  local t, f = true, false
  assert((1 != 2) == true and (1 != 1) == false, "!=")
  assert(!f == true and !t == false and !nil == true, "!")
  assert(!!t == true and !!nil == false and !!0 == true, "!!")
  assert(!(1 == 2) == true and !(1 != 2) == false, "!(...)")
  assert((t && 1) == 1 and (f && 1) == false and (nil && 1) == nil, "&&")
  assert((f || 2) == 2 and (1 || 2) == 1 and (nil || f) == false, "||")
  for _, a in ipairs{true, false} do
    for _, b in ipairs{true, false} do
      for _, c in ipairs{1, false} do
        assert((!a && b || c) == ((not a and b) or c), "!a && b || c")
        assert((a || b && c) == (a or (b and c)), "&& binds tighter than ||")
        assert((!a == b) == ((not a) == b), "! binds tighter than ==")
      end
    end
  end
  assert((1 + 1 != 3 && 2 < 3) == true, "!= and && with arithmetic")
  assert((1||2) == 1 and (nil&&1) == nil, "no spaces")
  local n = 0
  local function bump() n += 1; return true end
  local _ = t || bump()
  _ = f && bump()
  assert(n == 0, "|| and && short-circuit")
end

-- spelling errors and token names
do
  assert(syntax_err("x = a | |b"), "| |")
  assert(syntax_err("x = a & &b"), "& &")
  assert(syntax_err("x = ! = 1"), "! =")
  assert(syntax_err("x != 1", "'!='"), "!= token name")
  assert(syntax_err("x = a ~= b"), "~= removed")
  assert(syntax_err("x && 1", "'&&'"), "&& token name")
  assert(syntax_err("x || 1", "'||'"), "|| token name")
  assert(syntax_err("x and 1", "'and'"), "and token name")
  assert(syntax_err("! 1", "'!'"), "! token name")
  assert(syntax_err("not 1", "'not'"), "not token name")
  assert(syntax_err("x = 1 | | 2", "'|'"), "| token name")
end
