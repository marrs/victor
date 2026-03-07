    describe("rewrite_fennel_err")
        it("rewrites [string ...]:N: prefix to filepath:lineno: with correct line offset") {
            char out[256];
            rewrite_fennel_err(out, sizeof(out),
                "[string \"(do (local a 1)(local b 2)(local c 3)...\"]:3: some error",
                "foo.ms", 10);
            expect_str_eq(out, "foo.ms:13: some error");
        } tested;

        it("passes through messages that do not start with [string") {
            char out[256];
            rewrite_fennel_err(out, sizeof(out),
                "some other error", "foo.ms", 5);
            expect_str_eq(out, "foo.ms:5: some other error");
        } tested;

        it("handles a block error on the first line") {
            char out[256];
            rewrite_fennel_err(out, sizeof(out),
                "[string \"(do (local x 1))\"]:1: some error",
                "bar.ms", 7);
            expect_str_eq(out, "bar.ms:8: some error");
        } tested;

    describe("groff_stem")
        it("strips directory and extension from a simple path") {
            char buf[256];
            groff_stem("path/to/report.ms", buf, sizeof(buf));
            expect_str_eq(buf, "report");
        } tested;

        it("handles a path with no directory component") {
            char buf[256];
            groff_stem("report.ms", buf, sizeof(buf));
            expect_str_eq(buf, "report");
        } tested;

        it("handles a path with no extension") {
            char buf[256];
            groff_stem("path/to/report", buf, sizeof(buf));
            expect_str_eq(buf, "report");
        } tested;

    {
        lua_State *groff_lua = fennel_init();

        // Holds a fixture path and its derived EPS path under a given directory.
        // Call cleanup() when done.
        struct Vic_Fixture {
            char fix_path[32];
            char eps_path[128];

            static Vic_Fixture make(const char *expr, const char *dir) {
                Vic_Fixture res;
                char body[256];
                snprintf(body, sizeof(body), ".VIC\n%s\n.ENDVIC\n", expr);
                make_fixture(res.fix_path, body);
                char stem[64];
                groff_stem(res.fix_path, stem, sizeof(stem));
                if (dir)
                    snprintf(res.eps_path, sizeof(res.eps_path), "%s/%s.0.eps", dir, stem);
                else
                    snprintf(res.eps_path, sizeof(res.eps_path), "%s.0.eps", stem);
                return res;
            }

            void cleanup() const {
                remove(eps_path);
                remove(fix_path);
            }
        };

        // Evaluate a single-expression VIC block and return the content written
        // to the resulting EPS file. Cleans up both the fixture and EPS file.
        struct Vic_Eps {
            static void call(lua_State *lua, const char *expr, char *out, size_t outsz) {
                Vic_Fixture fix = Vic_Fixture::make(expr, nullptr);
                process_groff(lua, fix.fix_path);
                FILE *ef = fopen(fix.eps_path, "r");
                out[0] = '\0';
                if (ef) { size_t nr = fread(out, 1, outsz - 1, ef); out[nr] = '\0'; fclose(ef); }
                fix.cleanup();
            }
        };

        describe("process_groff stdout")
            it("passes through non-VIC lines unchanged") {
                char fix_path[32];
                make_fixture(fix_path, ".TL\nTest\n.PP\nHello\n");
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDOUT_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf, ".TL\nTest\n.PP\nHello\n");
            } tested;

            it("replaces .VIC/.ENDVIC block with .PSPIC directive") {
                char fix_path[32];
                make_fixture(fix_path,
                    ".PP\n"
                    ".VIC\n"
                    "\"test-eps-content\"\n"
                    ".ENDVIC\n"
                    ".PP\n");
                char stem[64];
                groff_stem(fix_path, stem, sizeof(stem));
                char eps_path[128];
                snprintf(eps_path, sizeof(eps_path), "%s.0.eps", stem);
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDOUT_FILENO);
                char expected[256];
                snprintf(expected, sizeof(expected),
                         ".PP\n.PSPIC %s\n.PP\n", eps_path);
                expect_str_eq(cap.buf, expected);
                remove(eps_path);
                remove(fix_path);
            } tested;

            it("increments filename counter across multiple VIC blocks") {
                char fix_path[32];
                make_fixture(fix_path,
                    ".VIC\n"
                    "\"first\"\n"
                    ".ENDVIC\n"
                    ".VIC\n"
                    "\"second\"\n"
                    ".ENDVIC\n");
                char stem[64];
                groff_stem(fix_path, stem, sizeof(stem));
                char eps0[128], eps1[128];
                snprintf(eps0, sizeof(eps0), "%s.0.eps", stem);
                snprintf(eps1, sizeof(eps1), "%s.1.eps", stem);
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDOUT_FILENO);
                char expected[512];
                snprintf(expected, sizeof(expected),
                         ".PSPIC %s\n.PSPIC %s\n", eps0, eps1);
                expect_str_eq(cap.buf, expected);
                remove(eps0);
                remove(eps1);
                remove(fix_path);
            } tested;

            it("passes through orphan .ENDVIC unchanged") {
                char fix_path[32];
                make_fixture(fix_path, ".PP\n.ENDVIC\n.PP\n");
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDOUT_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf, ".PP\n.ENDVIC\n.PP\n");
            } tested;

            it("emits a groff comment for a VIC block with a Fennel error") {
                char fix_path[32];
                make_fixture(fix_path,
                    ".VIC\n"
                    "(error \"intentional test error\")\n"
                    ".ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDOUT_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf, ".\\\" VIC block 0 failed\n");
            } tested;

            it("emits a groff comment when VIC block produces no string") {
                char fix_path[32];
                make_fixture(fix_path, ".VIC\nnil\n.ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDOUT_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf, ".\\\" VIC block 0: no output\n");
            } tested;

            it("vic_font is set to Times-Roman before VIC block evaluation") {
                char content[256];
                Vic_Eps::call(groff_lua, "vic_font", content, sizeof(content));
                expect_str_eq(content, "Times-Roman");
            } tested;

            it("vic_size is set to 10 before VIC block evaluation") {
                char content[256];
                Vic_Eps::call(groff_lua, "(tostring vic_size)", content, sizeof(content));
                expect_str_eq(content, "10");
            } tested;

        describe("process_groff stderr")
            it("writes error to stderr when file cannot be opened") {
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, "/nonexistent/path/file.ms");
                capture_end(&cap, STDERR_FILENO);
                expect_str_eq(cap.buf,
                    "[victor/groff] groff/cannot-open: cannot open '/nonexistent/path/file.ms'\n");
            } tested;

            it("writes error to stderr for a Fennel evaluation failure") {
                char fix_path[32];
                make_fixture(fix_path,
                    ".VIC\n"
                    "(error \"intentional test error\")\n"
                    ".ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_contains(cap.buf, "[victor/groff] groff/fennel-error:");
            } tested;

            it("includes filepath and line number in the Fennel error message") {
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, "spec/fixtures/fennel-error.ms");
                capture_end(&cap, STDERR_FILENO);
                expect_str_contains(cap.buf,
                    "spec/fixtures/fennel-error.ms:3:");
            } tested;

            it("writes warning to stderr for an orphan .ENDVIC") {
                char fix_path[32];
                make_fixture(fix_path, ".ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_contains(cap.buf, "[victor/groff] groff/orphan-endvic:");
                expect_str_contains(cap.buf, ":1: orphan .ENDVIC");
            } tested;

            it("writes warning to stderr for an unterminated .VIC block") {
                char fix_path[32];
                make_fixture(fix_path, ".VIC\n\"unclosed\"\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_contains(cap.buf, "[victor/groff] groff/unterminated-vic:");
                expect_str_contains(cap.buf, ":1: unterminated .VIC block");
            } tested;

            it("writes error to stderr when VIC block produces no string") {
                char fix_path[32];
                make_fixture(fix_path, ".VIC\nnil\n.ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_contains(cap.buf, "[victor/groff] groff/no-string:");
                expect_str_contains(cap.buf, ":1: VIC block 0 produced no string");
            } tested;

            it("writes error to stderr when EPS file cannot be written") {
                char fix_path[32];
                make_fixture(fix_path,
                    ".VIC\n"
                    "\"test-eps-content\"\n"
                    ".ENDVIC\n");
                fs_mock.fopen_write_fail = true;
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_contains(cap.buf, "[victor/groff] groff/eps-write-failed:");
            } tested;

        describe("process_groff intermediate dir")
            it("writes EPS to the given directory") {
                Vic_Fixture fix = Vic_Fixture::make("\"dir-test\"", "target");
                process_groff(groff_lua, fix.fix_path, "target");
                FILE *ef = fopen(fix.eps_path, "r");
                expect_ptr_neq(nullptr, ef);
                if (ef) fclose(ef);
                fix.cleanup();
            } tested;

            it("emits .PSPIC with the intermediate dir path") {
                Vic_Fixture fix = Vic_Fixture::make("\"dir-pspic\"", "target");
                Capture cap;
                capture_start(&cap, STDOUT_FILENO);
                process_groff(groff_lua, fix.fix_path, "target");
                capture_end(&cap, STDOUT_FILENO);
                char expected[256];
                snprintf(expected, sizeof(expected), ".PSPIC %s\n", fix.eps_path);
                expect_str_eq(cap.buf, expected);
                fix.cleanup();
            } tested;

        lua_close(groff_lua);
    }
