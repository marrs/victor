#include "../src/includes.h"

#include "test.h"

int main()
{
    describe("glyph_name")
        it("returns glyph name for BMP codepoint present in font") {
            String_Result res = glyph_name("FreeSans", 0x263A);
            expect_ptr_eq(res.err.level, nullptr);
            expect_str_eq(res.result, "smileface");
        } tested;

        it("returns warning and empty string for codepoint absent from font") {
            String_Result res = glyph_name("FreeSans", 0xFFFF);
            expect_str_eq(res.err.level, "warning");
            expect_str_eq(res.result, "");
        } tested;

        it("returns error when font cannot be found") {
            String_Result res = glyph_name("NonExistentFontXYZ", 0x263A);
            expect_str_eq(res.err.level, "error");
            expect_ptr_eq(res.result, nullptr);
        } tested;

    return exit_testing();
}
