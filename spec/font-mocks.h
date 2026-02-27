#pragma once
#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <string.h>
#include <strings.h>

struct Mock_State {
    bool        fc_name_parse_fail;
    bool        fc_sub_fail;
    bool        fc_match_fail;
    bool        fc_no_family;
    const char *fc_family;
    bool        fc_no_filepath;
    int         ft_init_err;
    int         ft_face_err;
    FT_UInt     glyph_idx;
    bool        has_glyph_names;
    const char *post_name; // "" or nullptr → AGL fallback
};

Mock_State mock;

void mock_reset(const char *family)
{
    mock = {};
    mock.fc_family       = family;
    mock.glyph_idx       = 42;
    mock.has_glyph_names = true;
    mock.post_name       = "";
}

// --- dummy storage for opaque FC/FT pointer types ---
static int dummy_pat_storage;
static int dummy_match_storage;
static int dummy_lib_storage;
static FT_FaceRec_ dummy_face;

extern "C" {

// --- FontConfig mocks ---

FcBool FcInit() { return FcTrue; }
void   FcDefaultSubstitute(FcPattern *) {}
void   FcPatternDestroy(FcPattern *) {}

FcPattern *FcNameParse(const FcChar8 *)
{
    if (mock.fc_name_parse_fail) return nullptr;
    return (FcPattern *)&dummy_pat_storage;
}

FcBool FcConfigSubstitute(FcConfig *, FcPattern *, FcMatchKind)
{
    if (mock.fc_sub_fail) return FcFalse;
    return FcTrue;
}

FcPattern *FcFontMatch(FcConfig *, FcPattern *, FcResult *)
{
    if (mock.fc_match_fail) return nullptr;
    return (FcPattern *)&dummy_match_storage;
}

FcResult FcPatternGetString(const FcPattern *, const char *object,
                            int, FcChar8 **s)
{
    if (strcmp(object, FC_FAMILY) == 0) {
        if (mock.fc_no_family) return FcResultNoMatch;
        *s = (FcChar8 *)mock.fc_family;
        return FcResultMatch;
    }
    if (strcmp(object, FC_FILE) == 0) {
        if (mock.fc_no_filepath) return FcResultNoMatch;
        static char dummy_path[] = "/dummy/font.ttf";
        *s = (FcChar8 *)dummy_path;
        return FcResultMatch;
    }
    return FcResultNoMatch;
}

int FcStrCmpIgnoreCase(const FcChar8 *s1, const FcChar8 *s2)
{
    return strcasecmp((const char *)s1, (const char *)s2);
}

// --- FreeType mocks ---

FT_Error FT_Init_FreeType(FT_Library *lib)
{
    if (mock.ft_init_err) return mock.ft_init_err;
    *lib = (FT_Library)&dummy_lib_storage;
    return 0;
}

FT_Error FT_New_Face(FT_Library, const char *, FT_Long, FT_Face *face)
{
    if (mock.ft_face_err) return mock.ft_face_err;
    dummy_face              = {};
    dummy_face.num_charmaps = 0;
    dummy_face.face_flags   = mock.has_glyph_names ? FT_FACE_FLAG_GLYPH_NAMES : 0;
    *face = &dummy_face;
    return 0;
}

FT_Error FT_Done_FreeType(FT_Library) { return 0; }
FT_Error FT_Done_Face(FT_Face) { return 0; }
FT_Error FT_Set_Charmap(FT_Face, FT_CharMap) { return 0; }

FT_UInt FT_Get_Char_Index(FT_Face, FT_ULong)
{
    return mock.glyph_idx;
}

FT_Error FT_Get_Glyph_Name(FT_Face, FT_UInt, FT_Pointer buf, FT_UInt buf_len)
{
    if (mock.post_name && mock.post_name[0] != '\0') {
        strncpy((char *)buf, mock.post_name, buf_len);
        ((char *)buf)[buf_len - 1] = '\0';
    } else {
        ((char *)buf)[0] = '\0';
    }
    return 0;
}

} // extern "C"
