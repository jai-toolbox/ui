#import "Basic";
#import "Hash_Table";
#import "File";

#import "tbx/json";
#import "tbx/assets";
#import "Math";

Distance_Field_Generation :: #import "tbx/distance_field_generation";

/*
msdf : multi-channel signed distance field (used to render text).

We assume that you've generated an atlas with msdf-atlas-gen.

This file makes it easy to load in and use it.

-----------
conventions

pixel space is measured from the top left of the screen
normalized space is specified as the space from ONE to -ONE in some dimension


-----------
terminology

px : pixel units
nrm : normalized space units
font size : The font size is a measurement in px, such that if the font size is N, then every glyph will fit in a square having side length N px (the em square)
em : the unit equal to the current font size, if font size is 32px then 1em = 32px.

*/

MSDF_Font :: struct {
    using #as data: Distance_Field_Generation.MSDF_Font_Data;

    glyphs : Table(u32, MSDF_Glyph);
    texture_handle: UI_Texture_Handle;
}

MSDF_Glyph :: Distance_Field_Generation.MSDF_Font_Glyph;

MSDF_Text_Geometry :: struct {
    using #as data: Distance_Field_Generation.MSDF_Text_Geometry_Data;
    positions: [..] Vector3;
}

load_msdf_font_metrics :: (json_path: string) -> font: MSDF_Font {
    font: MSDF_Font;

    json_ok: bool;
    json_data: string;
    json_data_is_owned := false;
    if assets_initialized {
        json_ok, json_data = load_asset(json_path);
    } else {
        json_data, json_ok = read_entire_file(json_path);
        json_data_is_owned = true;
    }
    assert(json_ok, "Failed to read font JSON: %", json_path);
    defer if json_data_is_owned && json_data.data free(json_data.data);

    root := json_parse(json_data);
    assert(root != null, "Failed to parse font JSON: %", json_path);
    defer json_free(root);

    atlas := json_get_object(root, "atlas");
    met   := json_get_object(root, "metrics");
    glyphs_arr := json_get_array(root, "glyphs");

    assert(atlas      != null, "Missing 'atlas' in font JSON: %", json_path);
    assert(met        != null, "Missing 'metrics' in font JSON: %", json_path);
    assert(glyphs_arr != null, "Missing 'glyphs' in font JSON: %", json_path);

    font.distance_range_atlas_px = cast(float32) json_get_number(atlas, "distanceRange", 4);
    font.atlas_em_size_px        = cast(float32) json_get_number(atlas, "size", 32);
    font.atlas_width_px          = cast(float32) json_get_number(atlas, "width", 512);
    font.atlas_height_px         = cast(float32) json_get_number(atlas, "height", 512);
    font.atlas_y_origin_bottom   = json_get_string(atlas, "yOrigin") == "bottom";

    font.line_height_em = cast(float32) json_get_number(met, "lineHeight", 1.2);
    font.ascender_em    = cast(float32) json_get_number(met, "ascender", 1.0);
    font.descender_em   = cast(float32) json_get_number(met, "descender", 0);

    glyph_count := json_array_count(glyphs_arr);

    for i : 0..glyph_count-1 {
        g := json_array_get(glyphs_arr, i);
        assert(g != null, "Null glyph entry at index % in font JSON: %", i, json_path);

        glyph: MSDF_Glyph;
        unicode := cast(u32) json_get_int(g, "unicode", 0);
        glyph.advance_em = cast(float32) json_get_number(g, "advance", 0);

        plane := json_get_object(g, "planeBounds");
        atl   := json_get_object(g, "atlasBounds");

        if plane != null && atl != null {
            glyph.has_geometry = true;

            glyph.plane_left_em   = cast(float32) json_get_number(plane, "left");
            glyph.plane_bottom_em = cast(float32) json_get_number(plane, "bottom");
            glyph.plane_right_em  = cast(float32) json_get_number(plane, "right");
            glyph.plane_top_em    = cast(float32) json_get_number(plane, "top");

            glyph.atlas_left_px   = cast(float32) json_get_number(atl, "left");
            glyph.atlas_bottom_px = cast(float32) json_get_number(atl, "bottom");
            glyph.atlas_right_px  = cast(float32) json_get_number(atl, "right");
            glyph.atlas_top_px    = cast(float32) json_get_number(atl, "top");
        }

        table_add(*font.glyphs, unicode, glyph);
    }

    return font;
}

deinit :: (font: *MSDF_Font) {
    deinit(*font.glyphs);
    font.* = .{};
}

// geometry

msdf_append_text_geometry :: (
    font: *MSDF_Font,
    text: string,
    left_edge_x_px: float32,
    baseline_y_px: float32,
    font_size_px: float32,
    window_w: float32,
    window_h: float32,
    color: Vector4,
    positions: *[..] Vector3,
    texture_coordinates: *[..] Vector2,
    rgba_colors: *[..] Vector4,
    indices: *[..] u32
) -> total_advance_px : float32 {
    cursor_x_px := left_edge_x_px;
    scale := font_size_px;

    visible_count := 0;
    for i : 0..text.count-1 {
        cp := cast(u32) text[i];
        glyph_ptr := table_find_pointer(*font.glyphs, cp);
        if glyph_ptr != null && glyph_ptr.has_geometry  visible_count += 1;
    }

    array_reserve(positions, positions.count + visible_count * 4);
    array_reserve(texture_coordinates, texture_coordinates.count + visible_count * 4);
    array_reserve(rgba_colors, rgba_colors.count + visible_count * 4);
    array_reserve(indices, indices.count + visible_count * 6);

    vertex_index := cast(u32) positions.count;

    for i : 0..text.count-1 {
        cp := cast(u32) text[i];

        glyph_ptr := table_find_pointer(*font.glyphs, cp);
        if glyph_ptr == null {
            glyph_ptr = table_find_pointer(*font.glyphs, cast(u32) #char "?");
            if glyph_ptr == null {
                cursor_x_px += font_size_px * 0.5;
                continue;
            }
        }

        glyph := glyph_ptr.*;

        if glyph.has_geometry {
            quad_left_px   := cursor_x_px + glyph.plane_left_em   * scale;
            quad_right_px  := cursor_x_px + glyph.plane_right_em  * scale;
            quad_top_px    := baseline_y_px - glyph.plane_top_em    * scale;
            quad_bottom_px := baseline_y_px - glyph.plane_bottom_em * scale;

            // this accounts for aspect ratio here, so in the msdf shader we don't actually need 
            // an aspect ratio adjustment hence why we pass {1, 1} to the shader right now (so we can remove that probably).
            ndc_left   := (quad_left_px   / window_w) * 2.0 - 1.0;
            ndc_right  := (quad_right_px  / window_w) * 2.0 - 1.0;
            ndc_top    := -((quad_top_px    / window_h) * 2.0 - 1.0);
            ndc_bottom := -((quad_bottom_px / window_h) * 2.0 - 1.0);

            u0 := glyph.atlas_left_px   / font.atlas_width_px;
            u1 := glyph.atlas_right_px  / font.atlas_width_px;
            v0: float32;
            v1: float32;

            if font.atlas_y_origin_bottom {
                v0 = glyph.atlas_bottom_px / font.atlas_height_px;
                v1 = glyph.atlas_top_px    / font.atlas_height_px;
            } else {
                v0 = 1.0 - glyph.atlas_top_px    / font.atlas_height_px;
                v1 = 1.0 - glyph.atlas_bottom_px / font.atlas_height_px;
            }

            array_add(positions, .{ndc_left,  ndc_top,    0});
            array_add(positions, .{ndc_right, ndc_top,    0});
            array_add(positions, .{ndc_right, ndc_bottom, 0});
            array_add(positions, .{ndc_left,  ndc_bottom, 0});

            array_add(texture_coordinates, .{u0, v1});
            array_add(texture_coordinates, .{u1, v1});
            array_add(texture_coordinates, .{u1, v0});
            array_add(texture_coordinates, .{u0, v0});

            array_add(rgba_colors, color);
            array_add(rgba_colors, color);
            array_add(rgba_colors, color);
            array_add(rgba_colors, color);

            array_add(indices, vertex_index + 0);
            array_add(indices, vertex_index + 2);
            array_add(indices, vertex_index + 1);

            array_add(indices, vertex_index + 0);
            array_add(indices, vertex_index + 3);
            array_add(indices, vertex_index + 2);

            vertex_index += 4;
        }

        cursor_x_px += glyph.advance_em * scale;
    }

    return cursor_x_px - left_edge_x_px;
}

msdf_generate_text_geometry :: (
    font: *MSDF_Font,
    text: string,
    left_edge_x_px: float32,
    baseline_y_px: float32,
    font_size_px: float32,
    window_w: float32,
    window_h: float32
) -> MSDF_Text_Geometry, total_advance_px : float32 {

    geometry: MSDF_Text_Geometry;
    total_advance_px = msdf_append_text_geometry(
        font,
        text,
        left_edge_x_px,
        baseline_y_px,
        font_size_px,
        window_w,
        window_h,
        .{1, 1, 1, 1},
        *geometry.positions,
        *geometry.texture_coordinates,
        *geometry.rgba_colors,
        *geometry.indices
    );

    return geometry, total_advance_px;
}

msdf_text_geometry_free :: (geometry: *MSDF_Text_Geometry) {
    array_free(geometry.indices);
    array_free(geometry.positions);
    array_free(geometry.texture_coordinates);
    array_free(geometry.rgba_colors);
}

// measurement

msdf_measure_text_pixels :: (font: *MSDF_Font, text: string, font_size_px: float32) -> float32 {
    width: float32 = 0;
    for i : 0..text.count-1 {
        cp := cast(u32) text[i];
        ptr := table_find_pointer(*font.glyphs, cp);
        if ptr != null {
            width += ptr.advance_em * font_size_px;
        } else {
            // if we can't find it, then we just do a heuristic guess
            width += font_size_px * 0.5;
        }
    }
    return width;
}

msdf_line_height :: (font: *MSDF_Font, font_size_px: float32) -> float32 {
    return font.line_height_em * font_size_px;
}

msdf_screen_pixels_per_distance_range :: (font: *MSDF_Font, font_size_px: float32) -> float32 {
    r := font.distance_range_atlas_px * (font_size_px / font.atlas_em_size_px);
    if r < 1.0 r = 1.0;
    return r;
}
