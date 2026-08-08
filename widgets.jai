
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
    if clicked  ui_emit_audio(.BUTTON_CLICK, id);

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


ui_dropdown :: (label: string, items: [] string, selected: *s32) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.button_height;
    rect := ui_allocate_rect(0, h);

    popup_is_open := ctx.open_popup_id == id;

    // label
    label_w := msdf_measure_text_pixels(ctx.font, label, style.font_size);
    label_x := rect.x;
    label_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, label_x, label_y, style.font_size, style.color_text);

    // combo box, the thing that activates the dropdown
    combo_x := rect.x + label_w + style.padding;
    combo_w := rect.w - label_w - style.padding;
    combo_rect: UI_Rect = .{combo_x, rect.y, combo_w, h};

    // toggle on press, not release  avoids race with end_frame auto-close
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

    // update popup position every frame while open (handles scrolling)
    if ctx.open_popup_id == id {
        item_count := cast(float32) items.count;
        visible_count := min(cast(s32) items.count, 10);
        popup_h := cast(float32) visible_count * style.button_height;
        ctx.popup_rect = .{combo_rect.x, combo_rect.y + combo_rect.h, combo_rect.w, popup_h};
    }

    // draw combo box
    bg := ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(combo_rect, bg);
    ui_cmd_rect_outline(combo_rect, style.color_border);

    // current selection text
    current_text := ifx selected.* >= 0 && selected.* < cast(s32) items.count
                    then items[selected.*]
                    else "---";
    text_x := combo_rect.x + style.padding;
    text_y := ui_text_baseline_y(combo_rect, style.font_size);
    ui_cmd_text(current_text, text_x, text_y, style.font_size, style.color_text);

    // arrow indicator
    arrow_size: float32 = 8.0;
    arrow_cx := combo_rect.x + combo_rect.w - style.padding - arrow_size * 0.5;
    arrow_cy := combo_rect.y + combo_rect.h * 0.5;
    ui_draw_triangle_down(arrow_cx, arrow_cy, arrow_size, style.color_text_disabled);

    // draw popup
    changed := false;
    if ctx.open_popup_id == id {
        ctx.drawing_overlay = true;

        state_ptr := table_find_pointer(*ctx.window_states, id);
        if state_ptr == null {
            new_state: UI_Window_State;
            new_state.scroll_y = 0;
            new_state.content_h = cast(float32) items.count * style.button_height;
            new_state.open = true;
            table_add(*ctx.window_states, id, new_state);
            state_ptr = table_find_pointer(*ctx.window_states, id);
        }

        visible_count := min(cast(s32) items.count, 10);
        max_first_item := cast(s32) items.count - visible_count;
        if max_first_item < 0 max_first_item = 0;
        state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, cast(float32) max_first_item);

        if rect_contains(ctx.popup_rect, ctx.mouse.x, ctx.mouse.y) && ctx.mouse.scroll_y != 0 && !ctx.scroll_consumed {
            state_ptr.scroll_y -= ctx.mouse.scroll_y * 3.0;
            state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, cast(float32) max_first_item);
            ctx.scroll_consumed = true;
            ui_emit_audio(.SCROLL, id, clamp(abs(ctx.mouse.scroll_y) / 5.0, 0.0, 1.0));
        }

        ui_cmd_rect(ctx.popup_rect, style.color_window_bg);
        ui_cmd_rect_outline(ctx.popup_rect, style.color_border);

        first_item := cast(s32) floor(state_ptr.scroll_y + 0.5);
        if first_item < 0 first_item = 0;
        if first_item > max_first_item first_item = max_first_item;

        list_w := ctx.popup_rect.w;
        if items.count > cast(s64) visible_count {
            list_w -= style.scrollbar_width;
        }

        last_item := min(first_item + visible_count - 1, cast(s32) items.count - 1);
        for i : first_item..last_item {
            item_id := ui_hash_fnv1a(items[i], id);
            visible_i := i - first_item;
            item_rect: UI_Rect = .{
                ctx.popup_rect.x,
                ctx.popup_rect.y + cast(float32) visible_i * style.button_height,
                list_w,
                style.button_height
            };

            is_hovered := rect_contains(item_rect, ctx.mouse.x, ctx.mouse.y);
            if is_hovered {
                ctx.hot = item_id;
                if ctx.mouse.left_pressed {
                    ctx.active = item_id;
                }
            }

            if is_hovered && ctx.active == item_id && ctx.mouse.left_released {
                selected.* = cast(s32) i;
                ctx.open_popup_id = UI_ID_NONE;
                changed = true;
                ui_emit_audio(.DROPDOWN_SELECT, id);
            }

            item_bg := ifx is_hovered then style.color_bg_hover
                        else ifx cast(s32) i == selected.* then style.color_bg_active
                        else style.color_window_bg;
            ui_cmd_rect(item_rect, item_bg);

            item_text_x := item_rect.x + style.padding;
            item_text_y := ui_text_baseline_y(item_rect, style.font_size);
            ui_cmd_text(items[i], item_text_x, item_text_y, style.font_size, style.color_text);
        }

        if items.count > cast(s64) visible_count {
            track_rect: UI_Rect = .{
                ctx.popup_rect.x + ctx.popup_rect.w - style.scrollbar_width,
                ctx.popup_rect.y,
                style.scrollbar_width,
                ctx.popup_rect.h
            };
            ui_cmd_rect(track_rect, style.color_scrollbar_bg);

            visible_fraction := cast(float32) visible_count / cast(float32) items.count;
            grab_h := max(track_rect.h * visible_fraction, 20.0);
            travel := max(track_rect.h - grab_h, 1.0);
            scroll_fraction := ifx max_first_item > 0 then state_ptr.scroll_y / cast(float32) max_first_item else 0.0;
            grab_y := track_rect.y + scroll_fraction * travel;
            grab_rect: UI_Rect = .{track_rect.x, grab_y, track_rect.w, grab_h};
            scrollbar_id := ui_hash_fnv1a("#dropdown_scrollbar", id);

            if rect_contains(grab_rect, ctx.mouse.x, ctx.mouse.y) {
                ctx.hot = scrollbar_id;
                if ctx.mouse.left_pressed ctx.active = scrollbar_id;
            }

            if ui_is_active(scrollbar_id) && ctx.mouse.left_down {
                state_ptr.scroll_y += (ctx.mouse.dy / travel) * cast(float32) max_first_item;
                state_ptr.scroll_y = clamp(state_ptr.scroll_y, 0.0, cast(float32) max_first_item);
            }

            grab_color := ifx ui_is_active(scrollbar_id) then style.color_accent
                          else ifx ui_is_hot(scrollbar_id) then style.color_bg_hover
                          else style.color_scrollbar_grab;
            ui_cmd_rect(grab_rect, grab_color);
        }

        ctx.drawing_overlay = false;
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

ui_window_snap_rect_for_mouse :: (mouse_x: float32, mouse_y: float32) -> UI_Rect, bool {
    ctx := ui_ctx;

    hotspot: float32 = 48.0;
    area := ctx.work_area;
    w := area.w;
    h := area.h;

    near_left   := mouse_x <= area.x + hotspot;
    near_right  := mouse_x >= area.x + w - hotspot;
    near_top    := mouse_y <= area.y + hotspot;
    near_bottom := mouse_y >= area.y + h - hotspot;

    if near_left && near_top       return .{area.x, area.y, w * 0.5, h * 0.5}, true;
    if near_right && near_top      return .{area.x + w * 0.5, area.y, w * 0.5, h * 0.5}, true;
    if near_left && near_bottom    return .{area.x, area.y + h * 0.5, w * 0.5, h * 0.5}, true;
    if near_right && near_bottom   return .{area.x + w * 0.5, area.y + h * 0.5, w * 0.5, h * 0.5}, true;

    if near_left    return .{area.x, area.y, w * 0.5, h}, true;
    if near_right   return .{area.x + w * 0.5, area.y, w * 0.5, h}, true;
    if near_top     return .{area.x, area.y, w, h * 0.5}, true;
    if near_bottom  return .{area.x, area.y + h * 0.5, w, h * 0.5}, true;

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

ui_begin_scroll_region :: (label: string, height: float32) -> float32 {
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

    ui_push_id(label);
    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = rect.x + style.padding,
        cursor_y   = rect.y - state_ptr.scroll_y,
        origin_x   = rect.x + style.padding,
        origin_y   = rect.y - state_ptr.scroll_y,
        max_w      = rect.w - style.padding * 2 - style.scrollbar_width,
        max_h      = rect.h + state_ptr.content_h,
        visible_h  = rect.h,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });

    return state_ptr.scroll_y;
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
        state_ptr.content_h = content_h;

        // apply scroll  only if no inner region already consumed it
        if !ctx.scroll_consumed && ctx.mouse.scroll_y != 0 {
            if rect_contains(state_ptr.scroll_region_rect, ctx.mouse.x, ctx.mouse.y) {
                max_scroll := state_ptr.content_h - state_ptr.scroll_region_rect.h;
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

ui_window_title_id :: (title: string) -> UI_Id {
    return ui_hash_fnv1a("#title", ui_window_id(title));
}

ui_window_rect :: (title: string) -> UI_Rect, bool {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr == null return .{}, false;
    return state_ptr.rect, state_ptr.open;
}

ui_window_title_rect :: (title: string) -> UI_Rect, bool {
    rect, ok := ui_window_rect(title);
    if !ok return .{}, false;
    return .{rect.x, rect.y, rect.w, ui_ctx.style.window_title_height}, true;
}

ui_window_title_is_active :: (title: string) -> bool {
    return ui_ctx.active == ui_window_title_id(title);
}

ui_window_title_released_over :: (dragged_title: string, target_title: string) -> bool {
    if !ui_window_title_is_active(dragged_title) || !ui_ctx.mouse.left_released return false;
    target_rect, ok := ui_window_title_rect(target_title);
    if !ok return false;
    return rect_contains(target_rect, ui_ctx.mouse.x, ui_ctx.mouse.y);
}

ui_window_z_order :: (title: string) -> s32 {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr == null return -1;
    return state_ptr.z_order;
}

ui_window_force_front :: (title: string) {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr != null {
        state_ptr.z_order = ui_ctx.next_z_order;
        ui_ctx.next_z_order += 1;
    }
}

ui_window_set_rect :: (title: string, rect: UI_Rect) {
    id := ui_window_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr != null {
        state_ptr.rect = rect;
    }
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
    had_error: bool;
    size: s64;
    modification_time: Apollo_Time;
}

UI_File_Search_Mode :: enum s32 {
    FILENAME;
    CONTENTS;
}

UI_File_Create_Mode :: enum {
    NONE;
    FILE;
    DIRECTORY;
}

UI_File_Select_State :: struct {
    current_directory: string;
    entries: [..] UI_File_Select_Entry;

    selected_index: s32 = -1;
    selected_path: string;

    path_buffer: [256] u8;
    path_length: s32;

    initialized: bool;
    needs_refresh: bool;
    show_dotfiles: bool;
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

    create_mode: UI_File_Create_Mode;
    create_name_buffer: [256] u8;
    create_name_length: s32;
    had_error: bool;
    error_message: string;
}

ui_file_select_free_entries :: (state: *UI_File_Select_State) {
    for state.entries {
        free(it.name);
        free(it.full_path);
    }
    array_reset(*state.entries);
}

ui_file_select_free_search :: (state: *UI_File_Select_State) {
    for state.search_files    free(it);
    for state.search_results  free(it);
    array_reset(*state.search_files);
    array_reset(*state.search_results);
    if state.search_status.count  free(state.search_status);
    state.search_status = "";
    state.search_files_collected = 0;
    state.search_files_searched = 0;
    state.search_done = false;
    state.search_had_error = false;
}

ui_file_select_set_search_status :: (state: *UI_File_Select_State, message: string) {
    if state.search_status.count  free(state.search_status);
    state.search_status = copy_string(message);
}

ui_file_select_set_selected_path :: (state: *UI_File_Select_State, path: string) {
    if state.selected_path.count  free(state.selected_path);
    state.selected_path = copy_string(path);
}

ui_file_select_set_error :: (state: *UI_File_Select_State, message: string) {
    if state.error_message.count  free(state.error_message);
    state.error_message = copy_string(message);
    state.had_error = message.count > 0;
}

ui_file_select_clear_error :: (state: *UI_File_Select_State) {
    ui_file_select_set_error(state, "");
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
    if directory[directory.count - 1] == #char "/" || directory[directory.count - 1] == #char "\\" {
        return tprint("%%", directory, name);
    }
    return tprint("%/%", directory, name);
}

ui_file_select_format_size :: (entry: *UI_File_Select_Entry) -> string {
    if entry.is_directory return "<dir>";
    if entry.had_error || entry.size < 0 return "";

    bytes := cast(u64) entry.size;
    base := cast(u64) 1024;
    unit_index := 0;
    divisor: u64 = 1;
    remaining := bytes;

    while remaining >= base && unit_index < 4 {
        remaining /= base;
        divisor *= base;
        unit_index += 1;
    }

    suffix := ifx unit_index == 0 then "B" else ifx unit_index == 1 then "KiB" else ifx unit_index == 2 then "MiB" else ifx unit_index == 3 then "GiB" else "TiB";
    if unit_index == 0 return tprint("% %", bytes, suffix);

    whole := bytes / divisor;
    remainder := bytes % divisor;
    tenth := (remainder * 10 + divisor / 2) / divisor;
    if tenth == 10 {
        whole += 1;
        tenth = 0;
    }

    if tenth == 0 return tprint("% %", whole, suffix);
    return tprint("% %", tprint("%.%", whole, tenth), suffix);
}

ui_file_select_format_modified :: (entry: *UI_File_Select_Entry) -> string {
    if entry.had_error return "";

    cal := to_calendar(entry.modification_time, .LOCAL);
    return tprint("%-%-% %:%",
        formatInt(cal.year, minimum_digits = 4),
        formatInt(cal.month_starting_at_0 + 1, minimum_digits = 2),
        formatInt(cal.day_of_month_starting_at_0 + 1, minimum_digits = 2),
        formatInt(cal.hour, minimum_digits = 2),
        formatInt(cal.minute, minimum_digits = 2)
    );
}

ui_file_select_draw_cell :: (rect: UI_Rect, text: string, color: Vector4, align_right := false) {
    if rect.w <= 0 || rect.h <= 0 || text.count == 0 return;

    style := *ui_ctx.style;
    pad := style.padding * 0.65;
    text_x := rect.x + pad;
    if align_right {
        text_w := msdf_measure_text_pixels(ui_ctx.font, text, style.font_size);
        text_x = rect.x + rect.w - text_w - pad;
    }
    text_y := ui_text_baseline_y(rect, style.font_size);

    ui_cmd_scissor_push(rect);
    ui_cmd_text(text, text_x, text_y, style.font_size, color);
    ui_cmd_scissor_pop();
}

ui_file_select_column_rects :: (table_rect: UI_Rect, name_w: float32, size_w: float32) -> (UI_Rect, UI_Rect, UI_Rect) {
    name_rect := UI_Rect.{table_rect.x, table_rect.y, name_w, table_rect.h};
    size_rect := UI_Rect.{name_rect.x + name_rect.w, table_rect.y, size_w, table_rect.h};
    modified_rect := UI_Rect.{size_rect.x + size_rect.w, table_rect.y, table_rect.w - name_w - size_w, table_rect.h};
    return name_rect, size_rect, modified_rect;
}

ui_file_select_table_inner_rect :: (rect: UI_Rect) -> UI_Rect {
    style := *ui_ctx.style;
    return .{
        rect.x + style.padding,
        rect.y,
        max(0.0, rect.w - style.padding * 2 - style.scrollbar_width),
        rect.h
    };
}

ui_file_select_clamp_columns :: (state: *UI_File_Select_State, available_w: float32) {
    min_name: float32 = 120.0;
    min_size: float32 = 76.0;
    min_modified: float32 = 128.0;

    if state.name_column_width <= 0  state.name_column_width = max(min_name, available_w * 0.52);
    if state.size_column_width <= 0  state.size_column_width = 92.0;

    state.name_column_width = clamp(state.name_column_width, min_name, max(min_name, available_w - min_size - min_modified));
    state.size_column_width = clamp(state.size_column_width, min_size, max(min_size, available_w - state.name_column_width - min_modified));

    if state.name_column_width + state.size_column_width + min_modified > available_w {
        state.name_column_width = max(min_name, available_w - state.size_column_width - min_modified);
    }
}

ui_file_select_column_resizer :: (id_label: string, x: float32, y: float32, h: float32, delta: *float32) {
    id := ui_get_id(id_label);
    rect := UI_Rect.{x - 4, y, 8, h};
    ui_try_hot(id, rect);
    ui_try_active(id);

    if ui_is_active(id) && ui_ctx.mouse.left_down {
        delta.* += ui_ctx.mouse.dx;
    }

    color := ifx ui_is_active(id) then ui_ctx.style.color_accent else ifx ui_is_hot(id) then ui_ctx.style.color_text_disabled else ui_ctx.style.color_separator;
    ui_cmd_rect(.{x - 1, y + 3, 2, h - 6}, color);
}

ui_file_select_footer_button :: (label: string, rect: UI_Rect) -> bool {
    style := *ui_ctx.style;
    id := ui_get_id(label);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked  ui_emit_audio(.BUTTON_CLICK, id);

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

ui_file_select_string_contains :: (haystack: string, needle: string) -> bool {
    if needle.count == 0 return true;
    if haystack.count < needle.count return false;

    last := haystack.count - needle.count;
    for start: 0..last {
        matched := true;
        for i: 0..needle.count - 1 {
            if haystack[start + i] != needle[i] {
                matched = false;
                break;
            }
        }
        if matched return true;
    }

    return false;
}

ui_file_select_search_collect_files :: (state: *UI_File_Select_State) -> bool {
    visitor :: (info: *File_Visit_Info, state: *UI_File_Select_State) {
        if info.is_directory {
            if !state.show_dotfiles && info.short_name.count > 0 && info.short_name[0] == #char "." {
                info.descend_into_directory = false;
            }
            return;
        }

        if !state.show_dotfiles && info.short_name.count > 0 && info.short_name[0] == #char "." return;

        path := copy_string(info.full_name);
        normalize_slashes(path);
        ui_file_select_collapse_drive_root_slashes(*path);
        array_add(*state.search_files, path);
    }

    return visit_files(state.current_directory, true, state, visitor, visit_files = true, visit_directories = true, follow_directory_symlinks = false);
}

ui_file_select_run_search :: (state: *UI_File_Select_State) {
    query: string;
    query.data = state.search_query_buffer.data;
    query.count = state.search_query_length;

    ui_file_select_free_search(state);

    if query.count == 0 {
        ui_file_select_set_search_status(state, "Enter a search query.");
        state.search_done = true;
        return;
    }

    collect_ok := ui_file_select_search_collect_files(state);
    state.search_files_collected = cast(s32) state.search_files.count;

    if !collect_ok {
        state.search_had_error = true;
        ui_file_select_set_search_status(state, "Could not recursively search this directory.");
        state.search_done = true;
        return;
    }

    for path: state.search_files {
        state.search_files_searched += 1;

        matches := false;
        if state.search_mode == xx UI_File_Search_Mode.FILENAME {
            matches = ui_file_select_string_contains(path, query);
        } else {
            contents, ok := read_entire_file(path, log_errors = false);
            if ok {
                matches = ui_file_select_string_contains(contents, query);
                free(contents);
            }
        }

        if matches {
            array_add(*state.search_results, copy_string(path));
        }
    }

    state.search_done = true;
    ui_file_select_set_search_status(state, tprint("Found % match(es) in % file(s).", state.search_results.count, state.search_files.count));
}

ui_file_select_draw_search_panel :: (state: *UI_File_Select_State) {
    if !ui_collapsing_header("Search", false) return;

    ui_text_input("Find", *state.search_query_buffer, *state.search_query_length);

    ui_begin_row();
    ui_radio("Filename", *state.search_mode, xx UI_File_Search_Mode.FILENAME);
    ui_radio("Contents", *state.search_mode, xx UI_File_Search_Mode.CONTENTS);
    ui_end_row();

    ui_begin_row();
    if ui_button("Search") {
        ui_file_select_run_search(state);
    }
    if ui_button("Clear Search") {
        state.search_query_length = 0;
        state.search_query_buffer[0] = 0;
        ui_file_select_free_search(state);
    }
    ui_end_row();

    progress := 0.0;
    if state.search_files_collected > 0 {
        progress = cast(float32) state.search_files_searched / cast(float32) state.search_files_collected;
    } else if state.search_done {
        progress = 1.0;
    }
    progress_label := ifx state.search_done then state.search_status else tprint("% / % files", state.search_files_searched, state.search_files_collected);
    ui_progress_bar(progress, progress_label);

    if state.search_results.count > 0 {
        result_h := min(120.0, cast(float32) state.search_results.count * (ui_ctx.style.font_size + ui_ctx.style.padding));
        layout := ui_current_layout();
        result_outer_rect := UI_Rect.{layout.cursor_x + layout.indent, layout.cursor_y, layout.max_w - layout.indent, result_h};

        ui_begin_scroll_region("search_results", result_h);
        for i: 0..state.search_results.count - 1 {
            path := state.search_results[i];

            row_h := ui_ctx.style.font_size + ui_ctx.style.padding;
            row_rect := ui_allocate_rect(0, row_h);
            row_is_visible := row_rect.y + row_rect.h >= result_outer_rect.y &&
                              row_rect.y <= result_outer_rect.y + result_outer_rect.h;
            if !row_is_visible continue;

            row_id := ui_get_id(path);
            ui_try_hot(row_id, row_rect);
            ui_try_active(row_id);

            selected := path == state.selected_path;
            bg: Vector4;
            if selected                  bg = ui_ctx.style.color_accent;
            else if ui_is_active(row_id) bg = ui_ctx.style.color_bg_active;
            else if ui_is_hot(row_id)    bg = ui_ctx.style.color_bg_hover;
            else                         bg = .{0, 0, 0, 0};
            if bg.w > 0  ui_cmd_rect(row_rect, bg);

            ui_file_select_draw_cell(row_rect, path, ui_ctx.style.color_text);

            if ui_was_clicked(row_id) {
                ui_file_select_set_selected_path(state, path);
                state.selected_index = -1;
                ui_emit_audio(.BUTTON_CLICK, row_id);
            }
        }
        ui_end_scroll_region();
    }
}

ui_file_select_name_is_valid :: (name: string) -> bool {
    if name.count == 0 return false;
    if name == "." || name == ".." return false;

    for i: 0..name.count-1 {
        if name[i] == #char "/" || name[i] == #char "\\" return false;
    }

    return true;
}

ui_file_select_begin_create :: (state: *UI_File_Select_State, mode: UI_File_Create_Mode) {
    state.create_mode = mode;
    state.create_name_length = 0;
    state.create_name_buffer[0] = 0;

    title := ifx mode == .DIRECTORY then "New Directory" else "New File";
    ui_set_window_open(title, true);
}

ui_file_select_finish_create :: (state: *UI_File_Select_State) -> bool {
    name: string;
    name.data = state.create_name_buffer.data;
    name.count = state.create_name_length;

    if !ui_file_select_name_is_valid(name) {
        ui_file_select_set_error(state, "Use a simple name without slashes.");
        return false;
    }

    new_path := ui_file_select_join_path(state.current_directory, name);

    ok := false;
    if state.create_mode == .DIRECTORY {
        ok = make_directory_if_it_does_not_exist(new_path, recursive = false);
    } else if state.create_mode == .FILE {
        if file_exists(new_path) {
            ui_file_select_set_error(state, tprint("Already exists: %", new_path));
            return false;
        }
        ok = write_entire_file(new_path, "");
    }

    if !ok {
        ui_file_select_set_error(state, tprint("Could not create: %", new_path));
        return false;
    }

    ui_file_select_clear_error(state);
    state.needs_refresh = true;

    if state.create_mode == .FILE {
        ui_file_select_set_selected_path(state, new_path);
    }

    state.create_mode = .NONE;
    return true;
}

ui_file_select_create_dialog :: (state: *UI_File_Select_State) {
    if state.create_mode == .NONE return;

    title := ifx state.create_mode == .DIRECTORY then "New Directory" else "New File";
    if ui_begin_window(title, 460, 140, 340, 150) {
        ui_text_input("Name", *state.create_name_buffer, *state.create_name_length);

        ui_begin_row();
        if ui_button("OK") {
            if ui_file_select_finish_create(state) {
                ui_set_window_open(title, false);
            }
        }
        ui_end_row();

        ui_end_window();
    } else if !ui_is_window_open(title) {
        state.create_mode = .NONE;
    }
}

ui_file_select_refresh :: (state: *UI_File_Select_State) {
    ui_file_select_free_entries(state);
    ui_file_select_clear_error(state);
    state.selected_index = -1;
    state.needs_refresh = false;

    visitor :: (info: *File_Visit_Info, state: *UI_File_Select_State) {
        if !state.show_dotfiles && info.short_name.count > 0 && info.short_name[0] == #char "." return;

        entry: UI_File_Select_Entry;
        entry.name = copy_string(info.short_name);
        entry.full_path = copy_string(info.full_name);
        normalize_slashes(entry.full_path);
        ui_file_select_collapse_drive_root_slashes(*entry.full_path);
        entry.is_directory = info.is_directory;
        entry.had_error = info.had_error;
        entry.size = info.size;
        entry.modification_time = info.modification_time;
        if !add_modtime_and_size_if_missing(info) {
            entry.had_error = true;
        } else {
            entry.size = info.size;
            entry.modification_time = info.modification_time;
        }

        array_add(*state.entries, entry);
        if entry.is_directory {
            index := state.entries.count - 1;
            while index > 0 && state.entries[index - 1].is_directory == false {
                state.entries[index] = state.entries[index - 1];
                index -= 1;
            }
            state.entries[index] = entry;
        }
    }

    ok := visit_files(state.current_directory, false, state, visitor, visit_files = true, visit_directories = true, follow_directory_symlinks = false);
    if !ok {
        ui_file_select_set_error(state, tprint("Could not open directory: %", state.current_directory));
    }
}

ui_file_select :: (label: string, state: *UI_File_Select_State, start_directory: string = "") -> bool {
    if !state.initialized {
        initial_directory := start_directory;
        if initial_directory.count == 0 {
            initial_directory = get_working_directory();
        }

        state.current_directory = copy_string(initial_directory);
        state.initialized = true;
        state.needs_refresh = true;
        ui_file_select_sync_path_buffer(state);
    }

    if state.needs_refresh {
        ui_file_select_refresh(state);
    }

    ui_push_id(label);
    defer ui_pop_id();

    ui_label(label);
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

    ui_begin_row();
    if ui_button("New File") {
        ui_file_select_begin_create(state, .FILE);
    }
    if ui_button("New Directory") {
        ui_file_select_begin_create(state, .DIRECTORY);
    }
    ui_end_row();

    ui_file_select_draw_search_panel(state);

    if state.had_error {
        ui_label_colored(state.error_message, .{1.0, 0.35, 0.25, 1.0});
    }

    ui_label(tprint("Current: %", state.current_directory));

    style := *ui_ctx.style;
    header_h := style.font_size + style.padding * 1.2;
    header_rect := ui_allocate_rect(0, header_h);
    header_table_rect := ui_file_select_table_inner_rect(header_rect);
    ui_file_select_clamp_columns(state, header_table_rect.w);

    name_header, size_header, modified_header := ui_file_select_column_rects(header_table_rect, state.name_column_width, state.size_column_width);

    ui_cmd_rect(header_rect, .{0.105, 0.112, 0.124, 1.0});
    ui_cmd_rect(.{header_rect.x, header_rect.y + header_rect.h - 1, header_rect.w, 1}, style.color_border);
    ui_file_select_draw_cell(name_header, "Name", style.color_text_disabled);
    ui_file_select_draw_cell(size_header, "Size", style.color_text_disabled);
    ui_file_select_draw_cell(modified_header, "Modified", style.color_text_disabled);

    ui_file_select_column_resizer("name_size_separator", name_header.x + name_header.w, header_rect.y, header_rect.h, *state.name_column_width);
    ui_file_select_column_resizer("size_modified_separator", size_header.x + size_header.w, header_rect.y, header_rect.h, *state.size_column_width);
    ui_file_select_clamp_columns(state, header_table_rect.w);

    selected_h := style.font_size + style.padding;
    footer_h := selected_h + style.button_height + style.item_spacing + style.padding * 2;

    layout := ui_current_layout();
    visible_bottom := layout.origin_y + layout.visible_h;
    footer_top := visible_bottom - footer_h;
    if footer_top < layout.cursor_y  footer_top = layout.cursor_y;

    scroll_h := footer_top - layout.cursor_y;
    scroll_h = clamp(scroll_h, 0.0, 260.0);

    scroll_outer_rect := UI_Rect.{layout.cursor_x + layout.indent, layout.cursor_y, layout.max_w - layout.indent, scroll_h};
    scroll_table_rect := ui_file_select_table_inner_rect(scroll_outer_rect);

    ui_begin_scroll_region("file_select_entries", scroll_h);
    for i : 0..state.entries.count-1 {
        entry := *state.entries[i];
        row_h := style.font_size + style.padding * 1.15;
        row_rect := ui_allocate_rect(0, row_h);
        row_rect.x = scroll_table_rect.x;
        row_rect.w = scroll_table_rect.w;

        row_is_visible := row_rect.y + row_rect.h >= scroll_outer_rect.y &&
                          row_rect.y <= scroll_outer_rect.y + scroll_outer_rect.h;
        if !row_is_visible continue;

        row_id := ui_get_id(entry.full_path);
        ui_try_hot(row_id, row_rect);
        ui_try_active(row_id);

        is_selected := state.selected_index == cast(s32) i;
        if ui_was_clicked(row_id) {
            if entry.is_directory {
                ui_file_select_set_directory(state, entry.full_path);
            } else {
                state.selected_index = cast(s32) i;
                ui_file_select_set_selected_path(state, entry.full_path);
            }
        }

        bg: Vector4;
        if is_selected       bg = .{0.22, 0.36, 0.54, 0.88};
        else if ui_is_hot(row_id) bg = .{0.20, 0.22, 0.25, 1.0};
        else if i % 2 == 0   bg = .{0.145, 0.150, 0.162, 1.0};
        else                 bg = .{0.118, 0.123, 0.135, 1.0};
        ui_cmd_rect(row_rect, bg);

        row_table_rect := UI_Rect.{row_rect.x, row_rect.y, scroll_table_rect.w, row_rect.h};
        name_rect, size_rect, modified_rect := ui_file_select_column_rects(row_table_rect, state.name_column_width, state.size_column_width);

        ui_cmd_rect(.{size_rect.x, row_rect.y, 1, row_rect.h}, .{0.22, 0.23, 0.25, 0.65});
        ui_cmd_rect(.{modified_rect.x, row_rect.y, 1, row_rect.h}, .{0.22, 0.23, 0.25, 0.65});

        name_text := ifx entry.is_directory then tprint("%/", entry.name) else entry.name;
        name_color := ifx entry.is_directory then .{0.64, 0.78, 1.00, 1.0} else style.color_text;
        ui_file_select_draw_cell(name_rect, name_text, name_color);
        ui_file_select_draw_cell(size_rect, ui_file_select_format_size(entry), style.color_text_disabled);
        ui_file_select_draw_cell(modified_rect, ui_file_select_format_modified(entry), style.color_text_disabled);
    }
    ui_end_scroll_region();

    footer_top = max(visible_bottom - footer_h, layout.origin_y);
    footer_x := layout.origin_x + layout.indent;
    footer_w := layout.max_w - layout.indent;
    selected_rect := UI_Rect.{footer_x, footer_top + style.padding, footer_w, selected_h};

    if state.selected_path.count > 0 {
        ui_file_select_draw_cell(selected_rect, tprint("Selected: %", state.selected_path), style.color_text);
    } else {
        ui_file_select_draw_cell(selected_rect, "Selected: <none>", style.color_text_disabled);
    }

    button_y := selected_rect.y + selected_rect.h + style.item_spacing;
    open_w := msdf_measure_text_pixels(ui_ctx.font, "Open", style.font_size) + style.padding * 2;
    clear_w := msdf_measure_text_pixels(ui_ctx.font, "Clear", style.font_size) + style.padding * 2;
    open_rect := UI_Rect.{footer_x, button_y, open_w, style.button_height};
    clear_rect := UI_Rect.{open_rect.x + open_rect.w + style.item_spacing, button_y, clear_w, style.button_height};

    if ui_file_select_footer_button("Open", open_rect) {
        if state.selected_path.count > 0 {
            changed = true;
        }
    }
    if ui_file_select_footer_button("Clear", clear_rect) {
        state.selected_index = -1;
        ui_file_select_set_selected_path(state, "");
    }

    footer_bottom := button_y + style.button_height;
    if footer_bottom > layout.content_max_y  layout.content_max_y = footer_bottom;

    return changed;
}

ui_file_select_destroy :: (state: *UI_File_Select_State) {
    ui_file_select_free_entries(state);
    ui_file_select_free_search(state);
    if state.current_directory.count  free(state.current_directory);
    if state.selected_path.count      free(state.selected_path);
    if state.error_message.count      free(state.error_message);
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
