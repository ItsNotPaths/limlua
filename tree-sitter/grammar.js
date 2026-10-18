/**
 * @file limlua grammar for tree-sitter
 * @license MIT
 * Based on tree-sitter-lua by Munif Tanjim (MIT).
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const PREC = {
  OR: 1, // or ||
  AND: 2, // and &&
  COMPARE: 3, // < > <= >= != ==
  BIT_OR: 4, // |
  BIT_XOR: 5, // ~
  BIT_AND: 6, // &
  BIT_SHIFT: 7, // << >>
  CONCAT: 8, // ..
  PLUS: 9, // + -
  MULTI: 10, // * / %
  UNARY: 11, // not ! - ~
  POWER: 12, // ^
};

const list_seq = (rule, separator, trailing_separator = false) =>
  trailing_separator
    ? seq(rule, repeat(seq(separator, rule)), optional(separator))
    : seq(rule, repeat(seq(separator, rule)));

const name_list = ($) => list_seq(field('name', $.identifier), ',');

export default grammar({
  name: 'lim',

  extras: ($) => [$.comment, /\s/],

  externals: ($) => [
    $._block_comment,
    $._block_string_start,
    $._block_string_content,
    $._block_string_end,
    $._same_line, // zero width: a name follows on this line (break name / continue name)
  ],

  supertypes: ($) => [$.statement, $.expression, $.declaration, $.variable],

  word: ($) => $.identifier,

  conflicts: ($) => [[$.variable, $.labeled_statement]],

  rules: {
    chunk: ($) =>
      seq(
        optional($.hash_bang_line),
        repeat($.statement),
        optional($.return_statement)
      ),

    hash_bang_line: (_) => /#.*/,

    block: ($) =>
      seq('{', repeat($.statement), optional($.return_statement), '}'),

    statement: ($) =>
      choice(
        $.empty_statement,
        $.assignment_statement,
        $.compound_assignment,
        $.function_call,
        $.label_statement,
        $.break_statement,
        $.continue_statement,
        $.goto_statement,
        $.block_statement,
        $.while_statement,
        $.repeat_statement,
        $.if_statement,
        $.for_statement,
        $.labeled_statement,
        $.declaration
      ),

    return_statement: ($) =>
      seq(
        'return',
        optional(alias($._expression_list, $.expression_list)),
        optional(';')
      ),

    empty_statement: (_) => ';',

    assignment_statement: ($) =>
      seq(
        alias($._variable_assignment_varlist, $.variable_list),
        field('operator', '='),
        alias($._variable_assignment_explist, $.expression_list)
      ),
    _variable_assignment_varlist: ($) =>
      list_seq(field('name', $.variable), ','),
    _variable_assignment_explist: ($) =>
      list_seq(field('value', $.expression), ','),

    // x += e, one target
    compound_assignment: ($) =>
      seq(
        field('name', $.variable),
        field('operator', choice('+=', '-=', '*=', '/=', '%=', '..=')),
        field('value', $.expression)
      ),

    // x++ / x--: only a c-style for step
    update_statement: ($) =>
      seq(field('name', $.variable), field('operator', choice('++', '--'))),

    label_statement: ($) => seq('::', $.identifier, '::'),

    break_statement: ($) =>
      seq('break', optional(seq($._same_line, field('label', $.identifier)))),

    continue_statement: ($) =>
      seq('continue', optional(seq($._same_line, field('label', $.identifier)))),

    goto_statement: ($) => seq('goto', $.identifier),

    block_statement: ($) => field('body', $.block),

    // name: for/while/repeat/{ }
    labeled_statement: ($) =>
      seq(
        field('label', $.identifier),
        ':',
        field(
          'body',
          choice(
            $.for_statement,
            $.while_statement,
            $.repeat_statement,
            $.block_statement
          )
        )
      ),

    while_statement: ($) =>
      seq('while', field('condition', $.expression), field('body', $.block)),

    repeat_statement: ($) =>
      seq(
        'repeat',
        field('body', $.block),
        'until',
        field('condition', $.expression)
      ),

    if_statement: ($) =>
      seq(
        'if',
        field('condition', $.expression),
        field('consequence', $.block),
        repeat(field('alternative', $.elseif_statement)),
        optional(field('alternative', $.else_statement))
      ),
    elseif_statement: ($) =>
      seq(
        choice('elseif', seq('else', 'if')),
        field('condition', $.expression),
        field('consequence', $.block)
      ),
    else_statement: ($) => seq('else', field('body', $.block)),

    for_statement: ($) =>
      seq(
        'for',
        field(
          'clause',
          choice($.for_generic_clause, $.for_numeric_clause, $.for_c_clause)
        ),
        field('body', $.block)
      ),
    for_generic_clause: ($) =>
      seq(
        alias($._name_list, $.variable_list),
        'in',
        alias($._expression_list, $.expression_list)
      ),
    for_numeric_clause: ($) =>
      seq(
        field('name', $.identifier),
        field('operator', '='),
        field('start', $.expression),
        ',',
        field('end', $.expression),
        optional(seq(',', field('step', $.expression)))
      ),
    // i = 0; cond; step
    for_c_clause: ($) =>
      seq(
        field('name', $.identifier),
        field('operator', '='),
        field('start', $.expression),
        ';',
        optional(field('condition', $.expression)),
        ';',
        optional(
          field(
            'step',
            choice(
              $.assignment_statement,
              $.compound_assignment,
              $.update_statement,
              $.function_call
            )
          )
        )
      ),
    _name_list: ($) => name_list($),

    declaration: ($) =>
      choice(
        $.function_declaration,
        field(
          'local_declaration',
          alias($._local_function_declaration, $.function_declaration)
        ),
        field('local_declaration', $.variable_declaration)
      ),
    function_declaration: ($) =>
      seq('function', field('name', $._function_name), $._function_body),
    _local_function_declaration: ($) =>
      seq('local', 'function', field('name', $.identifier), $._function_body),
    _function_name: ($) =>
      choice(
        $._function_name_prefix_expression,
        alias(
          $._function_name_method_index_expression,
          $.method_index_expression
        )
      ),
    _function_name_prefix_expression: ($) =>
      choice(
        $.identifier,
        alias($._function_name_dot_index_expression, $.dot_index_expression)
      ),
    _function_name_dot_index_expression: ($) =>
      seq(
        field('table', $._function_name_prefix_expression),
        '.',
        field('field', $.identifier)
      ),
    _function_name_method_index_expression: ($) =>
      seq(
        field('table', $._function_name_prefix_expression),
        ':',
        field('method', $.identifier)
      ),

    variable_declaration: ($) =>
      seq(
        'local',
        choice(
          alias($._att_name_list, $.variable_list),
          alias($._variable_assignment, $.assignment_statement)
        )
      ),
    _variable_assignment: ($) =>
      seq(
        alias($._att_name_list, $.variable_list),
        field('operator', '='),
        alias($._variable_assignment_explist, $.expression_list)
      ),
    _att_name_list: ($) =>
      list_seq(
        seq(
          field('name', $.identifier),
          optional(field('attribute', alias($._attrib, $.attribute)))
        ),
        ','
      ),
    _attrib: ($) => seq('<', $.identifier, '>'),

    _expression_list: ($) => list_seq($.expression, ','),

    expression: ($) =>
      choice(
        $.nil,
        $.false,
        $.true,
        $.number,
        $.string,
        $.vararg_expression,
        $.function_definition,
        $.variable,
        $.function_call,
        $.parenthesized_expression,
        $.table_constructor,
        $.binary_expression,
        $.unary_expression
      ),

    nil: (_) => 'nil',
    false: (_) => 'false',
    true: (_) => 'true',

    number: (_) => {
      function number_literal(digits, exponent_marker, exponent_digits) {
        return choice(
          seq(digits, /U?LL/i),
          seq(
            choice(
              seq(optional(digits), optional('.'), digits),
              seq(digits, optional('.'), optional(digits))
            ),
            optional(
              seq(
                choice(
                  exponent_marker.toLowerCase(),
                  exponent_marker.toUpperCase()
                ),
                seq(optional(choice('-', '+')), exponent_digits)
              )
            ),
            optional(choice('i', 'I'))
          )
        );
      }

      const decimal_digits = /[0-9]+/;
      const decimal_literal = number_literal(decimal_digits, 'e', decimal_digits);
      const hex_digits = /[a-fA-F0-9]+/;
      const hex_literal = seq(
        choice('0x', '0X'),
        number_literal(hex_digits, 'p', decimal_digits)
      );
      return token(choice(decimal_literal, hex_literal));
    },

    string: ($) => choice($._quote_string, $._block_string),

    _quote_string: ($) =>
      choice(
        seq(
          field('start', alias('"', '"')),
          field(
            'content',
            optional(alias($._doublequote_string_content, $.string_content))
          ),
          field('end', alias('"', '"'))
        ),
        seq(
          field('start', alias("'", "'")),
          field(
            'content',
            optional(alias($._singlequote_string_content, $.string_content))
          ),
          field('end', alias("'", "'"))
        )
      ),
    _doublequote_string_content: ($) =>
      repeat1(choice(token.immediate(prec(1, /[^"\\]+/)), $.escape_sequence)),
    _singlequote_string_content: ($) =>
      repeat1(choice(token.immediate(prec(1, /[^'\\]+/)), $.escape_sequence)),
    _block_string: ($) =>
      seq(
        field('start', alias($._block_string_start, '[[')),
        field('content', alias($._block_string_content, $.string_content)),
        field('end', alias($._block_string_end, ']]'))
      ),

    escape_sequence: () =>
      token.immediate(
        seq(
          '\\',
          choice(
            /[\nabfnrtv\\'"]/,
            /z\s*/,
            /[0-9]{1,3}/,
            /x[0-9a-fA-F]{2}/,
            /u\{[0-9a-fA-F]+\}/
          )
        )
      ),

    vararg_expression: (_) => '...',

    function_definition: ($) => seq('function', $._function_body),
    _function_body: ($) =>
      seq(field('parameters', $.parameters), field('body', $.block)),
    parameters: ($) => seq('(', optional($._parameter_list), ')'),
    _parameter_list: ($) =>
      choice(
        seq(name_list($), optional(seq(',', $.vararg_expression))),
        $.vararg_expression
      ),

    _prefix_expression: ($) =>
      prec(1, choice($.variable, $.function_call, $.parenthesized_expression)),

    variable: ($) =>
      choice($.identifier, $.bracket_index_expression, $.dot_index_expression),
    bracket_index_expression: ($) =>
      seq(
        field('table', $._prefix_expression),
        '[',
        field('field', $.expression),
        ']'
      ),
    dot_index_expression: ($) =>
      seq(
        field('table', $._prefix_expression),
        '.',
        field('field', $.identifier)
      ),

    function_call: ($) =>
      seq(
        field('name', choice($._prefix_expression, $.method_index_expression)),
        field('arguments', $.arguments)
      ),
    method_index_expression: ($) =>
      seq(
        field('table', $._prefix_expression),
        ':',
        field('method', $.identifier)
      ),
    // calls always need ( )
    arguments: ($) => seq('(', optional(list_seq($.expression, ',')), ')'),

    parenthesized_expression: ($) => seq('(', $.expression, ')'),

    table_constructor: ($) => seq('{', optional($._field_list), '}'),
    _field_list: ($) => list_seq($.field, $._field_sep, true),
    _field_sep: (_) => choice(',', ';'),
    field: ($) =>
      choice(
        seq(
          '[',
          field('name', $.expression),
          ']',
          field('operator', '='),
          field('value', $.expression)
        ),
        seq(field('name', $.identifier), '=', field('value', $.expression)),
        field('value', $.expression)
      ),

    binary_expression: ($) =>
      choice(
        ...[
          ['or', PREC.OR],
          ['||', PREC.OR],
          ['and', PREC.AND],
          ['&&', PREC.AND],
          ['<', PREC.COMPARE],
          ['<=', PREC.COMPARE],
          ['==', PREC.COMPARE],
          ['!=', PREC.COMPARE],
          ['>=', PREC.COMPARE],
          ['>', PREC.COMPARE],
          ['|', PREC.BIT_OR],
          ['~', PREC.BIT_XOR],
          ['&', PREC.BIT_AND],
          ['<<', PREC.BIT_SHIFT],
          ['>>', PREC.BIT_SHIFT],
          ['+', PREC.PLUS],
          ['-', PREC.PLUS],
          ['*', PREC.MULTI],
          ['/', PREC.MULTI],
          ['%', PREC.MULTI],
        ].map(([operator, precedence]) =>
          prec.left(
            precedence,
            seq(
              field('left', $.expression),
              field('operator', operator),
              field('right', $.expression)
            )
          )
        ),
        ...[
          ['..', PREC.CONCAT],
          ['^', PREC.POWER],
        ].map(([operator, precedence]) =>
          prec.right(
            precedence,
            seq(
              field('left', $.expression),
              field('operator', operator),
              field('right', $.expression)
            )
          )
        )
      ),

    unary_expression: ($) =>
      prec.left(
        PREC.UNARY,
        seq(
          field('operator', choice('not', '!', '-', '~')),
          field('operand', $.expression)
        )
      ),

    identifier: (_) => {
      const identifier_start =
        /[^\p{Control}\s+\-*/%^#&~|<>=!(){}\[\];:,.\\'"\d]/;
      const identifier_continue =
        /[^\p{Control}\s+\-*/%^#&~|<>=!(){}\[\];:,.\\'"]*/;
      return token(seq(identifier_start, identifier_continue));
    },

    // '//' to end of line, or nested '/* */' (external)
    comment: ($) => choice(token(seq('//', /[^\r\n]*/)), $._block_comment),
  },
});
