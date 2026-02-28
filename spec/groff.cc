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

        describe("process_groff stderr")
            it("writes error to stderr when file cannot be opened") {
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, "/nonexistent/path/file.ms");
                capture_end(&cap, STDERR_FILENO);
                expect_str_eq(cap.buf,
                    "[groff] groff/cannot-open: cannot open '/nonexistent/path/file.ms'\n");
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
                expect_str_contains(cap.buf, "[groff] groff/fennel-error:");
            } tested;

            it("writes warning to stderr for an orphan .ENDVIC") {
                char fix_path[32];
                make_fixture(fix_path, ".ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf,
                    "[groff] groff/orphan-endvic: orphan .ENDVIC\n");
            } tested;

            it("writes warning to stderr for an unterminated .VIC block") {
                char fix_path[32];
                make_fixture(fix_path, ".VIC\n\"unclosed\"\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf,
                    "[groff] groff/unterminated-vic: unterminated .VIC block\n");
            } tested;

            it("writes error to stderr when VIC block produces no string") {
                char fix_path[32];
                make_fixture(fix_path, ".VIC\nnil\n.ENDVIC\n");
                Capture cap;
                capture_start(&cap, STDERR_FILENO);
                process_groff(groff_lua, fix_path);
                capture_end(&cap, STDERR_FILENO);
                remove(fix_path);
                expect_str_eq(cap.buf,
                    "[groff] groff/no-string: VIC block 0 produced no string\n");
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
                expect_str_contains(cap.buf, "[groff] groff/eps-write-failed:");
            } tested;

        lua_close(groff_lua);
    }
