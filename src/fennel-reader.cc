// --- Char classifiers ---

static bool is_whitespace(int ch) {
    return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
}

static bool is_bkt_open(int ch) {
    return ch == '(' || ch == '[' || ch == '{';
}

static bool is_bkt_closed(int ch) {
    return ch == ')' || ch == ']' || ch == '}';
}

// --- File utils ---

static void skip_line(FILE *fp) {
    int ch;
    while ((ch = fgetc(fp)) != EOF && ch != '\n');
}

// --- Form reader ---

// Skip whitespace and ; line comments. Returns first significant char or EOF.
static int skip_ws(FILE *fp) {
    for (;;) {
        int ch = fgetc(fp);
        if (ch == EOF) return EOF;
        if (ch == ';') { skip_line(fp); continue; }
        if (is_whitespace(ch)) continue;
        return ch;
    }
}

static int read_form(FILE *fp, Buf *buf);

// Read a string body (opening " already appended). Returns 0 or -1.
static int read_str_literal(FILE *fp, Buf *buf) {
    for (;;) {
        int ch = fgetc(fp);
        if (ch == EOF) return -1;
        if (buf_push(buf, (char)ch) < 0) return -1;
        if (ch == '\\') {
            ch = fgetc(fp);
            if (ch == EOF) return -1;
            if (buf_push(buf, (char)ch) < 0) return -1;
        } else if (ch == '"') return 0;
    }
}

// Read a delimited form body (opening bracket already appended). Returns 0 or -1.
static int read_delimited(FILE *fp, Buf *buf) {
    int depth = 1;
    while (depth > 0) {
        int ch = fgetc(fp);
        if (ch == EOF) return -1;
        if (ch == '"') {
            if (buf_push(buf, '"') < 0) return -1;
            if (read_str_literal(fp, buf) < 0) return -1;
        } else if (ch == ';') {
            skip_line(fp);
        } else {
            if (buf_push(buf, (char)ch) < 0) return -1;
            if      (is_bkt_open(ch))   depth++;
            else if (is_bkt_closed(ch)) depth--;
        }
    }
    return 0;
}

// Read one complete top-level Fennel form into buf.
// Returns 0 on success, 1 on clean EOF (no form), -1 on parse error.
static int read_form(FILE *fp, Buf *buf) {
    int ch = skip_ws(fp);
    if (ch == EOF) return 1;

    if (buf_push(buf, (char)ch) < 0) return -1;

    if (is_bkt_open(ch)) return read_delimited(fp, buf);
    if (ch == '"')        return read_str_literal(fp, buf);

    // Prefix reader macros — absorb the following form
    if (ch == '\'' || ch == '`' || ch == '#') return read_form(fp, buf);
    if (ch == ',') {
        int next = fgetc(fp);
        if (next == '@') {
            if (buf_push(buf, '@') < 0) return -1;
        } else if (next != EOF) {
            ungetc(next, fp);
        }
        return read_form(fp, buf);
    }

    // Atom: read until whitespace or bracket
    for (;;) {
        ch = fgetc(fp);
        if (ch == EOF) break;
        if (is_whitespace(ch)) break;
        if (is_bkt_open(ch) || is_bkt_closed(ch)) { ungetc(ch, fp); break; }
        if (buf_push(buf, (char)ch) < 0) return -1;
    }
    return 0;
}
