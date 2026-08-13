
#import "File";


// label

ui_label :: (text: string) {
    ctx := ui_ctx;
    style := *ctx.style;
    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(text, rect.x, text_y, style.font_size, style.color_text);
}

ui_label_colored :: (text: string, color: Vector4) {
    ctx := ui_ctx;
    style := *ctx.style;
    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(text, rect.x, text_y, style.font_size, color);
}

ui_label_disabled :: (text: string) {
    ui_label_colored(text, ui_ctx.style.color_text_disabled);
}

// separator

// maybe say that this is horizontal?
ui_separator :: () {
    style := *ui_ctx.style;
    rect := ui_allocate_rect(0, style.border_width + style.item_spacing * 2);
    line_rect: UI_Rect = .{rect.x, rect.y + rect.h * 0.5, rect.w, style.border_width};
    ui_cmd_rect(line_rect, style.color_separator);
}

ui_vertical_separator :: (height: float32) {
    style := *ui_ctx.style;
    w := style.border_width + style.item_spacing * 2;
    rect := ui_allocate_rect(w, height);
    line_rect: UI_Rect = .{rect.x + rect.w * 0.5, rect.y, style.border_width, rect.h};
    ui_cmd_rect(line_rect, style.color_separator);
}

ui_separator_text :: (text: string) {
    ctx := ui_ctx;
    style := *ctx.style;
    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    text_w := msdf_measure_text_pixels(ctx.font, text, style.font_size);
    text_x := rect.x + style.padding;
    text_y := ui_text_baseline_y(rect, style.font_size);

    line_y := rect.y + rect.h * 0.5;
    line_start := text_x + text_w + style.padding;
    line_w := rect.w - (line_start - rect.x);

    if line_w > 0 {
        ui_cmd_rect(.{line_start, line_y, line_w, style.border_width}, style.color_separator);
    }
    ui_cmd_text(text, text_x, text_y, style.font_size, style.color_text);
}

// spacing

ui_spacing :: (pixels: float32) {
    ui_allocate_rect(0, pixels);
}

// bullet

ui_bullet_text :: (text: string) {
    ctx := ui_ctx;
    style := *ctx.style;
    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    bullet_size: float32 = 5.0;
    bullet_x := rect.x + style.padding;
    bullet_y := rect.y + rect.h * 0.5 - bullet_size * 0.5;
    ui_cmd_rect(.{bullet_x, bullet_y, bullet_size, bullet_size}, style.color_text);

    text_x := bullet_x + bullet_size + style.padding;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(text, text_x, text_y, style.font_size, style.color_text);
}

// button

ui_button :: (label: string) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    text_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    w := text_w + style.padding * 2;
    h := style.button_height;
    rect := ui_allocate_rect(w, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked {
        ui_emit_audio(.BUTTON_CLICK, id);
        if ctx.in_popup_content {
            ctx.open_popup_id = UI_ID_NONE;
        }
    }

    bg: Vector4;
    if ui_is_active(id)      bg = style.color_bg_active;
    else if ui_is_hot(id)    bg = style.color_bg_hover;
    else                     bg = style.color_bg;

    ui_cmd_rect(rect, bg);
    ui_cmd_rect_outline(rect, style.color_border);

    text_x := ui_text_centered_x(rect, label, style.font_size);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);

    return clicked;
}

ui_button_colored :: (label: string, normal: Vector4, hover: Vector4, active: Vector4) -> pressed : bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    text_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    w := text_w + style.padding * 2;
    h := style.button_height;
    rect := ui_allocate_rect(w, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked  ui_emit_audio(.BUTTON_CLICK, id);

    bg: Vector4;
    if ui_is_active(id)      bg = active;
    else if ui_is_hot(id)    bg = hover;
    else                     bg = normal;

    ui_cmd_rect(rect, bg);

    text_x := ui_text_centered_x(rect, label, style.font_size);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);

    return clicked;
}

// checkbox

ui_checkbox :: (label: string, value: *bool) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    box_size := style.checkbox_size;
    text_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    total_w := box_size + style.padding + text_w;
    h := max(box_size, style.font_size) + style.padding;
    rect := ui_allocate_rect(total_w, h);

    box_rect: UI_Rect = .{rect.x, rect.y + (h - box_size) * 0.5, box_size, box_size};

    ui_try_hot(id, rect);
    ui_try_active(id);
    toggled := ui_was_clicked(id);
    if toggled {
        value.* = !value.*;
        ui_emit_audio(.CHECKBOX_TOGGLE, id);
    }

    bg := ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(box_rect, bg);
    ui_cmd_rect_outline(box_rect, style.color_border);

    if value.* {
        inset: float32 = 3.0;
        check_rect: UI_Rect = .{
            box_rect.x + inset, box_rect.y + inset,
            box_rect.w - inset * 2, box_rect.h - inset * 2
        };
        ui_cmd_rect(check_rect, style.color_accent);
    }

    text_x := rect.x + box_size + style.padding;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);

    return toggled;
}

// radio button

ui_radio :: (label: string, value: *s32, option: s32) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    box_size := style.checkbox_size;
    text_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    total_w := box_size + style.padding + text_w;
    h := max(box_size, style.font_size) + style.padding;
    rect := ui_allocate_rect(total_w, h);

    box_rect: UI_Rect = .{rect.x, rect.y + (h - box_size) * 0.5, box_size, box_size};

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked {
        value.* = option;
        ui_emit_audio(.BUTTON_CLICK, id);
    }

    bg := ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(box_rect, bg);
    ui_cmd_rect_outline(box_rect, style.color_border);

    if value.* == option {
        inset: float32 = 4.0;
        inner: UI_Rect = .{
            box_rect.x + inset, box_rect.y + inset,
            box_rect.w - inset * 2, box_rect.h - inset * 2
        };
        ui_cmd_rect(inner, style.color_accent);
    }

    text_x := rect.x + box_size + style.padding;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);

    return clicked;
}

// sliders

ui_slider_float :: (label: string, value: *float32, min_val: float32, max_val: float32, format: string = "%.2f") -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.slider_height + style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    value_text := tprint("% : %", label, value.*);
    text_y := rect.y + style.font_size * ctx.font.ascender_em;
    ui_cmd_text(value_text, rect.x, text_y, style.font_size, style.color_text);

    track_y := rect.y + style.font_size + style.padding * 0.5;
    track_rect: UI_Rect = .{rect.x, track_y, rect.w, style.slider_height};

    ui_try_hot(id, track_rect);
    if ui_try_active(id)  ui_emit_audio(.SLIDER_GRAB, id);

    changed := false;
    if ui_is_active(id) && ctx.mouse.left_down {
        t := (ctx.mouse.x - track_rect.x) / track_rect.w;
        t = clamp(t, 0.0, 1.0);
        raw := min_val + t * (max_val - min_val);
        new_value := floor(raw * 100.0 + 0.5) / 100.0;
        if new_value != value.* {
            old_value := value.*;
            value.* = new_value;
            changed = true;
            delta := abs(new_value - old_value) / (max_val - min_val);
            ui_emit_audio(.SLIDER_CHANGE, id, clamp(delta * 5.0, 0.0, 1.0));
        }
    }

    if ui_is_active(id) && ctx.mouse.left_released  ui_emit_audio(.SLIDER_RELEASE, id);

    ui_cmd_rect(track_rect, style.color_slider_track);
    ui_cmd_rect_outline(track_rect, style.color_border);

    t := clamp((value.* - min_val) / (max_val - min_val), 0.0, 1.0);
    fill_w := t * track_rect.w;
    if fill_w > 0 {
        ui_cmd_rect(.{track_rect.x, track_rect.y, fill_w, track_rect.h}, style.color_accent);
    }

    grab_w: float32 = 10.0;
    grab_x := track_rect.x + t * (track_rect.w - grab_w);
    grab_rect: UI_Rect = .{grab_x, track_y, grab_w, style.slider_height};

    grab_color: Vector4;
    if ui_is_active(id)        grab_color = style.color_accent_active;
    else if ui_is_hot(id)      grab_color = style.color_accent_hover;
    else                       grab_color = style.color_slider_grab;
    ui_cmd_rect(grab_rect, grab_color);

    return changed;
}


ui_slider_int :: (label: string, value: *s32, min_val: s32, max_val: s32) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.slider_height + style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    value_text := tprint("% : %", label, value.*);
    text_y := rect.y + style.font_size * ctx.font.ascender_em;
    ui_cmd_text(value_text, rect.x, text_y, style.font_size, style.color_text);

    track_y := rect.y + style.font_size + style.padding * 0.5;
    track_rect: UI_Rect = .{rect.x, track_y, rect.w, style.slider_height};

    ui_try_hot(id, track_rect);
    if ui_try_active(id)  ui_emit_audio(.SLIDER_GRAB, id);

    changed := false;
    if ui_is_active(id) && ctx.mouse.left_down {
        t := (ctx.mouse.x - track_rect.x) / track_rect.w;
        t = clamp(t, 0.0, 1.0);
        raw := cast(float32) min_val + t * cast(float32)(max_val - min_val);
        new_value := cast(s32) (raw + 0.5);
        if new_value != value.* {
            old_value := value.*;
            value.* = new_value;
            changed = true;
            range := cast(float32)(max_val - min_val);
            delta := abs(cast(float32)(new_value - old_value)) / range;
            ui_emit_audio(.SLIDER_CHANGE, id, clamp(delta * 5.0, 0.0, 1.0));
        }
    }

    if ui_is_active(id) && ctx.mouse.left_released  ui_emit_audio(.SLIDER_RELEASE, id);

    ui_cmd_rect(track_rect, style.color_slider_track);
    ui_cmd_rect_outline(track_rect, style.color_border);

    t := clamp((cast(float32)(value.* - min_val)) / cast(float32)(max_val - min_val), 0.0, 1.0);
    fill_w := t * track_rect.w;
    if fill_w > 0 {
        ui_cmd_rect(.{track_rect.x, track_rect.y, fill_w, track_rect.h}, style.color_accent);
    }

    grab_w: float32 = 10.0;
    grab_x := track_rect.x + t * (track_rect.w - grab_w);
    grab_rect: UI_Rect = .{grab_x, track_y, grab_w, style.slider_height};

    grab_color: Vector4;
    if ui_is_active(id)        grab_color = style.color_accent_active;
    else if ui_is_hot(id)      grab_color = style.color_accent_hover;
    else                       grab_color = style.color_slider_grab;
    ui_cmd_rect(grab_rect, grab_color);

    return changed;
}


ui_progress_bar :: (fraction: float32, label: string = "") {
    ctx := ui_ctx;
    style := *ctx.style;

    h := style.slider_height;
    rect := ui_allocate_rect(0, h);

    ui_cmd_rect(rect, style.color_slider_track);

    f := clamp(fraction, 0.0, 1.0);
    fill_w := f * rect.w;
    if fill_w > 0 {
        ui_cmd_rect(.{rect.x, rect.y, fill_w, rect.h}, style.color_accent);
    }

    display_text := ifx label.count > 0 then label else tprint("%\%", cast(s32)(f * 100));
    text_x := ui_text_centered_x(rect, display_text, style.font_size);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(display_text, text_x, text_y, style.font_size, style.color_text);
}


/*

Why does this function take a fixed buffer and length instead of something dynamic like String_Builder or [..] u8?

Recall that a string in jai is just a few on memory it has a pointer and a count, it doesn't own memory and it can't append to it.
To build up text we need something that owns the memory.

So that would logically imply that you would need a String_Builder or a [..] u8, but then these things can run out of space 
(which would happen because the whole point is that you don't specify the size of the dynamic array at the start). 
When they run out of space you then have to go get more through the heap, which is slow, and so for a thin ui system you don't want
to be slowing down other parts of the program, so we don't use that. 

Hey, but then we can use the temp allocator because then when we run out of space we can get more easily, but you reset your temp allocator all the time,
and these strings need to persist across frames. Hey so why don't I use an arena allocator for all my strings, ok sure but at that point just do this
because its simpler and you actually know your bound of memory on each one instead of overshooting or undershooting with your arena.

*/
ui_text_input :: (label: string, buffer: *[256] u8, length: *s32) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    label_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    h := style.input_height;
    rect := ui_allocate_rect(0, h);

    label_x := rect.x;
    label_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, label_x, label_y, style.font_size, style.color_text);

    input_x := rect.x + label_w + style.padding;
    input_w := rect.w - label_w - style.padding;
    input_rect: UI_Rect = .{input_x, rect.y, input_w, h};

    ui_try_hot(id, input_rect);
    if ui_try_active(id) {
        ctx.focused = id;
        ui_emit_audio(.FOCUS_GAINED, id);
    }

    focused := ui_is_focused(id);

    bg := ifx focused then style.color_bg_active else ifx ui_is_hot(id) then style.color_bg_hover else style.color_input_bg;
    ui_cmd_rect(input_rect, bg);
    ui_cmd_rect_outline(input_rect, ifx focused then style.color_accent else style.color_border);

    current_text: string;
    current_text.data = buffer.data;
    current_text.count = length.*;

    text_x := input_rect.x + style.padding * 0.5;
    text_y := ui_text_baseline_y(input_rect, style.font_size);

    ui_cmd_scissor_push(input_rect);
    ui_cmd_text(current_text, text_x, text_y, style.font_size, style.color_text);

    if focused {
        cursor_x := text_x + msdf_measure_text_pixels(ctx.font, current_text, style.font_size);
        blink := cast(s32)(ctx.time_elapsed * 2.0) % 2 == 0;
        if blink {
            cursor_rect: UI_Rect = .{cursor_x, input_rect.y + 3, 1.5, input_rect.h - 6};
            ui_cmd_rect(cursor_rect, style.color_input_cursor);
        }
    }
    ui_cmd_scissor_pop();


    changed := false;
    if focused {
        for i : 0..ctx.keyboard.char_count-1 {
            c := ctx.keyboard.chars_entered[i];
            if c >= 32 && c < 127 {
                if length.* < 255 {
                    (buffer.*)[length.*] = c;
                    length.* += 1;
                    changed = true;
                    ui_emit_audio(.TEXT_INPUT_CHAR, id, 0.8);
                }
            }
        }

        for i : 0..ctx.keyboard.key_count-1 {
            key := ctx.keyboard.keys_pressed[i];
            if key == .BACKSPACE {
                if length.* > 0 {
                    length.* -= 1;
                    changed = true;
                    ui_emit_audio(.TEXT_INPUT_BACKSPACE, id);
                }
            } else if key == .ENTER || key == .ESCAPE {
                ctx.focused = UI_ID_NONE;
                ui_emit_audio(.TEXT_INPUT_CONFIRM, id);
            }
        }
    }

    return changed;
}


ui_begin_combo :: (label: string, preview_value: string, max_visible_items: s32 = 10, popup_width: float32 = 0) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    if max_visible_items <= 0 max_visible_items = 10;

    h := style.button_height;
    rect := ui_allocate_rect(0, h);

    popup_is_open := ctx.open_popup_id == id;

    // label
    label_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    if label.count > 0 {
        label_x := rect.x;
        label_y := ui_text_baseline_y(rect, style.font_size);
        ui_cmd_text(label, label_x, label_y, style.font_size, style.color_text);
    }

    // combo box, the thing that activates the dropdown
    combo_x := rect.x;
    combo_w := rect.w;
    if label.count > 0 {
        combo_x = rect.x + label_w + style.padding;
        combo_w = rect.w - label_w - style.padding;
    }
    if combo_w < style.button_height combo_w = style.button_height;
    combo_rect: UI_Rect = .{combo_x, rect.y, combo_w, h};

    // toggle on press, so the frame-end outside-click close cannot race it
    mouse_over_combo := rect_contains(combo_rect, ctx.mouse.x, ctx.mouse.y);
    if mouse_over_combo {
        ctx.hot = id;
        if ctx.mouse.left_pressed {
            if popup_is_open {
                ctx.open_popup_id = UI_ID_NONE;
                ui_emit_audio(.DROPDOWN_CLOSE, id);
            } else {
                ctx.open_popup_id = id;
                ui_emit_audio(.DROPDOWN_OPEN, id);
            }
            // claim active so end_frame's auto-close sees hot != none
            ctx.active = id;
        }
    }

    // draw combo box
    bg := ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(combo_rect, bg);
    ui_cmd_rect_outline(combo_rect, style.color_border);

    // preview text
    preview_rect: UI_Rect = .{
        combo_rect.x + style.padding,
        combo_rect.y,
        combo_rect.w - style.padding * 2 - 14.0,
        combo_rect.h
    };
    ui_cmd_scissor_push(preview_rect);
    text_x := preview_rect.x;
    text_y := ui_text_baseline_y(combo_rect, style.font_size);
    ui_cmd_text(preview_value, text_x, text_y, style.font_size, style.color_text);
    ui_cmd_scissor_pop();

    // arrow indicator
    arrow_size: float32 = 8.0;
    arrow_cx := combo_rect.x + combo_rect.w - style.padding - arrow_size * 0.5;
    arrow_cy := combo_rect.y + combo_rect.h * 0.5;
    ui_draw_triangle_down(arrow_cx, arrow_cy, arrow_size, style.color_text_disabled);

    if ctx.open_popup_id != id return false;

    state_ptr := table_find_pointer(*ctx.window_states, id);
    if state_ptr == null {
        new_state: UI_Window_State;
        new_state.scroll_y = 0;
        new_state.content_h = 0;
        new_state.open = true;
        table_add(*ctx.window_states, id, new_state);
        state_ptr = table_find_pointer(*ctx.window_states, id);
    }

    popup_w := ifx popup_width > 0 then popup_width else combo_rect.w;
    max_popup_h := cast(float32) max_visible_items * style.button_height;
    content_h := state_ptr.content_h;
    if content_h <= 0 content_h = max_popup_h;
    popup_h := min(max(content_h, style.button_height), max_popup_h);

    popup_x := combo_rect.x;
    popup_y := combo_rect.y + combo_rect.h;
    if popup_y + popup_h > ctx.window_h && combo_rect.y - popup_h >= 0 {
        popup_y = combo_rect.y - popup_h;
    } else if popup_y + popup_h > ctx.window_h {
        popup_y = max(0.0, ctx.window_h - popup_h);
    }

    ctx.popup_rect = .{popup_x, popup_y, popup_w, popup_h};

    max_scroll := state_ptr.content_h - ctx.popup_rect.h;
    if max_scroll < 0 max_scroll = 0;
    state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);

    if rect_contains(ctx.popup_rect, ctx.mouse.x, ctx.mouse.y) && ctx.mouse.scroll_y != 0 && !ctx.scroll_consumed {
        state_ptr.scroll_y -= ctx.mouse.scroll_y * style.button_height;
        state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);
        ctx.scroll_consumed = true;
        ui_emit_audio(.SCROLL, id, clamp(abs(ctx.mouse.scroll_y) / 5.0, 0.0, 1.0));
    }

    ctx.popup_previous_overlay = ctx.drawing_overlay;
    ctx.drawing_overlay = true;
    ctx.in_popup_content = true;
    ctx.current_popup_id = id;

    ui_cmd_rect(ctx.popup_rect, style.color_window_bg);
    ui_cmd_rect_outline(ctx.popup_rect, style.color_border);
    ui_cmd_scissor_push(ctx.popup_rect);

    inner_w := ctx.popup_rect.w;
    if state_ptr.content_h > ctx.popup_rect.h {
        inner_w -= style.scrollbar_width;
    }
    if inner_w < 0 inner_w = 0;

    ui_push_id(label);
    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = ctx.popup_rect.x,
        cursor_y   = ctx.popup_rect.y - state_ptr.scroll_y,
        origin_x   = ctx.popup_rect.x,
        origin_y   = ctx.popup_rect.y - state_ptr.scroll_y,
        max_w      = inner_w,
        max_h      = ctx.popup_rect.h + state_ptr.content_h,
        visible_h  = ctx.popup_rect.h,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });

    return true;
}

ui_end_combo :: () {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ctx.current_popup_id;

    layout := ui_current_layout();
    content_h := layout.content_max_y - layout.origin_y;

    ui_pop_layout();
    ui_pop_id();
    ui_cmd_scissor_pop();

    state_ptr := table_find_pointer(*ctx.window_states, id);
    if state_ptr != null {
        state_ptr.content_h = content_h;

        max_scroll := state_ptr.content_h - ctx.popup_rect.h;
        if max_scroll < 0 max_scroll = 0;
        state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);

        if max_scroll > 0 {
            track_rect: UI_Rect = .{
                ctx.popup_rect.x + ctx.popup_rect.w - style.scrollbar_width,
                ctx.popup_rect.y,
                style.scrollbar_width,
                ctx.popup_rect.h
            };
            ui_cmd_rect(track_rect, style.color_scrollbar_bg);

            visible_fraction := ctx.popup_rect.h / state_ptr.content_h;
            grab_h := max(track_rect.h * visible_fraction, 20.0);
            travel := max(track_rect.h - grab_h, 1.0);
            scroll_fraction := ifx max_scroll > 0 then state_ptr.scroll_y / max_scroll else 0.0;
            grab_y := track_rect.y + scroll_fraction * travel;
            grab_rect: UI_Rect = .{track_rect.x, grab_y, track_rect.w, grab_h};
            scrollbar_id := ui_hash_fnv1a("#combo_scrollbar", id);

            ui_try_hot(scrollbar_id, grab_rect);
            if ui_try_active(scrollbar_id) ui_emit_audio(.SCROLL, id, 0.4);

            if ui_is_active(scrollbar_id) && ctx.mouse.left_down {
                state_ptr.scroll_y += (ctx.mouse.dy / travel) * max_scroll;
                state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);
            }

            grab_color := ifx ui_is_active(scrollbar_id) then style.color_accent
                          else ifx ui_is_hot(scrollbar_id) then style.color_bg_hover
                          else style.color_scrollbar_grab;
            ui_cmd_rect(grab_rect, grab_color);
        }
    }

    ctx.in_popup_content = false;
    ctx.current_popup_id = UI_ID_NONE;
    ctx.drawing_overlay = ctx.popup_previous_overlay;
}

ui_dropdown :: (label: string, items: [] string, selected: *s32, max_visible_items: s32 = 10) -> bool {
    if selected.* < 0 || selected.* >= cast(s32) items.count selected.* = 0;
    current_text := ifx items.count > 0 then items[selected.*] else "---";

    changed := false;
    if ui_begin_combo(label, current_text, max_visible_items) {
        for i : 0..items.count-1 {
            is_selected := cast(s32) i == selected.*;
            if ui_selectable(items[i], is_selected) {
                selected.* = cast(s32) i;
                changed = true;
                ui_emit_audio(.DROPDOWN_SELECT, ui_get_id(label));
            }
        }
        ui_end_combo();
    }

    return changed;
}


// hierarchical view of information

ui_tree_node :: (label: string, default_open: bool = false) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    state_ptr := table_find_pointer(*ctx.window_states, id);
    if state_ptr == null {
        new_state: UI_Window_State;
        new_state.open = default_open;
        table_add(*ctx.window_states, id, new_state);
        state_ptr = table_find_pointer(*ctx.window_states, id);
    }

    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    if ui_was_clicked(id) {
        state_ptr.open = !state_ptr.open;
        if state_ptr.open  ui_emit_audio(.TREE_EXPAND, id);
        else               ui_emit_audio(.TREE_COLLAPSE, id);
    }

    // draw background on hover
    if ui_is_hot(id) {
        ui_cmd_rect(rect, style.color_bg_hover);
    }

    // draw arrow triangle
    arrow_size: float32 = 8.0;
    arrow_cx := rect.x + arrow_size * 0.5 + 2.0;
    arrow_cy := rect.y + rect.h * 0.5;
    if state_ptr.open {
        ui_draw_triangle_down(arrow_cx, arrow_cy, arrow_size, style.color_text_disabled);
    } else {
        ui_draw_triangle_right(arrow_cx, arrow_cy, arrow_size, style.color_text_disabled);
    }

    // draw label
    arrow_w: float32 = arrow_size + 6.0;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, rect.x + arrow_w, text_y, style.font_size, style.color_text);

    if state_ptr.open {
        layout := ui_current_layout();
        layout.indent += style.tree_indent;
    }

    return state_ptr.open;
}

ui_tree_pop :: () {
    layout := ui_current_layout();
    layout.indent -= ui_ctx.style.tree_indent;
}


ui_collapsing_header :: (label: string, default_open: bool = false) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    state_ptr := table_find_pointer(*ctx.window_states, id);
    if state_ptr == null {
        new_state: UI_Window_State;
        new_state.open = default_open;
        table_add(*ctx.window_states, id, new_state);
        state_ptr = table_find_pointer(*ctx.window_states, id);
    }

    h := style.button_height;
    rect := ui_allocate_rect(0, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    if ui_was_clicked(id) {
        state_ptr.open = !state_ptr.open;
        if state_ptr.open  ui_emit_audio(.TREE_EXPAND, id);
        else               ui_emit_audio(.TREE_COLLAPSE, id);
    }

    bg := ifx ui_is_active(id) then style.color_bg_active
          else ifx ui_is_hot(id) then style.color_bg_hover
          else style.color_bg;
    ui_cmd_rect(rect, bg);

    // draw arrow triangle
    arrow_size: float32 = 8.0;
    arrow_cx := rect.x + style.padding + arrow_size * 0.5;
    arrow_cy := rect.y + rect.h * 0.5;
    if state_ptr.open {
        ui_draw_triangle_down(arrow_cx, arrow_cy, arrow_size, style.color_text);
    } else {
        ui_draw_triangle_right(arrow_cx, arrow_cy, arrow_size, style.color_text);
    }

    // draw label
    arrow_w := style.padding + arrow_size + 4.0;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, rect.x + arrow_w, text_y, style.font_size, style.color_text);

    return state_ptr.open;
}

// a tooltip is a box that appears when you hover on something.

ui_set_tooltip :: (text: string) {
    ctx := ui_ctx;
    ctx.tooltip.text = text;
    ctx.tooltip.x = ctx.mouse.x + 12;
    ctx.tooltip.y = ctx.mouse.y + 12;
}

ui_draw_tooltip_internal :: () {
    ctx := ui_ctx;
    style := *ctx.style;

    text := ctx.tooltip.text;
    if text.count == 0 return;

    text_w := msdf_measure_text_pixels(ctx.font, text, style.font_size);
    pad := style.padding;
    w := text_w + pad * 2;
    h := style.font_size + pad * 2;

    tx := ctx.tooltip.x;
    ty := ctx.tooltip.y;
    if tx + w > ctx.window_w  tx = ctx.window_w - w;
    if ty + h > ctx.window_h  ty = ctx.window_h - h;

    rect: UI_Rect = .{tx, ty, w, h};
    ui_cmd_rect(rect, style.color_tooltip_bg);
    ui_cmd_rect_outline(rect, style.color_border);

    text_x := rect.x + pad;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(text, text_x, text_y, style.font_size, style.color_text);
}


ui_color_display :: (label: string, color: Vector4) {
    ctx := ui_ctx;
    style := *ctx.style;

    swatch_size := style.checkbox_size;
    text_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    total_w := swatch_size + style.padding + text_w;
    h := max(swatch_size, style.font_size) + style.padding;
    rect := ui_allocate_rect(total_w, h);

    swatch_rect: UI_Rect = .{rect.x, rect.y + (h - swatch_size) * 0.5, swatch_size, swatch_size};

    ui_cmd_rect(swatch_rect, .{0.4, 0.4, 0.4, 1.0});
    ui_cmd_rect(swatch_rect, color);
    ui_cmd_rect_outline(swatch_rect, style.color_border);

    text_x := rect.x + swatch_size + style.padding;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);
}


ui_color_edit3 :: (label: string, color: *Vector4) -> bool {
    ui_push_id(label);
    defer ui_pop_id();

    ui_label(label);

    changed := false;
    r := color.x;
    g := color.y;
    b := color.z;

    ui_begin_row();
    if ui_slider_float("R", *r, 0, 1)  { color.x = r; changed = true; }
    ui_end_row();

    ui_begin_row();
    if ui_slider_float("G", *g, 0, 1)  { color.y = g; changed = true; }
    ui_end_row();

    ui_begin_row();
    if ui_slider_float("B", *b, 0, 1)  { color.z = b; changed = true; }
    ui_end_row();

    ui_color_display("Preview", color.*);

    return changed;
}

// layout: row / column helpers

ui_begin_row :: () {
    layout := ui_current_layout();
    ui_push_layout(.{
        mode       = .HORIZONTAL,
        cursor_x   = layout.cursor_x + layout.indent,
        cursor_y   = layout.cursor_y,
        origin_x   = layout.cursor_x + layout.indent,
        origin_y   = layout.cursor_y,
        max_w      = layout.max_w - layout.indent,
        max_h      = layout.max_h,
        visible_h  = layout.visible_h - (layout.cursor_y - layout.origin_y),
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });
}

ui_end_row :: () {
    row_layout := ui_current_layout();
    row_h := row_layout.row_height;
    ui_pop_layout();

    parent := ui_current_layout();
    parent.cursor_y += row_h + ui_ctx.style.item_spacing;
}

ui_begin_column :: (width: float32 = 0) {
    layout := ui_current_layout();
    w := width;
    if w <= 0 w = layout.max_w - layout.indent;

    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = layout.cursor_x + layout.indent,
        cursor_y   = layout.cursor_y,
        origin_x   = layout.cursor_x + layout.indent,
        origin_y   = layout.cursor_y,
        max_w      = w,
        max_h      = layout.max_h,
        visible_h  = layout.visible_h - (layout.cursor_y - layout.origin_y),
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });
}

ui_end_column :: () {
    col_layout := ui_current_layout();
    content_h := col_layout.cursor_y - col_layout.origin_y;
    ui_pop_layout();

    parent := ui_current_layout();
    if parent.mode == .HORIZONTAL {
        if content_h > parent.row_height parent.row_height = content_h;
        parent.cursor_x = col_layout.origin_x + col_layout.max_w + ui_ctx.style.item_spacing;
    } else {
        parent.cursor_y += content_h + ui_ctx.style.item_spacing;
    }
}

ui_indent :: () {
    layout := ui_current_layout();
    layout.indent += ui_ctx.style.indent_width;
}

ui_unindent :: () {
    layout := ui_current_layout();
    layout.indent -= ui_ctx.style.indent_width;
    if layout.indent < 0 layout.indent = 0;
}

// windows / panels

ui_window_id :: (title: string) -> UI_Id {
    return ui_hash_fnv1a(title);
}

ui_window_snap_rect_for_mouse :: (mouse_x: float32, mouse_y: float32) -> (rect: UI_Rect, should_snap: bool) {
    area := ui_ctx.work_area;
    edge_threshold: float32 = 28.0;

    if mouse_x <= area.x + edge_threshold {
        return .{area.x, area.y, area.w * 0.5, area.h}, true;
    }
    if mouse_x >= area.x + area.w - edge_threshold {
        return .{area.x + area.w * 0.5, area.y, area.w * 0.5, area.h}, true;
    }
    if mouse_y <= area.y + edge_threshold {
        return area, true;
    }

    return .{}, false;
}

ui_begin_window :: (title: string, default_x: float32 = 50, default_y: float32 = 50, default_w: float32 = 300, default_h: float32 = 400) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_window_id(title);

    state_ptr := table_find_pointer(*ctx.window_states, id);
    if state_ptr == null {
        new_state: UI_Window_State;
        new_state.rect = .{default_x, default_y, default_w, default_h};
        new_state.collapsed = false;
        new_state.scroll_y = 0;
        new_state.content_h = 0;
        new_state.open = true;
        new_state.is_window = true;
        new_state.z_order = ctx.next_z_order;
        ctx.next_z_order += 1;
        table_add(*ctx.window_states, id, new_state);
        state_ptr = table_find_pointer(*ctx.window_states, id);
        ui_emit_audio(.WINDOW_OPEN, id);
    }

    if !state_ptr.open return false;

    win := state_ptr.rect;
    title_h := style.window_title_height;

    title_rect: UI_Rect = .{win.x, win.y, win.w, title_h};
    title_id := ui_hash_fnv1a("#title", id);

    // title bar interaction: drag to move
    ui_try_hot(title_id, title_rect);
    ui_try_active(title_id);

    if ui_is_active(title_id) && ctx.mouse.left_down {
        state_ptr.rect.x += ctx.mouse.dx;
        state_ptr.rect.y += ctx.mouse.dy;
        win = state_ptr.rect;
        title_rect = .{win.x, win.y, win.w, title_h};
    }

    if ui_is_active(title_id) && ctx.mouse.left_released {
        snap_rect, should_snap := ui_window_snap_rect_for_mouse(ctx.mouse.x, ctx.mouse.y);
        if should_snap {
            state_ptr.rect = snap_rect;
            win = state_ptr.rect;
            title_rect = .{win.x, win.y, win.w, title_h};
        }
    }

    // collapse on right-click
    if rect_contains(title_rect, ctx.mouse.x, ctx.mouse.y) && ctx.mouse.right_pressed {
        state_ptr.collapsed = !state_ptr.collapsed;
        if state_ptr.collapsed  ui_emit_audio(.WINDOW_COLLAPSE, id);
        else                    ui_emit_audio(.WINDOW_EXPAND, id);
    }

    // bring to front on click
    full_rect: UI_Rect = ifx state_ptr.collapsed then title_rect else win;
    if rect_contains(full_rect, ctx.mouse.x, ctx.mouse.y) {
        ctx.any_window_hovered = true;
        if ctx.mouse.left_pressed {
            state_ptr.z_order = ctx.next_z_order;
            ctx.next_z_order += 1;
        }
    }

    // draw title bar
    ui_cmd_rect(title_rect, style.color_window_title_bg);

    // draw collapse arrow
    arrow_size: float32 = 8.0;
    arrow_cx := title_rect.x + style.padding + arrow_size * 0.5;
    arrow_cy := title_rect.y + title_h * 0.5;
    if state_ptr.collapsed {
        ui_draw_triangle_right(arrow_cx, arrow_cy, arrow_size, style.color_text_disabled);
    } else {
        ui_draw_triangle_down(arrow_cx, arrow_cy, arrow_size, style.color_text_disabled);
    }

    // draw title text
    arrow_w := style.padding + arrow_size + 4.0;
    title_text_y := ui_text_baseline_y(title_rect, style.font_size_title);
    ui_cmd_text(title, title_rect.x + arrow_w, title_text_y, style.font_size_title, style.color_text);

    // close button
    close_rect: UI_Rect = .{
        win.x + win.w - title_h,
        win.y,
        title_h,
        title_h
    };
    close_id := ui_hash_fnv1a("#close", id);

    ui_try_hot(close_id, close_rect);
    ui_try_active(close_id);
    if ui_was_clicked(close_id) {
        state_ptr.open = false;
        ui_emit_audio(.WINDOW_CLOSE, id);
        return false;
    }

    if ui_is_hot(close_id) {
        ui_cmd_rect(close_rect, style.color_bg_hover);
    }

    x_color := ifx ui_is_hot(close_id) then style.color_text else style.color_text_disabled;
    ui_draw_x_mark(close_rect, x_color, 2.0);

    if state_ptr.collapsed return false;

    // draw window body
    body_rect: UI_Rect = .{win.x, win.y + title_h, win.w, win.h - title_h};
    ui_cmd_rect(body_rect, style.color_window_bg);
    ui_cmd_rect_outline(win, style.color_border);

    // resize handle
    resize_size: float32 = 16.0;
    resize_rect: UI_Rect = .{
        win.x + win.w - resize_size,
        win.y + win.h - resize_size,
        resize_size,
        resize_size
    };
    resize_id := ui_hash_fnv1a("#resize", id);

    ui_try_hot(resize_id, resize_rect);
    ui_try_active(resize_id);

    if ui_is_active(resize_id) && ctx.mouse.left_down {
        state_ptr.rect.w += ctx.mouse.dx;
        state_ptr.rect.h += ctx.mouse.dy;
        if state_ptr.rect.w < 100  state_ptr.rect.w = 100;
        if state_ptr.rect.h < title_h + 50  state_ptr.rect.h = title_h + 50;

        area := ctx.work_area;
        max_w := area.x + area.w - state_ptr.rect.x;
        max_h := area.y + area.h - state_ptr.rect.y;
        if state_ptr.rect.w > max_w  state_ptr.rect.w = max(100.0, max_w);
        if state_ptr.rect.h > max_h  state_ptr.rect.h = max(title_h + 50, max_h);
    }

    // draw resize grip triangle in bottom-right corner
    grip_color := ifx ui_is_hot(resize_id) then style.color_text else style.color_text_disabled;

    ui_draw_resize_triangle :: (rect: UI_Rect, color: Vector4, size: float32 = 14.0) {

        x1 := rect.x + rect.w;
        y1 := rect.y + rect.h;
        x0 := x1 - size;
        y0 := y1 - size;

        pixels := NewArray(3, Vector2,, allocator = temp);
        pixels[0] = .{x1, y0};   // top-right
        pixels[1] = .{x1, y1};   // bottom-right
        pixels[2] = .{x0, y1};   // bottom-left

        positions := ui_pixels_to_ndc(pixels);
        colors := ui_solid_colors(3, color);

        indices := NewArray(3, u32,, allocator = temp);
        indices[0] = 0;  indices[1] = 1;  indices[2] = 2;

        ui_cmd_geometry(positions, colors, indices);
    }

    ui_draw_resize_triangle(win, grip_color, resize_size);

    // scrollbar
    // note: scroll input is deferred to ui_end_window
    content_area: UI_Rect = .{
        body_rect.x + style.padding,
        body_rect.y + style.padding,
        body_rect.w - style.padding * 2 - style.scrollbar_width,
        body_rect.h - style.padding * 2
    };

    needs_scroll := state_ptr.content_h > content_area.h;

    if needs_scroll {
        max_scroll := state_ptr.content_h - content_area.h;
        if max_scroll < 0 max_scroll = 0;
        state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);

        scrollbar_track: UI_Rect = .{
            body_rect.x + body_rect.w - style.scrollbar_width - style.padding * 0.5,
            body_rect.y + style.padding,
            style.scrollbar_width,
            body_rect.h - style.padding * 2 - resize_size  // leaving room for resize grip
        };
        ui_cmd_rect(scrollbar_track, style.color_scrollbar_bg);

        visible_fraction := content_area.h / state_ptr.content_h;
        grab_h := max(scrollbar_track.h * visible_fraction, 20.0);
        scroll_fraction := state_ptr.scroll_y / max_scroll;
        grab_y := scrollbar_track.y + scroll_fraction * (scrollbar_track.h - grab_h);

        scrollbar_grab_rect: UI_Rect = .{scrollbar_track.x, grab_y, scrollbar_track.w, grab_h};
        scrollbar_id := ui_hash_fnv1a("#scrollbar", id);

        ui_try_hot(scrollbar_id, scrollbar_grab_rect);
        ui_try_active(scrollbar_id);

        if ui_is_active(scrollbar_id) && ctx.mouse.left_down {
            drag_ratio := ctx.mouse.dy / (scrollbar_track.h - grab_h);
            state_ptr.scroll_y += drag_ratio * max_scroll;
            state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);
        }

        grab_color := ifx ui_is_active(scrollbar_id) then style.color_accent
                      else ifx ui_is_hot(scrollbar_id) then style.color_bg_hover
                      else style.color_scrollbar_grab;
        ui_cmd_rect(scrollbar_grab_rect, grab_color);
    } else {
        state_ptr.scroll_y = 0;
        content_area.w += style.scrollbar_width;
    }

    // set up clipping and layout for window contents
    ui_cmd_scissor_push(content_area);

    ui_push_id(title);
    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = content_area.x,
        cursor_y   = content_area.y - state_ptr.scroll_y,
        origin_x   = content_area.x,
        origin_y   = content_area.y - state_ptr.scroll_y,
        max_w      = content_area.w,
        max_h      = content_area.h + state_ptr.content_h,
        visible_h  = content_area.h,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });

    return true;
}

ui_end_window :: () {
    ctx := ui_ctx;

    layout := ui_current_layout();
    content_h := layout.content_max_y - layout.origin_y;

    // grab the window id before popping
    window_id := ctx.id_stack[ctx.id_stack_depth - 1];

    ui_pop_layout();
    ui_pop_id();
    ui_cmd_scissor_pop();

    // write back content height so scroll works
    state_ptr := table_find_pointer(*ctx.window_states, window_id);
    if state_ptr != null {
        state_ptr.content_h = content_h;

        // apply scroll here  only if no inner region consumed it
        if !ctx.scroll_consumed && state_ptr.content_h > 0 {
            // reconstruct body_rect from window state
            title_h := ctx.style.window_title_height;
            body_rect: UI_Rect = .{
                state_ptr.rect.x,
                state_ptr.rect.y + title_h,
                state_ptr.rect.w,
                state_ptr.rect.h - title_h
            };

            if rect_contains(body_rect, ctx.mouse.x, ctx.mouse.y) {
                content_area_h := body_rect.h - ctx.style.padding * 2;
                needs_scroll := state_ptr.content_h > content_area_h;
                if needs_scroll && ctx.mouse.scroll_y != 0 {
                    state_ptr.scroll_y -= ctx.mouse.scroll_y * 30.0;
                    max_scroll := state_ptr.content_h - content_area_h;
                    if max_scroll < 0 max_scroll = 0;
                    state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);
                    ctx.scroll_consumed = true;
                    ui_emit_audio(.SCROLL, window_id, clamp(abs(ctx.mouse.scroll_y) / 5.0, 0.0, 1.0));
                }
            }
        }
    }
}

// simpler panel (no title bar, no drag, no resize, just a background region)
ui_begin_panel :: (label: string, height: float32 = 0) {
    ctx := ui_ctx;
    style := *ctx.style;

    h := ifx height > 0 then height else 200.0;
    rect := ui_allocate_rect(0, h);

    ui_cmd_rect(rect, style.color_panel_bg);
    ui_cmd_rect_outline(rect, style.color_border);

    inner := rect_shrink(rect, style.padding);

    ui_push_id(label);
    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = inner.x,
        cursor_y   = inner.y,
        origin_x   = inner.x,
        origin_y   = inner.y,
        max_w      = inner.w,
        max_h      = inner.h,
        visible_h  = inner.h,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });
}

ui_end_panel :: () {
    ui_pop_layout();
    ui_pop_id();
}

// scroll region (standalone, not tied to a window)

ui_begin_scroll_region_ex :: (label: string, height: float32, horizontal_padding: float32 = -1) -> (scroll_y: float32, inner_rect: UI_Rect) {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    rect := ui_allocate_rect(0, height);

    state_ptr := table_find_pointer(*ctx.window_states, id);
    if state_ptr == null {
        new_state: UI_Window_State;
        new_state.scroll_y = 0;
        new_state.content_h = 0;
        new_state.open = true;
        new_state.is_window = false;
        table_add(*ctx.window_states, id, new_state);
        state_ptr = table_find_pointer(*ctx.window_states, id);
    }

    // store the rect so ui_end_scroll_region can use it for hit testing
    state_ptr.scroll_region_rect = rect;

    ui_cmd_rect(rect, style.color_panel_bg);

    max_scroll := state_ptr.content_h - height;
    if max_scroll < 0 max_scroll = 0;
    state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);

    ui_cmd_scissor_push(rect);

    pad := ifx horizontal_padding >= 0 then horizontal_padding else style.padding;
    inner_rect: UI_Rect = .{
        rect.x + pad,
        rect.y,
        rect.w - pad * 2 - style.scrollbar_width,
        rect.h
    };
    if inner_rect.w < 0 inner_rect.w = 0;

    ui_push_id(label);
    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = inner_rect.x,
        cursor_y   = rect.y - state_ptr.scroll_y,
        origin_x   = inner_rect.x,
        origin_y   = rect.y - state_ptr.scroll_y,
        max_w      = inner_rect.w,
        max_h      = rect.h + state_ptr.content_h,
        visible_h  = rect.h,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });

    scroll_y: float32 = state_ptr.scroll_y;
    return scroll_y, inner_rect;
}

ui_begin_scroll_region :: (label: string, height: float32) -> float32 {
    scroll_y, _ := ui_begin_scroll_region_ex(label, height);
    return scroll_y;
}

ui_end_scroll_region :: () {
    ctx := ui_ctx;

    layout := ui_current_layout();
    content_h := layout.content_max_y - layout.origin_y;

    scroll_id := ctx.id_stack[ctx.id_stack_depth - 1];

    ui_pop_layout();
    ui_pop_id();
    ui_cmd_scissor_pop();

    state_ptr := table_find_pointer(*ctx.window_states, scroll_id);
    if state_ptr != null {
        style := *ctx.style;
        state_ptr.content_h = content_h;
        max_scroll := state_ptr.content_h - state_ptr.scroll_region_rect.h;
        if max_scroll < 0 max_scroll = 0;

        if max_scroll > 0 {
            track_rect: UI_Rect = .{
                state_ptr.scroll_region_rect.x + state_ptr.scroll_region_rect.w - style.scrollbar_width,
                state_ptr.scroll_region_rect.y,
                style.scrollbar_width,
                state_ptr.scroll_region_rect.h
            };
            ui_cmd_rect(track_rect, style.color_scrollbar_bg);

            visible_fraction := clamp(state_ptr.scroll_region_rect.h / state_ptr.content_h, 0.0, 1.0);
            grab_h := max(track_rect.h * visible_fraction, 20.0);
            grab_h = min(grab_h, track_rect.h);
            scroll_fraction := ifx max_scroll > 0 then state_ptr.scroll_y / max_scroll else 0.0;
            grab_y := track_rect.y + scroll_fraction * (track_rect.h - grab_h);
            grab_rect: UI_Rect = .{track_rect.x, grab_y, track_rect.w, grab_h};

            scrollbar_id := ui_hash_fnv1a("#scroll_region_scrollbar", scroll_id);
            ui_try_hot(scrollbar_id, track_rect);
            ui_try_active(scrollbar_id);
            if ui_is_active(scrollbar_id) && ctx.mouse.left_down {
                track_scroll_h := max(1.0, track_rect.h - grab_h);
                t := (ctx.mouse.y - track_rect.y - grab_h * 0.5) / track_scroll_h;
                state_ptr.scroll_y = clamp(t, 0.0, 1.0) * max_scroll;
                ctx.scroll_consumed = true;
            }

            grab_color := ifx ui_is_active(scrollbar_id) then style.color_accent
                          else ifx ui_is_hot(scrollbar_id) then style.color_bg_hover
                          else style.color_scrollbar_grab;
            ui_cmd_rect(grab_rect, grab_color);
        }

        // apply scroll  only if no inner region already consumed it
        if !ctx.scroll_consumed && ctx.mouse.scroll_y != 0 {
            if rect_contains(state_ptr.scroll_region_rect, ctx.mouse.x, ctx.mouse.y) {
                if max_scroll > 0 {
                    state_ptr.scroll_y -= ctx.mouse.scroll_y * 30.0;
                    state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, max_scroll);
                    ctx.scroll_consumed = true;
                    ui_emit_audio(.SCROLL, scroll_id, clamp(abs(ctx.mouse.scroll_y) / 5.0, 0.0, 1.0));
                }
            }
        }
    }
}

// tabs

ui_begin_tab_bar :: (label: string, selected: *s32, tab_names: [] string) -> s32 {
    ctx := ui_ctx;
    style := *ctx.style;

    ui_push_id(label);
    ui_begin_row();

    for i : 0..tab_names.count-1 {
        tab_id := ui_get_id(tab_names[i]);
        text_w := msdf_measure_text_pixels(ctx.font, tab_names[i], style.font_size);
        w := text_w + style.padding * 2;
        h := style.button_height;

        rect := ui_allocate_rect(w, h);

        ui_try_hot(tab_id, rect);
        ui_try_active(tab_id);
        if ui_was_clicked(tab_id) {
            selected.* = cast(s32) i;
            ui_emit_audio(.TAB_SELECT, tab_id);
        }

        is_selected := selected.* == cast(s32) i;

        bg: Vector4;
        if is_selected                    bg = style.color_accent;
        else if ui_is_active(tab_id)      bg = style.color_bg_active;
        else if ui_is_hot(tab_id)         bg = style.color_bg_hover;
        else                              bg = style.color_bg;

        ui_cmd_rect(rect, bg);

        text_x := ui_text_centered_x(rect, tab_names[i], style.font_size);
        text_y := ui_text_baseline_y(rect, style.font_size);
        ui_cmd_text(tab_names[i], text_x, text_y, style.font_size, style.color_text);
    }

    ui_end_row();

    return selected.*;
}

ui_end_tab_bar :: () {
    ui_pop_id();
}

// tables (simple column-based)

UI_Table_Context :: struct {
    column_count: s32;
    column_widths: [16] float32;
    current_column: s32;
    row_rect: UI_Rect;
}

_ui_table_ctx: UI_Table_Context;

ui_begin_table :: (label: string, column_count: s32, column_widths: [] float32 = .[]) {
    ctx := ui_ctx;

    _ui_table_ctx.column_count = column_count;
    _ui_table_ctx.current_column = 0;

    available_w := ui_available_width();

    if column_widths.count >= column_count {
        for i : 0..column_count-1 {
            _ui_table_ctx.column_widths[i] = column_widths[i];
        }
    } else {
        equal_w := available_w / cast(float32) column_count;
        for i : 0..column_count-1 {
            _ui_table_ctx.column_widths[i] = equal_w;
        }
    }

    ui_push_id(label);
}

ui_end_table :: () {
    ui_pop_id();
}

ui_table_next_row :: () {
    _ui_table_ctx.current_column = 0;
    row_h := ui_ctx.style.font_size + ui_ctx.style.padding;
    _ui_table_ctx.row_rect = ui_allocate_rect(0, row_h);
}

ui_table_next_column :: (text: string) {
    ctx := ui_ctx;
    style := *ctx.style;
    tc := *_ui_table_ctx;

    if tc.current_column >= tc.column_count return;

    col_x := _ui_table_ctx.row_rect.x;
    for i : 0..tc.current_column-1 {
        col_x += tc.column_widths[i];
    }

    col_w := tc.column_widths[tc.current_column];
    col_rect: UI_Rect = .{col_x, tc.row_rect.y, col_w, tc.row_rect.h};

    text_x := col_rect.x + style.padding * 0.5;
    text_y := ui_text_baseline_y(col_rect, style.font_size);
    ui_cmd_text(text, text_x, text_y, style.font_size, style.color_text);

    tc.current_column += 1;
}

ui_table_header_row :: (headers: [] string) {
    ctx := ui_ctx;
    style := *ctx.style;

    ui_table_next_row();

    ui_cmd_rect(_ui_table_ctx.row_rect, style.color_bg);

    for i : 0..headers.count-1 {
        if i >= _ui_table_ctx.column_count break;
        ui_table_next_column(headers[i]);
    }
}

// selectable (list item that can be clicked)

ui_selectable :: (label: string, is_selected: bool) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked  ui_emit_audio(.BUTTON_CLICK, id);

    bg: Vector4;
    if is_selected                   bg = style.color_accent;
    else if ui_is_active(id)         bg = style.color_bg_active;
    else if ui_is_hot(id)            bg = style.color_bg_hover;
    else                             bg = .{0, 0, 0, 0};

    if bg.w > 0 {
        ui_cmd_rect(rect, bg);
    }

    text_x := rect.x + style.padding;
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);

    return clicked;
}

// image placeholder

ui_image_placeholder :: (label: string, width: float32, height: float32, tint: Vector4 = .{0.3, 0.3, 0.3, 1}) {
    rect := ui_allocate_rect(width, height);
    ui_cmd_rect(rect, tint);
    ui_cmd_rect_outline(rect, ui_ctx.style.color_border);

    text_x := ui_text_centered_x(rect, label, ui_ctx.style.font_size);
    text_y := ui_text_baseline_y(rect, ui_ctx.style.font_size);
    ui_cmd_text(label, text_x, text_y, ui_ctx.style.font_size, ui_ctx.style.color_text_disabled);
}

ui_image :: (texture_id: GLuint, width: float32, height: float32, tint: Vector4 = .{1, 1, 1, 1}) -> UI_Rect {
    rect := ui_allocate_rect(width, height);
    ui_cmd_image(texture_id, rect, tint);
    return rect;
}

ui_render_target_view :: (target: *UI_Render_Target, width: float32, height: float32, tint: Vector4 = .{1, 1, 1, 1}) -> UI_Rect {
    rect := ui_allocate_rect(width, height);
    target_w := cast(s32) max(width, 1);
    target_h := cast(s32) max(height, 1);

    if ui_render_target_ensure_size(target, target_w, target_h) {
        ui_cmd_image(target.color_texture, rect, tint);
    } else {
        ui_cmd_rect(rect, .{0.16, 0.05, 0.05, 1.0});
    }

    ui_cmd_rect_outline(rect, ui_ctx.style.color_border);
    return rect;
}

ui_render_target_view_fill :: (label: string, target: *UI_Render_Target, min_height: float32 = 32, tint: Vector4 = .{1, 1, 1, 1}) -> UI_Render_Target_View_Input {
    ctx := ui_ctx;

    width := ui_available_width();
    height := ui_available_height();
    if height < min_height height = min_height;

    rect := ui_allocate_rect(width, height);
    target_w := cast(s32) max(rect.w, 1);
    target_h := cast(s32) max(rect.h, 1);

    if ui_render_target_ensure_size(target, target_w, target_h) {
        ui_cmd_image(target.color_texture, rect, tint);
    } else {
        ui_cmd_rect(rect, .{0.16, 0.05, 0.05, 1.0});
    }

    ui_cmd_rect_outline(rect, ctx.style.color_border);

    id := ui_get_id(label);
    hovered := ui_try_hot(id, rect);
    if hovered && ctx.mouse.left_pressed {
        ctx.focused = id;
    }
    ui_try_active(id);

    result: UI_Render_Target_View_Input;
    result.rect = rect;
    result.hovered = hovered;
    result.active = ui_is_active(id);
    result.focused = ui_is_focused(id);
    result.local_mouse_x = clamp(ctx.mouse.x - rect.x, 0.0, rect.w);
    result.local_mouse_y = clamp(ctx.mouse.y - rect.y, 0.0, rect.h);
    result.normalized_mouse_x = ifx rect.w > 0 then result.local_mouse_x / rect.w else 0;
    result.normalized_mouse_y = ifx rect.h > 0 then result.local_mouse_y / rect.h else 0;
    result.left_down = (result.hovered || result.active) && ctx.mouse.left_down;
    result.left_pressed = result.hovered && ctx.mouse.left_pressed;
    result.left_released = (result.hovered || result.active) && ctx.mouse.left_released;
    result.right_down = result.hovered && ctx.mouse.right_down;
    result.right_pressed = result.hovered && ctx.mouse.right_pressed;
    result.right_released = result.hovered && ctx.mouse.right_released;
    result.scroll_y = ifx result.hovered then ctx.mouse.scroll_y else 0;
    result.target_width = target.width;
    result.target_height = target.height;

    return result;
}

ui_same_line :: (spacing: float32 = -1) {
    ctx := ui_ctx;
    layout := ui_current_layout();

    if layout.mode == .VERTICAL {
        layout.cursor_y -= ctx.style.item_spacing;
    }
}

// debug overlay

ui_debug_overlay :: () {
    ctx := ui_ctx;
    style := *ctx.style;

    ui_label(tprint("Mouse: %, %", cast(s32) ctx.mouse.x, cast(s32) ctx.mouse.y));
    ui_label(tprint("Hot: %", ctx.hot));
    ui_label(tprint("Active: %", ctx.active));
    ui_label(tprint("Focused: %", ctx.focused));
    ui_label(tprint("Draw cmds: %", ctx.draw_buffers.commands.count));
    ui_label(tprint("Layout depth: %", ctx.layout_depth));
    ui_label(tprint("FPS: %", ifx ctx.dt > 0 then cast(s32)(1.0 / ctx.dt) else 0));
}

// open/close window programmatically

ui_set_window_open :: (title: string, open: bool) {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr != null {
        state_ptr.open = open;
    }
}

ui_is_window_open :: (title: string) -> bool {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr != null return state_ptr.open;
    return true;
}

ui_mouse_over_open_window :: () -> bool {
    ctx := ui_ctx;
    for * state, id: ctx.window_states {
        if !state.is_window continue;
        if !state.open continue;
        rect := state.rect;
        if state.collapsed {
            rect.h = ctx.style.window_title_height;
        }
        if rect_contains(rect, ctx.mouse.x, ctx.mouse.y) return true;
    }
    return false;
}

ui_window_rect :: (title: string) -> UI_Rect, bool {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr == null return .{}, false;
    return state_ptr.rect, true;
}

ui_window_force_front :: (title: string) {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr == null return;
    state_ptr.z_order = ui_ctx.next_z_order;
    ui_ctx.next_z_order += 1;
}

ui_window_set_rect :: (title: string, rect: UI_Rect) {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr == null return;
    state_ptr.rect = rect;
}

ui_window_z_order :: (title: string) -> s32 {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr == null return -1;
    return state_ptr.z_order;
}

ui_window_title_is_active :: (title: string) -> bool {
    id := ui_window_id(title);
    title_id := ui_hash_fnv1a("#title", id);
    return ui_is_active(title_id);
}

ui_window_title_released_over :: (dragged_title: string, target_title: string) -> bool {
    if !ui_window_title_is_active(dragged_title) return false;
    if !ui_ctx.mouse.left_released return false;
    target_rect, ok := ui_window_rect(target_title);
    if !ok return false;
    title_rect: UI_Rect = .{target_rect.x, target_rect.y, target_rect.w, ui_ctx.style.window_title_height};
    return rect_contains(title_rect, ui_ctx.mouse.x, ui_ctx.mouse.y);
}

ui_drag_float :: (label: string, value: *float32, speed: float32 = 0.1, min_val: float32 = -1000000, max_val: float32 = 1000000) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.input_height;
    rect := ui_allocate_rect(0, h);

    label_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    label_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, rect.x, label_y, style.font_size, style.color_text);

    drag_x := rect.x + label_w + style.padding;
    drag_w := rect.w - label_w - style.padding;
    drag_rect: UI_Rect = .{drag_x, rect.y, drag_w, h};

    ui_try_hot(id, drag_rect);
    if ui_try_active(id)  ui_emit_audio(.SLIDER_GRAB, id);

    changed := false;
    if ui_is_active(id) && ctx.mouse.left_down {
        raw := value.* + ctx.mouse.dx * speed;
        raw = clamp(raw, min_val, max_val);
        new_value := floor(raw * 100.0 + 0.5) / 100.0;
        if new_value != value.* {
            old_value := value.*;
            value.* = new_value;
            changed = true;
            delta := abs(new_value - old_value) / (max_val - min_val);
            ui_emit_audio(.SLIDER_CHANGE, id, clamp(delta * 5.0, 0.0, 1.0));
        }
    }

    if ui_is_active(id) && ctx.mouse.left_released  ui_emit_audio(.SLIDER_RELEASE, id);

    bg := ifx ui_is_active(id) then style.color_bg_active
          else ifx ui_is_hot(id) then style.color_bg_hover
          else style.color_input_bg;
    ui_cmd_rect(drag_rect, bg);
    ui_cmd_rect_outline(drag_rect, style.color_border);

    value_text := tprint("%.2", value.*);
    value_x := drag_rect.x + style.padding * 0.5;
    value_y := ui_text_baseline_y(drag_rect, style.font_size);
    ui_cmd_text(value_text, value_x, value_y, style.font_size, style.color_text);

    return changed;
}

ui_drag_int :: (label: string, value: *s32, speed: float32 = 0.5, min_val: s32 = -1000000, max_val: s32 = 1000000) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.input_height;
    rect := ui_allocate_rect(0, h);

    label_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    label_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, rect.x, label_y, style.font_size, style.color_text);

    drag_x := rect.x + label_w + style.padding;
    drag_w := rect.w - label_w - style.padding;
    drag_rect: UI_Rect = .{drag_x, rect.y, drag_w, h};

    ui_try_hot(id, drag_rect);
    if ui_try_active(id)  ui_emit_audio(.SLIDER_GRAB, id);

    changed := false;
    if ui_is_active(id) && ctx.mouse.left_down {
        f := cast(float32) value.* + ctx.mouse.dx * speed;
        f = clamp(f, cast(float32) min_val, cast(float32) max_val);
        new_value := cast(s32) (f + ifx f >= 0 then 0.5 else -0.5);
        if new_value != value.* {
            old_value := value.*;
            value.* = new_value;
            changed = true;
            range := cast(float32)(max_val - min_val);
            delta := abs(cast(float32)(new_value - old_value)) / range;
            ui_emit_audio(.SLIDER_CHANGE, id, clamp(delta * 5.0, 0.0, 1.0));
        }
    }

    if ui_is_active(id) && ctx.mouse.left_released  ui_emit_audio(.SLIDER_RELEASE, id);

    bg := ifx ui_is_active(id) then style.color_bg_active
          else ifx ui_is_hot(id) then style.color_bg_hover
          else style.color_input_bg;
    ui_cmd_rect(drag_rect, bg);
    ui_cmd_rect_outline(drag_rect, style.color_border);

    value_text := tprint("%", value.*);
    value_x := drag_rect.x + style.padding * 0.5;
    value_y := ui_text_baseline_y(drag_rect, style.font_size);
    ui_cmd_text(value_text, value_x, value_y, style.font_size, style.color_text);

    return changed;
}

ui_toggle :: (label_on: string, label_off: string, value: *bool) -> bool {
    label := ifx value.* then label_on else label_off;
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label_on);

    text_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    w := text_w + style.padding * 2;
    h := style.button_height;
    rect := ui_allocate_rect(w, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked {
        value.* = !value.*;
        ui_emit_audio(.CHECKBOX_TOGGLE, id);
    }

    bg: Vector4;
    if value.* {
        if ui_is_active(id)        bg = style.color_accent_active;
        else if ui_is_hot(id)      bg = style.color_accent_hover;
        else                       bg = style.color_accent;
    } else {
        if ui_is_active(id)        bg = style.color_bg_active;
        else if ui_is_hot(id)      bg = style.color_bg_hover;
        else                       bg = style.color_bg;
    }

    ui_cmd_rect(rect, bg);
    ui_cmd_rect_outline(rect, style.color_border);

    text_x := ui_text_centered_x(rect, label, style.font_size);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, text_x, text_y, style.font_size, style.color_text);

    return clicked;
}

// stat bar

ui_stat_bar :: (label: string, current: float32, maximum: float32, fill_color: Vector4 = .{0.26, 0.59, 0.98, 1.0}) {
    ctx := ui_ctx;
    style := *ctx.style;

    h := style.slider_height;
    rect := ui_allocate_rect(0, h);

    ui_cmd_rect(rect, style.color_slider_track);

    fraction := clamp(current / maximum, 0.0, 1.0);
    fill_w := fraction * rect.w;
    if fill_w > 0 {
        ui_cmd_rect(.{rect.x, rect.y, fill_w, rect.h}, fill_color);
    }

    display := tprint("% : % / %", label, cast(s32) current, cast(s32) maximum);
    text_x := ui_text_centered_x(rect, display, style.font_size);
    text_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(display, text_x, text_y, style.font_size, style.color_text);
}

// list box

ui_list_box :: (label: string, items: [] string, selected: *s32, visible_count: s32 = 5) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;

    ui_push_id(label);
    defer ui_pop_id();

    ui_label(label);

    item_h := style.font_size + style.padding;
    total_h := item_h * cast(float32) visible_count;

    scroll := ui_begin_scroll_region(label, total_h);

    changed := false;
    for i : 0..items.count-1 {
        is_selected := cast(s32) i == selected.*;
        if ui_selectable(items[i], is_selected) {
            selected.* = cast(s32) i;
            changed = true;
        }
    }

    ui_end_scroll_region();

    return changed;
}

// file selector

UI_File_Select_Entry :: struct {
    name: string;
    full_path: string;
    is_directory: bool;
    size: s64;
    modification_time: Apollo_Time;
}

UI_File_Select_Mode :: enum {
    FILE;
    DIRECTORY;
}

UI_File_Select_Create_Kind :: enum {
    NONE;
    FILE;
    DIRECTORY;
}

UI_File_Select_Sort_Column :: enum {
    NAME;
    SIZE;
    MODIFIED;
}

UI_FILE_SELECT_PLACES_PATH :: "data/file_select_places.txt";
UI_FILE_SELECT_CONTEXT_MENU_ID :: #run ui_hash_fnv1a("file_select_places_context_menu");

UI_File_Select_Context_Kind :: enum {
    NONE;
    ENTRY_DIRECTORY;
    PLACE;
}

UI_File_Select_State :: struct {
    current_directory: string;
    entries: [..] UI_File_Select_Entry;
    places: [..] string;
    mode: UI_File_Select_Mode = .FILE;
    show_dotfiles: bool;
    sort_column: UI_File_Select_Sort_Column = .NAME;
    sort_ascending: bool = true;
    name_column_fraction: float32;
    size_column_fraction: float32;

    selected_index: s32 = -1;
    selected_path: string;

    path_buffer: [256] u8;
    path_length: s32;
    create_name_buffer: [256] u8;
    create_name_length: s32;
    create_kind: UI_File_Select_Create_Kind;
    create_error: string;
    context_kind: UI_File_Select_Context_Kind;
    context_path: string;
    context_index: s32 = -1;
    context_x: float32;
    context_y: float32;

    initialized: bool;
    places_loaded: bool;
    needs_refresh: bool;
    name_column_width: float32;
    size_column_width: float32;

    search_mode: s32;
    search_query_buffer: [256] u8;
    search_query_length: s32;
    search_files: [..] string;
    search_results: [..] string;
    search_files_collected: s32;
    search_files_searched: s32;
    search_done: bool;
    search_had_error: bool;
    search_status: string;
}

ui_file_select_free_entries :: (state: *UI_File_Select_State) {
    for state.entries {
        free(it.name);
        free(it.full_path);
    }
    array_reset(*state.entries);
}

ui_file_select_free_places :: (state: *UI_File_Select_State) {
    for state.places {
        free(it);
    }
    array_reset(*state.places);
}

ui_file_select_set_selected_path :: (state: *UI_File_Select_State, path: string) {
    if state.selected_path.count  free(state.selected_path);
    state.selected_path = copy_string(path);
}

ui_file_select_clear_create_error :: (state: *UI_File_Select_State) {
    if state.create_error.count  free(state.create_error);
    state.create_error = "";
}

ui_file_select_set_error :: (state: *UI_File_Select_State, message: string) {
    ui_file_select_clear_create_error(state);
    state.create_error = copy_string(message);
}

ui_file_select_sync_path_buffer :: (state: *UI_File_Select_State) {
    state.path_length = cast(s32) min(state.current_directory.count, state.path_buffer.count - 1);
    if state.path_length > 0 {
        memcpy(state.path_buffer.data, state.current_directory.data, state.path_length);
    }
    for i: state.path_length..state.path_buffer.count - 1 state.path_buffer[i] = 0;
}

ui_file_select_copy_browser_directory :: (directory: string) -> string {
    absolute_directory, absolute_ok := get_absolute_path(directory);
    if absolute_ok {
        normalize_slashes(absolute_directory);
        return copy_string(absolute_directory);
    }

    result := copy_string(directory);
    normalize_slashes(result);
    return result;
}

ui_file_select_normalized_copy :: (path: string) -> string {
    result := ui_file_select_copy_browser_directory(path);
    normalize_slashes(result);
    ui_file_select_collapse_drive_root_slashes(*result);
    return result;
}

ui_file_select_path_equal :: (a: string, b: string) -> bool {
    if a.count != b.count return false;
    for i: 0..a.count-1 {
        ca := a[i];
        cb := b[i];
        if ca == #char "\\" ca = #char "/";
        if cb == #char "\\" cb = #char "/";
        if ca != cb return false;
    }
    return true;
}

ui_file_select_place_index :: (state: *UI_File_Select_State, path: string) -> s32 {
    normalized := ui_file_select_normalized_copy(path);
    defer free(normalized);

    for i: 0..state.places.count-1 {
        if ui_file_select_path_equal(state.places[i], normalized) return cast(s32) i;
    }
    return -1;
}

ui_file_select_add_place :: (state: *UI_File_Select_State, path: string) -> bool {
    if path.count == 0 return false;
    if ui_file_select_place_index(state, path) >= 0 return false;

    normalized := ui_file_select_normalized_copy(path);
    array_add(*state.places, normalized);
    return true;
}

ui_file_select_save_places :: (state: *UI_File_Select_State) -> bool {
    out: [..] u8;
    defer array_free(out);

    for place: state.places {
        for i: 0..place.count-1 array_add(*out, place[i]);
        array_add(*out, #char "\n");
    }

    make_directory_if_it_does_not_exist("data", recursive = true);
    return write_entire_file(UI_FILE_SELECT_PLACES_PATH, out.data, out.count);
}

ui_file_select_remove_place :: (state: *UI_File_Select_State, index: s32) -> bool {
    if index < 0 || index >= state.places.count return false;
    free(state.places[index]);
    for i: index..state.places.count-2 {
        state.places[i] = state.places[i + 1];
    }
    state.places.count -= 1;
    return true;
}

ui_file_select_add_default_place :: (state: *UI_File_Select_State, path: string) {
    if path.count == 0 return;
    ui_file_select_add_place(state, path);
}

ui_file_select_load_default_places :: (state: *UI_File_Select_State) {
    home, ok := get_home_directory();
    if ok {
        ui_file_select_add_default_place(state, home);
        ui_file_select_add_default_place(state, ui_file_select_join_path(home, "Desktop"));
        ui_file_select_add_default_place(state, ui_file_select_join_path(home, "Documents"));
        ui_file_select_add_default_place(state, ui_file_select_join_path(home, "Downloads"));
        ui_file_select_add_default_place(state, ui_file_select_join_path(home, "Pictures"));
        ui_file_select_add_default_place(state, ui_file_select_join_path(home, "projects"));
    }
}

ui_file_select_load_places :: (state: *UI_File_Select_State) {
    if state.places_loaded return;
    state.places_loaded = true;

    data, ok := read_entire_file(UI_FILE_SELECT_PLACES_PATH, log_errors = false);
    if !ok {
        ui_file_select_load_default_places(state);
        ui_file_select_save_places(state);
        return;
    }
    defer free(data);

    line_start := 0;
    for i: 0..data.count {
        if i < data.count && data[i] != #char "\n" && data[i] != #char "\r" continue;
        if i > line_start {
            line: string;
            line.data = data.data + line_start;
            line.count = i - line_start;
            ui_file_select_add_place(state, line);
        }
        line_start = i + 1;
        if i + 1 < data.count && data[i] == #char "\r" && data[i + 1] == #char "\n" {
            line_start = i + 2;
        }
    }

    if state.places.count == 0 {
        ui_file_select_load_default_places(state);
        ui_file_select_save_places(state);
    }
}

ui_file_select_collapse_drive_root_slashes :: (path: *string) {
    if path.*.count < 4 return;
    if path.*[1] != #char ":" return;
    if path.*[2] != #char "/" return;

    while path.*.count > 3 && path.*[3] == #char "/" {
        for i: 3..path.*.count - 2 path.*[i] = path.*[i + 1];
        path.*.count -= 1;
    }
}

ui_file_select_set_directory :: (state: *UI_File_Select_State, directory: string) {
    new_directory := ui_file_select_copy_browser_directory(directory);
    normalize_slashes(new_directory);
    ui_file_select_collapse_drive_root_slashes(*new_directory);
    if state.current_directory.count  free(state.current_directory);
    state.current_directory = new_directory;
    state.selected_index = -1;
    ui_file_select_set_selected_path(state, "");
    ui_file_select_sync_path_buffer(state);
    state.needs_refresh = true;
}

ui_file_select_is_windows_drive_root :: (path: string) -> bool {
    return path.count == 3 && path[1] == #char ":" && path[2] == #char "/";
}

ui_file_select_parent_directory :: (directory: string) -> string {
    normalized := copy_temporary_string(directory);
    normalize_slashes(normalized);

    while normalized.count > 1 {
        if normalized[normalized.count - 1] != #char "/" break;
        if ui_file_select_is_windows_drive_root(normalized) break;
        normalized.count -= 1;
    }

    if normalized.count == 0 return ".";
    if normalized.count == 1 && normalized[0] == #char "/" return normalized;
    if ui_file_select_is_windows_drive_root(normalized) return normalized;

    if normalized.count == 2 && normalized[1] == #char ":" {
        return tprint("%/", normalized);
    }

    last_slash: s32 = -1;
    for i: 0..normalized.count - 1 {
        if normalized[i] == #char "/" last_slash = cast(s32) i;
    }

    if last_slash < 0 return ".";
    if last_slash == 0 return "/";

    parent := normalized;
    parent.count = last_slash;
    if parent.count == 2 && parent[1] == #char ":" {
        parent.count = 3;
    }
    return parent;
}

ui_file_select_join_path :: (directory: string, name: string) -> string {
    if directory.count == 0 return copy_string(name);
    if directory[directory.count - 1] == #char "/" return tprint("%%", directory, name);
    return tprint("%/%", directory, name);
}

ui_file_select_is_default_ignored :: (name: string) -> bool {
    return name == ".git" || name == ".svn" || name == ".hg";
}

ui_file_select_is_dotfile :: (name: string) -> bool {
    return name.count > 0 && name[0] == #char ".";
}

ui_file_select_name_has_path_separator :: (name: string) -> bool {
    for name {
        if it == #char "/" || it == #char "\\" return true;
    }
    return false;
}

ui_file_select_format_size :: (entry: UI_File_Select_Entry) -> string {
    if entry.is_directory return "<dir>";
    if entry.size < 0 return "";
    if entry.size < 1024 return tprint("% B", entry.size);
    if entry.size < 1024 * 1024 return tprint("% KB", entry.size / 1024);
    if entry.size < 1024 * 1024 * 1024 return tprint("% MB", entry.size / (1024 * 1024));
    return tprint("% GB", entry.size / (1024 * 1024 * 1024));
}

ui_file_select_format_modified :: (entry: UI_File_Select_Entry) -> string {
    cal := to_calendar(entry.modification_time, .LOCAL);
    month := cast(s32) cal.month_starting_at_0 + 1;
    day := cast(s32) cal.day_of_month_starting_at_0 + 1;
    return tprint("%-%-% %:%",
        cal.year,
        formatInt(month, minimum_digits = 2),
        formatInt(day, minimum_digits = 2),
        formatInt(cal.hour, minimum_digits = 2),
        formatInt(cal.minute, minimum_digits = 2));
}

ui_file_select_string_less :: (a: string, b: string) -> bool {
    count := min(a.count, b.count);
    for i: 0..count-1 {
        ca := a[i];
        cb := b[i];
        if ca >= #char "A" && ca <= #char "Z" ca += 32;
        if cb >= #char "A" && cb <= #char "Z" cb += 32;
        if ca < cb return true;
        if ca > cb return false;
    }
    return a.count < b.count;
}

ui_file_select_time_less :: (a: Apollo_Time, b: Apollo_Time) -> bool {
    aa := cast(S128) a;
    bb := cast(S128) b;
    if aa.high != bb.high return aa.high < bb.high;
    return aa.low < bb.low;
}

ui_file_select_string_compare :: (a: string, b: string) -> s32 {
    if ui_file_select_string_less(a, b) return -1;
    if ui_file_select_string_less(b, a) return 1;
    return 0;
}

ui_file_select_entry_compare :: (state: *UI_File_Select_State, a: UI_File_Select_Entry, b: UI_File_Select_Entry) -> s32 {
    if a.is_directory != b.is_directory {
        return ifx a.is_directory then cast(s32) -1 else cast(s32) 1;
    }

    result: s32;
    if state.sort_column == .NAME {
        result = ui_file_select_string_compare(a.name, b.name);
    } else if state.sort_column == .SIZE {
        if a.size == b.size {
            result = ui_file_select_string_compare(a.name, b.name);
        } else if a.size < b.size {
            result = -1;
        } else {
            result = 1;
        }
    } else {
        if a.modification_time == b.modification_time {
            result = ui_file_select_string_compare(a.name, b.name);
        } else if ui_file_select_time_less(a.modification_time, b.modification_time) {
            result = -1;
        } else {
            result = 1;
        }
    }

    return ifx state.sort_ascending then result else -result;
}

ui_file_select_entry_less :: (state: *UI_File_Select_State, a: UI_File_Select_Entry, b: UI_File_Select_Entry) -> bool {
    return ui_file_select_entry_compare(state, a, b) < 0;
}

ui_file_select_sort_entries :: (state: *UI_File_Select_State) {
    entries := *state.entries;
    for i: 1..entries.count-1 {
        entry := entries.*[i];
        j := i;
        while j > 0 && ui_file_select_entry_less(state, entry, entries.*[j - 1]) {
            entries.*[j] = entries.*[j - 1];
            j -= 1;
        }
        entries.*[j] = entry;
    }
}

ui_file_select_sync_selected_index :: (state: *UI_File_Select_State) {
    if state.selected_path.count == 0 {
        state.selected_index = -1;
        return;
    }

    state.selected_index = -1;
    for i: 0..state.entries.count-1 {
        if state.entries[i].full_path == state.selected_path {
            state.selected_index = cast(s32) i;
            return;
        }
    }
}

ui_file_select_set_sort :: (state: *UI_File_Select_State, column: UI_File_Select_Sort_Column) {
    if state.sort_column == column {
        state.sort_ascending = !state.sort_ascending;
    } else {
        state.sort_column = column;
        state.sort_ascending = true;
    }
    ui_file_select_sort_entries(state);
    ui_file_select_sync_selected_index(state);
}

ui_file_select_refresh :: (state: *UI_File_Select_State) {
    ui_file_select_free_entries(state);
    ui_file_select_clear_create_error(state);
    state.selected_index = -1;
    state.needs_refresh = false;

    Visitor_Context :: struct {
        entries: *[..] UI_File_Select_Entry;
        mode: UI_File_Select_Mode;
        show_dotfiles: bool;
    }

    visitor :: (info: *File_Visit_Info, ctx: *Visitor_Context) {
        if ui_file_select_is_default_ignored(info.short_name) return;
        if !ctx.show_dotfiles && ui_file_select_is_dotfile(info.short_name) return;
        if ctx.mode == .DIRECTORY && !info.is_directory return;

        entry: UI_File_Select_Entry;
        entry.name = copy_string(info.short_name);
        entry.full_path = copy_string(info.full_name);
        normalize_slashes(entry.full_path);
        ui_file_select_collapse_drive_root_slashes(*entry.full_path);
        entry.is_directory = info.is_directory;
        entry.size = info.size;
        entry.modification_time = info.modification_time;

        array_add(ctx.entries, entry);
    }

    ctx: Visitor_Context = .{*state.entries, state.mode, state.show_dotfiles};
    ok := visit_files(state.current_directory, false, *ctx, visitor, visit_files = state.mode == .FILE, visit_directories = true, follow_directory_symlinks = false);
    if !ok {
        ui_file_select_set_error(state, tprint("Could not open directory: %", state.current_directory));
    }
    ui_file_select_sort_entries(state);
    ui_file_select_sync_selected_index(state);
}

ui_file_select_set_mode :: (state: *UI_File_Select_State, mode: UI_File_Select_Mode) {
    if state.mode == mode return;
    state.mode = mode;
    state.selected_index = -1;
    ui_file_select_set_selected_path(state, "");
    state.needs_refresh = true;
}

ui_file_select_begin_create :: (state: *UI_File_Select_State, kind: UI_File_Select_Create_Kind) {
    state.create_kind = kind;
    state.create_name_length = 0;
    for i: 0..state.create_name_buffer.count - 1 state.create_name_buffer[i] = 0;
    ui_file_select_clear_create_error(state);
}

ui_file_select_name_from_create_buffer :: (state: *UI_File_Select_State) -> string {
    result: string;
    result.data = state.create_name_buffer.data;
    result.count = state.create_name_length;
    return result;
}

ui_file_select_finish_create :: (state: *UI_File_Select_State) -> bool {
    name := ui_file_select_name_from_create_buffer(state);
    if name.count == 0 {
        ui_file_select_clear_create_error(state);
        state.create_error = copy_string("Name is required");
        return false;
    }

    if ui_file_select_name_has_path_separator(name) {
        ui_file_select_clear_create_error(state);
        state.create_error = copy_string("Name cannot contain path separators");
        return false;
    }

    path := ui_file_select_join_path(state.current_directory, name);
    ok := false;
    if state.create_kind == .DIRECTORY {
        ok = make_directory_if_it_does_not_exist(path);
    } else if state.create_kind == .FILE {
        ok = write_entire_file(path, "");
    }

    if !ok {
        ui_file_select_clear_create_error(state);
        state.create_error = copy_string("Could not create entry");
        return false;
    }

    created_kind := state.create_kind;
    state.create_kind = .NONE;
    if created_kind == .DIRECTORY {
        ui_file_select_set_directory(state, path);
    } else {
        ui_file_select_set_selected_path(state, path);
        state.selected_index = -1;
        state.needs_refresh = true;
    }
    ui_file_select_clear_create_error(state);
    return true;
}

ui_file_select_cell_text :: (text: string, rect: UI_Rect, font_size: float32, color: Vector4, right_reserved: float32 = 0) {
    style := *ui_ctx.style;
    clip_rect := rect;
    if clip_rect.w <= style.padding return;
    ui_cmd_scissor_push(clip_rect);
    text_x := rect.x + style.padding;
    text_y := ui_text_baseline_y(rect, font_size);
    ui_cmd_text(text, text_x, text_y, font_size, color);
    ui_cmd_scissor_pop();
}

ui_file_select_set_context_path :: (state: *UI_File_Select_State, path: string) {
    if state.context_path.count  free(state.context_path);
    state.context_path = copy_string(path);
}

ui_file_select_open_context_menu :: (state: *UI_File_Select_State, kind: UI_File_Select_Context_Kind, path: string, index: s32) {
    state.context_kind = kind;
    state.context_index = index;
    state.context_x = ui_ctx.mouse.x;
    state.context_y = ui_ctx.mouse.y;
    ui_file_select_set_context_path(state, path);
    ui_ctx.open_popup_id = UI_FILE_SELECT_CONTEXT_MENU_ID;
    ui_ctx.popup_rect = .{state.context_x, state.context_y, 180, ui_ctx.style.button_height + ui_ctx.style.padding};
}

ui_file_select_render_row :: (state: *UI_File_Select_State, entry: UI_File_Select_Entry, index: s32, rect: UI_Rect, name_w: float32, size_w: float32) -> (clicked: bool, right_clicked: bool) {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(entry.full_path);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked  ui_emit_audio(.BUTTON_CLICK, id);
    right_clicked := ui_is_hot(id) && ctx.mouse.right_pressed;

    selected := state.selected_index == index;
    bg: Vector4;
    if selected {
        bg = style.color_accent;
    } else if ui_is_hot(id) {
        bg = style.color_bg_hover;
    } else if index % 2 == 0 {
        bg = .{0.095, 0.10, 0.11, 1};
    } else {
        bg = .{0.075, 0.08, 0.09, 1};
    }
    ui_cmd_rect(rect, bg);

    name_rect: UI_Rect = .{rect.x, rect.y, name_w, rect.h};
    size_rect: UI_Rect = .{rect.x + name_w, rect.y, size_w, rect.h};
    modified_rect: UI_Rect = .{rect.x + name_w + size_w, rect.y, rect.w - name_w - size_w, rect.h};

    ui_cmd_rect(.{size_rect.x, rect.y, 1, rect.h}, style.color_border);
    ui_cmd_rect(.{modified_rect.x, rect.y, 1, rect.h}, style.color_border);

    display_name := ifx entry.is_directory then tprint("%/", entry.name) else entry.name;
    text_color := ifx entry.is_directory then .{0.62, 0.78, 1.0, 1} else style.color_text;
    if selected text_color = .{1, 1, 1, 1};

    ui_file_select_cell_text(display_name, name_rect, style.font_size, text_color);
    ui_file_select_cell_text(ui_file_select_format_size(entry), size_rect, style.font_size, style.color_text_disabled);
    ui_file_select_cell_text(ui_file_select_format_modified(entry), modified_rect, style.font_size, style.color_text_disabled);

    return clicked, right_clicked;
}

ui_file_select_sort_indicator :: (state: *UI_File_Select_State, column: UI_File_Select_Sort_Column) -> string {
    if state.sort_column != column return "";
    return ifx state.sort_ascending then "^" else "v";
}

ui_file_select_render_header_cell :: (state: *UI_File_Select_State, label: string, column: UI_File_Select_Sort_Column, rect: UI_Rect) {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    ui_try_hot(id, rect);
    ui_try_active(id);
    if ui_was_clicked(id) {
        ui_file_select_set_sort(state, column);
        ui_emit_audio(.BUTTON_CLICK, id);
    }

    bg := ifx ui_is_active(id) then style.color_bg_active else ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(rect, bg);

    indicator := ui_file_select_sort_indicator(state, column);
    indicator_reserved: float32 = 0;
    if indicator.count > 0 {
        indicator_reserved = msdf_measure_text_pixels(ctx.font, indicator, style.font_size) + style.padding * 2;
    }

    label_rect := rect;
    label_rect.w -= indicator_reserved;
    ui_file_select_cell_text(label, label_rect, style.font_size, style.color_text_disabled);

    if indicator.count > 0 {
        text_y := ui_text_baseline_y(rect, style.font_size);
        indicator_w := msdf_measure_text_pixels(ctx.font, indicator, style.font_size);
        indicator_rect: UI_Rect = .{rect.x + rect.w - indicator_reserved, rect.y, indicator_reserved, rect.h};
        ui_cmd_scissor_push(indicator_rect);
        ui_cmd_text(indicator, rect.x + rect.w - indicator_w - style.padding, text_y, style.font_size, style.color_text);
        ui_cmd_scissor_pop();
    }
}

ui_file_select_drag_divider :: (label: string, rect: UI_Rect, left_fraction: *float32, right_fraction: *float32, table_w: float32) {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    hit_rect := rect_expand(rect, 4);
    ui_try_hot(id, hit_rect);
    ui_try_active(id);
    if ui_is_active(id) && ctx.mouse.left_down && table_w > 1 {
        delta := ctx.mouse.dx / table_w;
        left_fraction.* += delta;
        right_fraction.* -= delta;
    }

    color := ifx ui_is_active(id) then style.color_accent else ifx ui_is_hot(id) then style.color_accent_hover else style.color_border;
    ui_cmd_rect(rect, color);
}

ui_file_select_column_widths :: (state: *UI_File_Select_State, table_w: float32) -> (name_w: float32, size_w: float32, modified_w: float32) {
    if state.name_column_fraction <= 0 state.name_column_fraction = 0.46;
    if state.size_column_fraction <= 0 state.size_column_fraction = 0.16;

    min_name := ifx table_w >= 260 then 100.0 else 40.0;
    min_size := ifx table_w >= 260 then 72.0 else 36.0;
    min_modified := ifx table_w >= 260 then 110.0 else 50.0;

    name_w: float32 = state.name_column_fraction * table_w;
    size_w: float32 = state.size_column_fraction * table_w;
    modified_w: float32 = table_w - name_w - size_w;

    if name_w < min_name {
        diff := min_name - name_w;
        name_w = min_name;
        modified_w -= diff;
    }
    if size_w < min_size {
        diff := min_size - size_w;
        size_w = min_size;
        modified_w -= diff;
    }
    if modified_w < min_modified {
        diff := min_modified - modified_w;
        modified_w = min_modified;
        if name_w - min_name > size_w - min_size {
            name_w -= min(diff, name_w - min_name);
        } else {
            size_w -= min(diff, size_w - min_size);
        }
    }

    if name_w + size_w + modified_w > table_w {
        scale := table_w / (name_w + size_w + modified_w);
        name_w *= scale;
        size_w *= scale;
        modified_w = table_w - name_w - size_w;
    }

    if table_w > 1 {
        state.name_column_fraction = name_w / table_w;
        state.size_column_fraction = size_w / table_w;
    }

    return name_w, size_w, modified_w;
}

ui_file_select_place_label :: (path: string) -> string {
    home, ok := get_home_directory();
    if ok && ui_file_select_path_equal(path, home) return "Home";

    normalized := copy_temporary_string(path);
    normalize_slashes(normalized);
    while normalized.count > 1 && normalized[normalized.count - 1] == #char "/" {
        normalized.count -= 1;
    }

    name := path_filename(normalized);
    if name.count > 0 return name;
    return normalized;
}

ui_file_select_render_places :: (state: *UI_File_Select_State, rect: UI_Rect) {
    ctx := ui_ctx;
    style := *ctx.style;

    ui_cmd_rect(rect, .{0.105, 0.11, 0.12, 1});
    ui_cmd_rect_outline(rect, style.color_border);

    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = rect.x + style.padding,
        cursor_y   = rect.y + style.padding,
        origin_x   = rect.x + style.padding,
        origin_y   = rect.y + style.padding,
        max_w      = rect.w - style.padding * 2,
        max_h      = rect.h - style.padding * 2,
        visible_h  = rect.h - style.padding * 2,
        row_height = 0,
        indent     = 0,
        content_max_y = rect.y + style.padding,
    });
    ui_push_id("places");

    ui_label_disabled("Places");
    row_h := style.font_size + style.padding;
    for i: 0..state.places.count-1 {
        place := state.places[i];
        row := ui_allocate_rect(0, row_h);
        id := ui_get_id(place);

        ui_try_hot(id, row);
        ui_try_active(id);

        selected := ui_file_select_path_equal(place, state.current_directory);
        bg: Vector4;
        if selected       bg = .{0.16, 0.25, 0.36, 1};
        else if ui_is_hot(id) bg = style.color_bg_hover;
        else              bg = .{0.105, 0.11, 0.12, 1};
        ui_cmd_rect(row, bg);

        label := ui_file_select_place_label(place);
        ui_file_select_cell_text(label, row, style.font_size, style.color_text);

        if ui_was_clicked(id) {
            ui_file_select_set_directory(state, place);
            ui_emit_audio(.BUTTON_CLICK, id);
        }
        if ui_is_hot(id) && ctx.mouse.right_pressed {
            ui_file_select_open_context_menu(state, .PLACE, place, cast(s32) i);
        }
    }

    ui_pop_id();
    ui_pop_layout();
}

ui_file_select_render_context_menu :: (state: *UI_File_Select_State) {
    ctx := ui_ctx;
    style := *ctx.style;
    id := UI_FILE_SELECT_CONTEXT_MENU_ID;
    if ctx.open_popup_id != id || state.context_kind == .NONE return;

    label := ifx state.context_kind == .PLACE then "Remove from Places" else "Add to Places";
    rect: UI_Rect = .{state.context_x, state.context_y, 190, style.button_height};
    ctx.popup_rect = rect;

    was_drawing_overlay := ctx.drawing_overlay;
    ctx.drawing_overlay = true;
    defer ctx.drawing_overlay = was_drawing_overlay;

    ui_cmd_rect(rect, style.color_window_bg);
    ui_cmd_rect_outline(rect, style.color_border);

    item_id := ui_hash_fnv1a(label, id);
    is_hovered := rect_contains(rect, ctx.mouse.x, ctx.mouse.y);
    if is_hovered {
        ctx.hot = item_id;
        if ctx.mouse.left_pressed {
            ctx.active = item_id;
        }
    }

    bg := ifx ctx.active == item_id then style.color_bg_active else ifx is_hovered then style.color_bg_hover else style.color_window_bg;
    ui_cmd_rect(rect, bg);
    ui_cmd_text(label, rect.x + style.padding, ui_text_baseline_y(rect, style.font_size), style.font_size, style.color_text);

    if is_hovered && ctx.active == item_id && ctx.mouse.left_released {
        if state.context_kind == .PLACE {
            ui_file_select_remove_place(state, state.context_index);
        } else {
            ui_file_select_add_place(state, state.context_path);
        }
        ui_file_select_save_places(state);
        ctx.open_popup_id = UI_ID_NONE;
        state.context_kind = .NONE;
        ui_file_select_set_context_path(state, "");
        ui_emit_audio(.BUTTON_CLICK, item_id);
    }
}

ui_file_select :: (label: string, state: *UI_File_Select_State, start_directory: string = "", mode: UI_File_Select_Mode = .FILE) -> bool {
    if !state.initialized {
        initial_directory := start_directory;
        if initial_directory.count == 0 {
            initial_directory = get_working_directory();
        }

        state.current_directory = copy_string(initial_directory);
        state.mode = mode;
        state.initialized = true;
        state.needs_refresh = true;
        ui_file_select_sync_path_buffer(state);
    } else {
        ui_file_select_set_mode(state, mode);
    }

    ui_file_select_load_places(state);

    if state.needs_refresh {
        ui_file_select_refresh(state);
    }

    ui_push_id(label);
    defer ui_pop_id();

    heading := ifx state.mode == .DIRECTORY then "Directories" else label;
    ui_label(heading);
    ui_text_input("Path", *state.path_buffer, *state.path_length);

    changed := false;

    ui_begin_row();
    old_show_dotfiles := state.show_dotfiles;
    ui_checkbox("Show dotfiles", *state.show_dotfiles);
    if state.show_dotfiles != old_show_dotfiles {
        state.needs_refresh = true;
    }
    ui_end_row();

    ui_begin_row();
    if ui_button("Go") {
        edited_path: string;
        edited_path.data = state.path_buffer.data;
        edited_path.count = state.path_length;
        ui_file_select_set_directory(state, edited_path);
    }
    if ui_button("Up") {
        parent := ui_file_select_parent_directory(state.current_directory);
        ui_file_select_set_directory(state, parent);
    }
    if ui_button("Refresh") {
        state.needs_refresh = true;
    }
    if ui_button("Debug") {
        log("file browser: dir='%', entries=%, selected_index=%, selected='%', columns(name=%, size=%), show_dotfiles=%\n",
            state.current_directory,
            state.entries.count,
            state.selected_index,
            state.selected_path,
            state.name_column_width,
            state.size_column_width,
            state.show_dotfiles
        );
    }
    ui_end_row();

    if ui_checkbox("Show dotfiles", *state.show_dotfiles) {
        state.needs_refresh = true;
    }

    ui_begin_row();
    if ui_button("New File") {
        ui_file_select_begin_create(state, .FILE);
    }
    if ui_button("New Directory") {
        ui_file_select_begin_create(state, .DIRECTORY);
    }
    ui_end_row();

    if state.create_error.count > 0 {
        ui_label_colored(state.create_error, .{1.0, 0.35, 0.25, 1.0});
    }

    ui_label(tprint("Current: %", state.current_directory));

    style := *ui_ctx.style;
    row_h := style.font_size + style.padding;
    reserved_h := row_h + style.button_height + style.item_spacing * 3;
    table_total_h := ui_available_height() - reserved_h;
    if table_total_h < row_h table_total_h = row_h;

    table_outer := ui_allocate_rect(0, table_total_h);
    show_places := table_outer.w >= 360;
    places_w: float32 = 0;
    browser_gap: float32 = 0;
    if show_places {
        places_w = clamp(table_outer.w * 0.26, 120.0, 180.0);
        browser_gap = style.item_spacing;
    }

    places_rect: UI_Rect = .{table_outer.x, table_outer.y, places_w, table_outer.h};
    browser_rect: UI_Rect = .{table_outer.x + places_w + browser_gap, table_outer.y, table_outer.w - places_w - browser_gap, table_outer.h};
    if browser_rect.w < 0 browser_rect.w = 0;

    if show_places {
        ui_file_select_render_places(state, places_rect);
    }

    table_scroller_h := browser_rect.h - row_h;
    if table_scroller_h < 0 table_scroller_h = 0;
    table_w := browser_rect.w - style.scrollbar_width;
    if table_w < 0 table_w = 0;
    name_w, size_w, modified_w := ui_file_select_column_widths(state, table_w);

    header_rect: UI_Rect = .{browser_rect.x, browser_rect.y, table_w, row_h};
    name_header: UI_Rect = .{header_rect.x, header_rect.y, name_w, header_rect.h};
    size_header: UI_Rect = .{header_rect.x + name_w, header_rect.y, size_w, header_rect.h};
    modified_header: UI_Rect = .{header_rect.x + name_w + size_w, header_rect.y, modified_w, header_rect.h};

    ui_file_select_render_header_cell(state, "Name", .NAME, name_header);
    ui_file_select_render_header_cell(state, "Size", .SIZE, size_header);
    ui_file_select_render_header_cell(state, "Modified", .MODIFIED, modified_header);

    divider_0: UI_Rect = .{header_rect.x + name_w, header_rect.y, 1, header_rect.h};
    divider_1: UI_Rect = .{header_rect.x + name_w + size_w, header_rect.y, 1, header_rect.h};
    ui_file_select_drag_divider("name_size_divider", divider_0, *state.name_column_fraction, *state.size_column_fraction, table_w);
    modified_fraction := 1.0 - state.name_column_fraction - state.size_column_fraction;
    ui_file_select_drag_divider("size_modified_divider", divider_1, *state.size_column_fraction, *modified_fraction, table_w);
    state.size_column_fraction = 1.0 - state.name_column_fraction - modified_fraction;
    name_w, size_w, modified_w = ui_file_select_column_widths(state, table_w);

    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = browser_rect.x,
        cursor_y   = browser_rect.y + row_h,
        origin_x   = browser_rect.x,
        origin_y   = browser_rect.y + row_h,
        max_w      = browser_rect.w,
        max_h      = table_scroller_h,
        visible_h  = table_scroller_h,
        row_height = 0,
        indent     = 0,
        content_max_y = browser_rect.y + row_h,
    });
    ui_begin_scroll_region_ex("file_select_entries", table_scroller_h, 0);
    for i : 0..state.entries.count-1 {
        entry := state.entries[i];
        rect := ui_allocate_rect(0, row_h);
        clicked, right_clicked := ui_file_select_render_row(state, entry, cast(s32) i, rect, name_w, size_w);
        if right_clicked && entry.is_directory {
            ui_file_select_open_context_menu(state, .ENTRY_DIRECTORY, entry.full_path, cast(s32) i);
        }
        if clicked {
            if entry.is_directory {
                ui_file_select_set_directory(state, entry.full_path);
            } else {
                state.selected_index = cast(s32) i;
                ui_file_select_set_selected_path(state, entry.full_path);
            }
        }
    }
    ui_end_scroll_region();
    ui_pop_layout();
    ui_file_select_render_context_menu(state);

    if state.selected_path.count > 0 {
        ui_label(tprint("Selected: %", state.selected_path));
    } else {
        selected_text := ifx state.mode == .DIRECTORY then tprint("Selected: current directory") else "Selected: <none>";
        ui_label_disabled(selected_text);
    }

    ui_begin_row();
    action_label := ifx state.mode == .DIRECTORY then "Select Directory" else "Open";
    if ui_button(action_label) {
        if state.mode == .DIRECTORY {
            ui_file_select_set_selected_path(state, state.current_directory);
            changed = true;
        } else if state.selected_path.count > 0 {
            changed = true;
        }
    }
    if ui_button("Clear") {
        state.selected_index = -1;
        ui_file_select_set_selected_path(state, "");
    }
    ui_end_row();

    return changed;
}

ui_file_select_create_dialog :: (state: *UI_File_Select_State) {
    if state.create_kind == .NONE return;

    title := ifx state.create_kind == .DIRECTORY then "New Directory" else "New File";
    if ui_begin_window(title, 220, 160, 380, 150) {
        ui_text_input("Name", *state.create_name_buffer, *state.create_name_length);
        if state.create_error.count > 0 {
            ui_label_colored(state.create_error, .{1.0, 0.35, 0.25, 1.0});
        }

        ui_begin_row();
        if ui_button("OK") {
            ui_file_select_finish_create(state);
        }
        if ui_button("Cancel") {
            state.create_kind = .NONE;
            ui_file_select_clear_create_error(state);
        }
        ui_end_row();

        ui_end_window();
    } else if !ui_is_window_open(title) {
        state.create_kind = .NONE;
        ui_file_select_clear_create_error(state);
    }
}

ui_file_select_destroy :: (state: *UI_File_Select_State) {
    ui_file_select_free_entries(state);
    ui_file_select_free_places(state);
    if state.current_directory.count  free(state.current_directory);
    if state.selected_path.count      free(state.selected_path);
    if state.context_path.count       free(state.context_path);
    ui_file_select_clear_create_error(state);
    state.* = .{};
}

// disabled scope

ui_begin_disabled :: () {
    ctx := ui_ctx;
    ctx.style.color_text = ctx.style.color_text_disabled;
}

ui_end_disabled :: () {
    ctx := ui_ctx;
    ctx.style.color_text = ui_default_style().color_text;
}

// style stack

UI_Style_Var :: enum {
    FONT_SIZE;
    PADDING;
    ITEM_SPACING;
    BUTTON_HEIGHT;
}

_ui_style_backup: [16] float32;
_ui_style_backup_count: s32 = 0;

ui_push_style_float :: (variable: UI_Style_Var, value: float32) {
    style := *ui_ctx.style;
    idx := _ui_style_backup_count;
    assert(idx < 16, "Style stack overflow");

    if variable == {
        case .FONT_SIZE;
            _ui_style_backup[idx] = style.font_size;
            style.font_size = value;
        case .PADDING;
            _ui_style_backup[idx] = style.padding;
            style.padding = value;
        case .ITEM_SPACING;
            _ui_style_backup[idx] = style.item_spacing;
            style.item_spacing = value;
        case .BUTTON_HEIGHT;
            _ui_style_backup[idx] = style.button_height;
            style.button_height = value;
    }
    _ui_style_backup_count += 1;
}

ui_pop_style_float :: (variable: UI_Style_Var) {
    assert(_ui_style_backup_count > 0, "Style stack underflow");
    _ui_style_backup_count -= 1;
    idx := _ui_style_backup_count;

    style := *ui_ctx.style;
    if variable == {
        case .FONT_SIZE;     style.font_size = _ui_style_backup[idx];
        case .PADDING;       style.padding = _ui_style_backup[idx];
        case .ITEM_SPACING;  style.item_spacing = _ui_style_backup[idx];
        case .BUTTON_HEIGHT; style.button_height = _ui_style_backup[idx];
    }
}

_ui_color_backup: [16] Vector4;
_ui_color_backup_count: s32 = 0;

UI_Color_Var :: enum {
    BG;
    TEXT;
    ACCENT;
    BORDER;
}

ui_push_style_color :: (variable: UI_Color_Var, value: Vector4) {
    style := *ui_ctx.style;
    idx := _ui_color_backup_count;
    assert(idx < 16, "Color style stack overflow");

    if variable == {
        case .BG;
            _ui_color_backup[idx] = style.color_bg;
            style.color_bg = value;
        case .TEXT;
            _ui_color_backup[idx] = style.color_text;
            style.color_text = value;
        case .ACCENT;
            _ui_color_backup[idx] = style.color_accent;
            style.color_accent = value;
        case .BORDER;
            _ui_color_backup[idx] = style.color_border;
            style.color_border = value;
    }
    _ui_color_backup_count += 1;
}

ui_pop_style_color :: (variable: UI_Color_Var) {
    assert(_ui_color_backup_count > 0, "Color style stack underflow");
    _ui_color_backup_count -= 1;
    idx := _ui_color_backup_count;

    style := *ui_ctx.style;
    if variable == {
        case .BG;     style.color_bg = _ui_color_backup[idx];
        case .TEXT;    style.color_text = _ui_color_backup[idx];
        case .ACCENT;  style.color_accent = _ui_color_backup[idx];
        case .BORDER;  style.color_border = _ui_color_backup[idx];
    }
}
