; helix scope names, which oket's themes resolve by dot fallback.
; the FIRST pattern to capture a node wins, so specific patterns come before general ones.

(comment) @comment

(hash_bang_line) @keyword.directive

; Literals
(nil) @constant.builtin

[
  (false)
  (true)
] @constant.builtin.boolean

(vararg_expression) @constant

(number) @constant.numeric

(escape_sequence) @constant.character.escape

(string) @string

; Keywords
[
  "local"
  "function"
] @keyword.function

[
  "if"
  "elseif"
  "else"
] @keyword.control.conditional

[
  "for"
  "in"
  "while"
  "repeat"
  "until"
] @keyword.control.repeat

[
  "return"
  "break"
  "continue"
  "goto"
] @keyword.control.return

[
  "and"
  "or"
  "not"
] @keyword.operator

; every name is plain `variable`, as in the lua grammar
(label_statement) @label

(identifier) @variable

; Operators and punctuation
(binary_expression
  operator: _ @operator)

(unary_expression
  operator: _ @operator)

(compound_assignment
  operator: _ @operator)

(update_statement
  operator: _ @operator)

"=" @operator

(table_constructor
  [
    "{"
    "}"
  ] @constructor)

[
  ";"
  ":"
  "::"
  ","
  "."
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket
