// limlua external scanner: nested /* */ comments, [[ ]] / [==[ ]==] strings, and the
// zero-width token that lets `break name` / `continue name` take a name on the same line only.
// Block string scanning is from tree-sitter-lua by Munif Tanjim (MIT).

#include "tree_sitter/alloc.h"
#include "tree_sitter/parser.h"
#include <wctype.h>

enum TokenType {
  BLOCK_COMMENT,
  BLOCK_STRING_START,
  BLOCK_STRING_CONTENT,
  BLOCK_STRING_END,
  SAME_LINE,
};

typedef struct {
  uint8_t level_count;
} Scanner;

static inline void consume(TSLexer *lexer) { lexer->advance(lexer, false); }
static inline void skip(TSLexer *lexer) { lexer->advance(lexer, true); }

static inline bool consume_char(char c, TSLexer *lexer) {
  if (lexer->lookahead != c) return false;
  consume(lexer);
  return true;
}

static inline uint8_t consume_and_count_char(char c, TSLexer *lexer) {
  uint8_t count = 0;
  while (lexer->lookahead == c) {
    ++count;
    consume(lexer);
  }
  return count;
}

void *tree_sitter_lim_external_scanner_create(void) { return ts_calloc(1, sizeof(Scanner)); }

void tree_sitter_lim_external_scanner_destroy(void *payload) { ts_free(payload); }

unsigned tree_sitter_lim_external_scanner_serialize(void *payload, char *buffer) {
  buffer[0] = (char)((Scanner *)payload)->level_count;
  return 1;
}

void tree_sitter_lim_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  ((Scanner *)payload)->level_count = length > 0 ? (uint8_t)buffer[0] : 0;
}

static bool scan_block_start(Scanner *scanner, TSLexer *lexer) {
  if (consume_char('[', lexer)) {
    uint8_t level = consume_and_count_char('=', lexer);
    if (consume_char('[', lexer)) {
      scanner->level_count = level;
      return true;
    }
  }
  return false;
}

static bool scan_block_end(Scanner *scanner, TSLexer *lexer) {
  if (consume_char(']', lexer)) {
    uint8_t level = consume_and_count_char('=', lexer);
    if (scanner->level_count == level && consume_char(']', lexer)) return true;
  }
  return false;
}

static bool scan_block_content(Scanner *scanner, TSLexer *lexer) {
  while (lexer->lookahead != 0) {
    if (lexer->lookahead == ']') {
      lexer->mark_end(lexer);
      if (scan_block_end(scanner, lexer)) return true;
    } else {
      consume(lexer);
    }
  }
  return false;
}

// after '/': the rest of a nested block comment
static bool scan_block_comment(TSLexer *lexer) {
  unsigned depth = 1;
  if (!consume_char('*', lexer)) return false;
  while (depth > 0) {
    if (lexer->eof(lexer)) return false;
    if (consume_char('*', lexer)) {
      if (consume_char('/', lexer)) depth--;
    } else if (consume_char('/', lexer)) {
      if (consume_char('*', lexer)) depth++;
    } else {
      consume(lexer);
    }
  }
  lexer->mark_end(lexer);
  return true;
}

// zero width, just before a name that sits on this line
static bool scan_same_line(TSLexer *lexer) {
  while (lexer->lookahead == ' ' || lexer->lookahead == '\t') skip(lexer);
  lexer->mark_end(lexer);
  return iswalpha(lexer->lookahead) || lexer->lookahead == '_';
}

bool tree_sitter_lim_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  Scanner *scanner = (Scanner *)payload;
  bool recovering = valid_symbols[BLOCK_STRING_CONTENT] && valid_symbols[SAME_LINE];

  if (valid_symbols[BLOCK_STRING_END] && scan_block_end(scanner, lexer)) {
    scanner->level_count = 0;
    lexer->result_symbol = BLOCK_STRING_END;
    return true;
  }

  if (valid_symbols[BLOCK_STRING_CONTENT] && scan_block_content(scanner, lexer)) {
    lexer->result_symbol = BLOCK_STRING_CONTENT;
    return true;
  }

  if (valid_symbols[SAME_LINE] && !recovering && scan_same_line(lexer)) {
    lexer->result_symbol = SAME_LINE;
    return true;
  }

  while (iswspace(lexer->lookahead)) skip(lexer);

  if (valid_symbols[BLOCK_STRING_START] && scan_block_start(scanner, lexer)) {
    lexer->result_symbol = BLOCK_STRING_START;
    return true;
  }

  if (valid_symbols[BLOCK_COMMENT] && consume_char('/', lexer) && scan_block_comment(lexer)) {
    lexer->result_symbol = BLOCK_COMMENT;
    return true;
  }

  return false;
}
