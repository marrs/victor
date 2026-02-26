#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <stdint.h>

static String_Result glyph_name(const char *font_name, uint32_t codepoint)
{
    // Static buffers — single-threaded tool
    static char name_buf[256];
    static char msg_buf[256];

    // Compute AGL name from codepoint
    if (codepoint <= 0xFFFF) {
        snprintf(name_buf, sizeof(name_buf), "uni%04X", codepoint);
    } else {
        snprintf(name_buf, sizeof(name_buf), "u%X", codepoint);
    }

    // FontConfig: resolve font name → file path
    FcInit();

    FcPattern *pat = FcNameParse((const FcChar8 *)font_name);
    if (!pat) {
        snprintf(msg_buf, sizeof(msg_buf), "FcNameParse failed for: %s", font_name);
        String_Result res = string_result("error", "font/fc-parse-failed", msg_buf, nullptr);
        print_err(res);
        return res;
    }

    if (!FcConfigSubstitute(nullptr, pat, FcMatchPattern)) {
        FcPatternDestroy(pat);
        snprintf(msg_buf, sizeof(msg_buf), "FcConfigSubstitute failed for: %s", font_name);
        String_Result res = string_result("error", "font/fc-substitute-failed", msg_buf, nullptr);
        print_err(res);
        return res;
    }
    FcDefaultSubstitute(pat);

    FcResult fc_res;
    FcPattern *match = FcFontMatch(nullptr, pat, &fc_res);
    FcPatternDestroy(pat);

    if (!match) {
        snprintf(msg_buf, sizeof(msg_buf), "FcFontMatch failed for: %s", font_name);
        String_Result res = string_result("error", "font/fc-match-failed", msg_buf, nullptr);
        print_err(res);
        return res;
    }

    // FontConfig always returns a fallback — verify the family name matches
    FcChar8 *matched_family = nullptr;
    if (FcPatternGetString(match, FC_FAMILY, 0, &matched_family) != FcResultMatch
            || !matched_family) {
        FcPatternDestroy(match);
        snprintf(msg_buf, sizeof(msg_buf), "no family name in match for: %s", font_name);
        String_Result res = string_result("error", "font/fc-no-family", msg_buf, nullptr);
        print_err(res);
        return res;
    }
    if (FcStrCmpIgnoreCase(matched_family, (const FcChar8 *)font_name) != 0) {
        FcPatternDestroy(match);
        snprintf(msg_buf, sizeof(msg_buf),
                 "font not found: %s (closest match: %s)", font_name, matched_family);
        String_Result res = string_result("error", "font/not-found", msg_buf, nullptr);
        print_err(res);
        return res;
    }

    FcChar8 *filepath = nullptr;
    if (FcPatternGetString(match, FC_FILE, 0, &filepath) != FcResultMatch || !filepath) {
        FcPatternDestroy(match);
        snprintf(msg_buf, sizeof(msg_buf), "no file path in match for: %s", font_name);
        String_Result res = string_result("error", "font/fc-no-filepath", msg_buf, nullptr);
        print_err(res);
        return res;
    }

    // FreeType: open face
    FT_Library ft;
    FT_Error ft_err = FT_Init_FreeType(&ft);
    if (ft_err) {
        FcPatternDestroy(match);
        snprintf(msg_buf, sizeof(msg_buf), "FT_Init_FreeType failed: %d", ft_err);
        String_Result res = string_result("error", "font/ft-init-failed", msg_buf, nullptr);
        print_err(res);
        return res;
    }

    FT_Face face;
    ft_err = FT_New_Face(ft, (const char *)filepath, 0, &face);
    FcPatternDestroy(match);
    if (ft_err) {
        FT_Done_FreeType(ft);
        snprintf(msg_buf, sizeof(msg_buf), "FT_New_Face failed (%d): %s", ft_err, font_name);
        String_Result res = string_result("error", "font/ft-open-failed", msg_buf, nullptr);
        print_err(res);
        return res;
    }

    // Find glyph index via Windows Unicode BMP cmap.
    for (int ci = 0; ci < face->num_charmaps; ci++) {
        FT_CharMap cm = face->charmaps[ci];
        if (cm->platform_id == 3 && cm->encoding_id == 1) {
            FT_Set_Charmap(face, cm);
            break;
        }
    }
    FT_UInt glyph_idx = FT_Get_Char_Index(face, codepoint);

    if (glyph_idx == 0) {
        FT_Done_Face(face);
        FT_Done_FreeType(ft);
        snprintf(msg_buf, sizeof(msg_buf),
                 "codepoint U+%04X absent from font %s", codepoint, font_name);
        String_Result res = string_result("warning", "font/glyph-absent", msg_buf, "");
        print_err(res);
        return res;
    }

    // Read the actual glyph name from the post table so GhostScript can look
    // it up by name.  Fall back to the AGL-derived name (already in name_buf)
    // if the font has no post names (format 3.0) or the stored name is empty,
    // and return a warning so the caller knows the name is unverified.
    if ((face->face_flags & FT_FACE_FLAG_GLYPH_NAMES) &&
            FT_Get_Glyph_Name(face, glyph_idx, name_buf, sizeof(name_buf)) == 0 &&
            name_buf[0] != '\0') {
        FT_Done_Face(face);
        FT_Done_FreeType(ft);
        String_Result res = string_result(nullptr, nullptr, nullptr, name_buf);
        print_err(res);
        return res;
    }

    FT_Done_Face(face);
    FT_Done_FreeType(ft);

    snprintf(msg_buf, sizeof(msg_buf),
             "no post table name for U+%04X in %s, using AGL fallback",
             codepoint, font_name);
    String_Result res = string_result("warning", "font/no-post-name", msg_buf, name_buf);
    print_err(res);
    return res;
}
