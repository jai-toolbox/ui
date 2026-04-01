#import "Basic";
#import "Hash_Table";
#import "File";
#import "stb_image";
#import "GL";

#import "tbx/opengl";
#import "tbx/json";
#import "Math";

/*
msdf : multi-channel signed distance field (used to render text).

We assume that you've generated an atlas with msdf-atlas-gen.

This file makes it easy to load in and use it.

*/

MSDF_Font :: struct {
    distance_range  : float32;
    atlas_size      : float32;
    atlas_w         : float32;
    atlas_h         : float32;
    y_origin_bottom : bool;

    line_height : float32;
    ascender    : float32;
    descender   : float32;

    glyphs : Table(u32, MSDF_Glyph);

    texture_id : GLuint;
}

MSDF_Glyph :: struct {
    advance      : float32;
    has_geometry : bool;

    plane_left   : float32;
    plane_bottom : float32;
    plane_right  : float32;
    plane_top    : float32;

    atlas_left   : float32;
    atlas_bottom : float32;
    atlas_right  : float32;
    atlas_top    : float32;
}

MSDF_Text_Geometry :: struct {
    indices             : [..] u32;
    positions           : [..] Vector3;
    texture_coordinates : [..] Vector2;
}

msdf_load_atlas_texture :: (png_path: string) -> GLuint {
    w, h, channels: s32;

    pixels := stbi_load(png_path.data, *w, *h, *channels, 4);
    assert(pixels != null, "Failed to load atlas image: %", png_path);
    defer stbi_image_free(pixels);

    print("Atlas loaded: %x%, original_channels=%, forced to 4\n", w, h, channels);

    tex: GLuint;
    glGenTextures(1, *tex);
    glBindTexture(GL_TEXTURE_2D, tex);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, cast(u32) w, cast(u32) h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    glBindTexture(GL_TEXTURE_2D, 0);

    return tex;
}

msdf_font_load :: (json_path: string, png_path: string) -> MSDF_Font {
    font: MSDF_Font;

    json_data, json_ok := read_entire_file(json_path);
    assert(json_ok, "Failed to read font JSON: %", json_path);

    root := json_parse(json_data);
    assert(root != null, "Failed to parse font JSON: %", json_path);
    defer json_free(root);

    atlas := json_get_object(root, "atlas");
    met   := json_get_object(root, "metrics");
    glyphs_arr := json_get_array(root, "glyphs");

    assert(atlas      != null, "Missing 'atlas' in font JSON: %", json_path);
    assert(met        != null, "Missing 'metrics' in font JSON: %", json_path);
    assert(glyphs_arr != null, "Missing 'glyphs' in font JSON: %", json_path);

    font.distance_range  = cast(float32) json_get_number(atlas, "distanceRange", 4);
    font.atlas_size      = cast(float32) json_get_number(atlas, "size", 32);
    font.atlas_w         = cast(float32) json_get_number(atlas, "width", 512);
    font.atlas_h         = cast(float32) json_get_number(atlas, "height", 512);
    font.y_origin_bottom = json_get_string(atlas, "yOrigin") == "bottom";

    font.line_height = cast(float32) json_get_number(met, "lineHeight", 1.2);
    font.ascender    = cast(float32) json_get_number(met, "ascender", 1.0);
    font.descender   = cast(float32) json_get_number(met, "descender", 0);

    glyph_count := json_array_count(glyphs_arr);
    init(*font.glyphs, cast(u32)(glyph_count * 2));

    for i : 0..glyph_count-1 {
        g := json_array_get(glyphs_arr, i);
        assert(g != null, "Null glyph entry at index % in font JSON: %", i, json_path);

        glyph: MSDF_Glyph;
        unicode := cast(u32) json_get_int(g, "unicode", 0);
        glyph.advance = cast(float32) json_get_number(g, "advance", 0);

        plane := json_get_object(g, "planeBounds");
        atl   := json_get_object(g, "atlasBounds");

        if plane != null && atl != null {
            glyph.has_geometry = true;

            glyph.plane_left   = cast(float32) json_get_number(plane, "left");
            glyph.plane_bottom = cast(float32) json_get_number(plane, "bottom");
            glyph.plane_right  = cast(float32) json_get_number(plane, "right");
            glyph.plane_top    = cast(float32) json_get_number(plane, "top");

            glyph.atlas_left   = cast(float32) json_get_number(atl, "left");
            glyph.atlas_bottom = cast(float32) json_get_number(atl, "bottom");
            glyph.atlas_right  = cast(float32) json_get_number(atl, "right");
            glyph.atlas_top    = cast(float32) json_get_number(atl, "top");
        }

        table_add(*font.glyphs, unicode, glyph);
    }

    font.texture_id = msdf_load_atlas_texture(png_path);

    return font;
}

msdf_font_destroy :: (font: *MSDF_Font) {
    if font.texture_id != 0 {
        glDeleteTextures(1, *font.texture_id);
        font.texture_id = 0;
    }
    deinit(*font.glyphs);
}

// geometry

msdf_generate_text_geometry :: (
    font: *MSDF_Font,
    text: string,
    x: float32,
    y: float32,
    font_size_px: float32,
    window_w: float32,
    window_h: float32
) -> MSDF_Text_Geometry, float32 /* total_advance_px */ {

    geometry: MSDF_Text_Geometry;
    cursor_x := x;
    scale := font_size_px;

    visible_count := 0;
    for i : 0..text.count-1 {
        cp := cast(u32) text[i];
        glyph_ptr := table_find_pointer(*font.glyphs, cp);
        if glyph_ptr != null && glyph_ptr.has_geometry  visible_count += 1;
    }

    array_reserve(*geometry.positions, visible_count * 4);
    array_reserve(*geometry.texture_coordinates, visible_count * 4);
    array_reserve(*geometry.indices, visible_count * 6);

    vertex_index: u32 = 0;

    for i : 0..text.count-1 {
        cp := cast(u32) text[i];

        glyph_ptr := table_find_pointer(*font.glyphs, cp);
        if glyph_ptr == null {
            glyph_ptr = table_find_pointer(*font.glyphs, cast(u32) #char "?");
            if glyph_ptr == null {
                cursor_x += font_size_px * 0.5;
                continue;
            }
        }

        glyph := << glyph_ptr;

        if glyph.has_geometry {
            quad_left   := cursor_x + glyph.plane_left   * scale;
            quad_right  := cursor_x + glyph.plane_right  * scale;
            quad_top    := y - glyph.plane_top    * scale;
            quad_bottom := y - glyph.plane_bottom * scale;

            ndc_left   := (quad_left   / window_w) * 2.0 - 1.0;
            ndc_right  := (quad_right  / window_w) * 2.0 - 1.0;
            ndc_top    := -((quad_top    / window_h) * 2.0 - 1.0);
            ndc_bottom := -((quad_bottom / window_h) * 2.0 - 1.0);

            u0 := glyph.atlas_left   / font.atlas_w;
            u1 := glyph.atlas_right  / font.atlas_w;
            v0: float32;
            v1: float32;

            if font.y_origin_bottom {
                v0 = glyph.atlas_bottom / font.atlas_h;
                v1 = glyph.atlas_top    / font.atlas_h;
            } else {
                v0 = 1.0 - glyph.atlas_top    / font.atlas_h;
                v1 = 1.0 - glyph.atlas_bottom / font.atlas_h;
            }

            array_add(*geometry.positions, .{ndc_left,  ndc_top,    0});
            array_add(*geometry.positions, .{ndc_right, ndc_top,    0});
            array_add(*geometry.positions, .{ndc_right, ndc_bottom, 0});
            array_add(*geometry.positions, .{ndc_left,  ndc_bottom, 0});

            array_add(*geometry.texture_coordinates, .{u0, v1});
            array_add(*geometry.texture_coordinates, .{u1, v1});
            array_add(*geometry.texture_coordinates, .{u1, v0});
            array_add(*geometry.texture_coordinates, .{u0, v0});

            array_add(*geometry.indices, vertex_index + 0);
            array_add(*geometry.indices, vertex_index + 2);
            array_add(*geometry.indices, vertex_index + 1);

            array_add(*geometry.indices, vertex_index + 0);
            array_add(*geometry.indices, vertex_index + 3);
            array_add(*geometry.indices, vertex_index + 2);

            vertex_index += 4;
        }

        cursor_x += glyph.advance * scale;
    }

    return geometry, cursor_x - x;
}

msdf_text_geometry_free :: (geometry: *MSDF_Text_Geometry) {
    array_free(geometry.indices);
    array_free(geometry.positions);
    array_free(geometry.texture_coordinates);
}

// measurement

msdf_measure_text :: (font: *MSDF_Font, text: string, font_size_px: float32) -> float32 {
    width: float32 = 0;
    for i : 0..text.count-1 {
        cp := cast(u32) text[i];
        ptr := table_find_pointer(*font.glyphs, cp);
        if ptr != null  width += ptr.advance * font_size_px;
        else            width += font_size_px * 0.5;
    }
    return width;
}

msdf_line_height :: (font: *MSDF_Font, font_size_px: float32) -> float32 {
    return font.line_height * font_size_px;
}

msdf_screen_pixels_per_distance_range :: (font: *MSDF_Font, font_size_px: float32) -> float32 {
    r := font.distance_range * (font_size_px / font.atlas_size);
    if r < 1.0 r = 1.0;
    return r;
}


msdf_draw_text_immediate :: (
    renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer,
    font: *MSDF_Font,
    text: string,
    x: float32,
    y: float32,
    font_size_px: float32,
    color: Vector4,
    window_w: float32,
    window_h: float32
) {
    geometry, total_advance := msdf_generate_text_geometry(
        font, text, x, y, font_size_px, window_w, window_h
    );
    defer msdf_text_geometry_free(*geometry);

    if geometry.indices.count == 0 return;

    // bind the shader first so uniform calls actually land
    glUseProgram(renderer.shader_program_gl_handle);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, font.texture_id);

    set_texture_sampler_uniform(renderer, 0);
    set_rgba_color_uniform(renderer, color);
    set_aspect_ratio_uniform(renderer, .{1.0, 1.0});
    px_range := msdf_screen_pixels_per_distance_range(font, font_size_px);

    glUniform1f(
        glGetUniformLocation(renderer.shader_program_gl_handle, "screen_pixels_per_distance_range"),
        px_range
    );

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    immediate_render(renderer,
        geometry.indices,
        geometry.positions,
        geometry.texture_coordinates
    );
}

// rendering (buffered mode)

msdf_create_text_renderable :: (
    renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer,
    font: *MSDF_Font,
    text: string,
    x: float32,
    y: float32,
    font_size_px: float32,
    window_w: float32,
    window_h: float32
) -> Multi_Channel_Signed_Distance_Field_Text_Renderable, bool {

    renderable: Multi_Channel_Signed_Distance_Field_Text_Renderable;

    geometry, total_advance := msdf_generate_text_geometry(
        font, text, x, y, font_size_px, window_w, window_h
    );

    array_copy(*renderable.indices, geometry.indices);
    array_copy(*renderable.positions, geometry.positions);
    array_copy(*renderable.texture_coordinates, geometry.texture_coordinates);
    msdf_text_geometry_free(*geometry);

    success := buffer_object(renderer, *renderable);
    return renderable, success;
}

msdf_queue_text :: (
    renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer,
    font: *MSDF_Font,
    renderable: Multi_Channel_Signed_Distance_Field_Text_Renderable,
    color: Vector4
) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, font.texture_id);

    set_texture_sampler_uniform(renderer, 0);
    set_rgba_color_uniform(renderer, color);
    set_aspect_ratio_uniform(renderer, .{1.0, 1.0});

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    queue_render(renderer, renderable);
}
