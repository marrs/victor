    describe("glyph_name")
        it("returns glyph name for BMP codepoint present in font") {
            mock_reset("FreeSans");
            mock.post_name = "smileface";
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_INFO);
            expect_str_eq(res.result, "smileface");
        } tested;

        it("returns warning and empty string for codepoint absent from font") {
            mock_reset("FreeSans");
            mock.glyph_idx = 0;
            String_Result res = glyph_name("FreeSans", 0xFFFF);
            expect_int_eq(res.err.level, LOG_WARNING);
            expect_str_eq(res.result, "");
        } tested;

        it("returns warning when font name contains spaces") {
            String_Result res = glyph_name("DejaVu Sans", 0x263A);
            expect_int_eq(res.err.level, LOG_WARNING);
            expect_str_eq(res.err.code, "font/name-has-spaces");
            expect_str_eq(res.err.msg, "PostScript name tokens cannot contain spaces: DejaVu Sans");
            expect_str_eq(res.result, "");
        } tested;

        it("returns warning with AGL fallback name when font has no post table names") {
            mock_reset("FreeSans");
            mock.has_glyph_names = false;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_WARNING);
            expect_str_eq(res.result, "uni263A");
        } tested;

        it("returns error when FcNameParse fails") {
            mock_reset("FreeSans");
            mock.fc_name_parse_fail = true;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when FcConfigSubstitute fails") {
            mock_reset("FreeSans");
            mock.fc_sub_fail = true;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when FcFontMatch fails") {
            mock_reset("FreeSans");
            mock.fc_match_fail = true;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when matched font has no family name") {
            mock_reset("FreeSans");
            mock.fc_no_family = true;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when matched font has no file path") {
            mock_reset("FreeSans");
            mock.fc_no_filepath = true;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when FT_Init_FreeType fails") {
            mock_reset("FreeSans");
            mock.ft_init_err = 1;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when FT_New_Face fails") {
            mock_reset("FreeSans");
            mock.ft_face_err = 1;
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

        it("returns error when font cannot be found") {
            mock_reset("FreeSans");
            String_Result res = glyph_name("NonExistentFontXYZ", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;
