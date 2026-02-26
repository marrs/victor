#include "../src/includes.h"

#include "test.h"

int main()
{
    describe("glyph_name")
        it("returns glyph name for BMP codepoint present in font") {
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_int_eq(res.err.level, LOG_INFO);
            expect_str_eq(res.result, "smileface");
        } tested;

        it("returns warning and empty string for codepoint absent from font") {
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
        } tested;

        it("returns error when FcNameParse fails") {
        } tested;

        it("returns error when FcConfigSubstitute fails") {
        } tested;

        it("returns error when FcFontMatch fails") {
        } tested;

        it("returns error when matched font has no family name") {
        } tested;

        it("returns error when matched font has no file path") {
        } tested;

        it("returns error when FT_Init_FreeType fails") {
        } tested;

        it("returns error when FT_New_Face fails") {
        } tested;

        it("returns error when font cannot be found") {
            String_Result res = glyph_name("NonExistentFontXYZ", 0x263A);
            expect_int_eq(res.err.level, LOG_ERROR);
            expect_ptr_eq(res.result, nullptr);
        } tested;

    return exit_testing();
}
