    describe("format_err")
        it("formats message as [context] code: msg") {
            char buf[256];
            Error err = {LOG_ERROR, "groff/test-code", "test message"};
            format_err("groff", err, buf, sizeof(buf));
            expect_str_eq(buf, "[groff] groff/test-code: test message");
        } tested;
