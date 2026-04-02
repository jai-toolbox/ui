

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

ui_separator :: () {
    style := *ui_ctx.style;
    rect := ui_allocate_rect(0, style.border_width + style.item_spacing * 2);
    line_rect: UI_Rect = .{rect.x, rect.y + rect.h * 0.5, rect.w, style.border_width};
    ui_cmd_rect(line_rect, style.color_separator);
}

ui_separator_text :: (text: string) {
    ctx := ui_ctx;
    style := *ctx.style;
    h := style.font_size + style.padding;
    rect := ui_allocate_rect(0, h);

    text_w := msdf_measure_text(ctx.font, text, style.font_size);
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

    text_w := msdf_measure_text(ctx.font, label, style.font_size);
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

ui_button_colored :: (label: string, normal: Vector4, hover: Vector4, active: Vector4) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    text_w := msdf_measure_text(ctx.font, label, style.font_size);
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
    text_w := msdf_measure_text(ctx.font, label, style.font_size);
    total_w := box_size + style.padding + text_w;
    h := max(box_size, style.font_size) + style.padding;
    rect := ui_allocate_rect(total_w, h);

    box_rect: UI_Rect = .{rect.x, rect.y + (h - box_size) * 0.5, box_size, box_size};

    ui_try_hot(id, rect);
    ui_try_active(id);
    toggled := ui_was_clicked(id);
    if toggled {
        value.* = !<<value;
        ui_emit_audio(.CHECKBOX_TOGGLE, id);
    }

    bg := ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(box_rect, bg);
    ui_cmd_rect_outline(box_rect, style.color_border);

    if <<value {
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
    text_w := msdf_measure_text(ctx.font, label, style.font_size);
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

    if <<value == option {
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

    value_text := tprint("% : %", label, <<value);
    text_y := rect.y + style.font_size * ctx.font.ascender;
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
        if new_value != <<value {
            old_value := <<value;
            <<value = new_value;
            changed = true;
            delta := abs(new_value - old_value) / (max_val - min_val);
            ui_emit_audio(.SLIDER_CHANGE, id, clamp(delta * 5.0, 0.0, 1.0));
        }
    }

    if ui_is_active(id) && ctx.mouse.left_released  ui_emit_audio(.SLIDER_RELEASE, id);

    ui_cmd_rect(track_rect, style.color_slider_track);
    ui_cmd_rect_outline(track_rect, style.color_border);

    t := clamp((<<value - min_val) / (max_val - min_val), 0.0, 1.0);
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

    value_text := tprint("% : %", label, <<value);
    text_y := rect.y + style.font_size * ctx.font.ascender;
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
        if new_value != <<value {
            old_value := <<value;
            <<value = new_value;
            changed = true;
            range := cast(float32)(max_val - min_val);
            delta := abs(cast(float32)(new_value - old_value)) / range;
            ui_emit_audio(.SLIDER_CHANGE, id, clamp(delta * 5.0, 0.0, 1.0));
        }
    }

    if ui_is_active(id) && ctx.mouse.left_released  ui_emit_audio(.SLIDER_RELEASE, id);

    ui_cmd_rect(track_rect, style.color_slider_track);
    ui_cmd_rect_outline(track_rect, style.color_border);

    t := clamp((cast(float32)(<<value - min_val)) / cast(float32)(max_val - min_val), 0.0, 1.0);
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


ui_text_input :: (label: string, buffer: *[256] u8, length: *s32) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    label_w := msdf_measure_text(ctx.font, label, style.font_size);
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
    current_text.count = <<length;

    text_x := input_rect.x + style.padding * 0.5;
    text_y := ui_text_baseline_y(input_rect, style.font_size);

    ui_cmd_scissor_push(input_rect);
    ui_cmd_text(current_text, text_x, text_y, style.font_size, style.color_text);

    if focused {
        cursor_x := text_x + msdf_measure_text(ctx.font, current_text, style.font_size);
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
                if <<length < 255 {
                    (<<buffer)[<<length] = c;
                    <<length += 1;
                    changed = true;
                    ui_emit_audio(.TEXT_INPUT_CHAR, id, 0.8);
                }
            }
        }

        for i : 0..ctx.keyboard.key_count-1 {
            key := ctx.keyboard.keys_pressed[i];
            if key == .BACKSPACE {
                if <<length > 0 {
                    <<length -= 1;
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
    label_w := msdf_measure_text(ctx.font, label, style.font_size);
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
        popup_h := item_count * style.button_height;
        ctx.popup_rect = .{combo_rect.x, combo_rect.y + combo_rect.h, combo_rect.w, popup_h};
    }

    // draw combo box
    bg := ifx ui_is_hot(id) then style.color_bg_hover else style.color_bg;
    ui_cmd_rect(combo_rect, bg);
    ui_cmd_rect_outline(combo_rect, style.color_border);

    // current selection text
    current_text := ifx <<selected >= 0 && <<selected < cast(s32) items.count
                    then items[<<selected]
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

        ui_cmd_rect(ctx.popup_rect, style.color_window_bg);
        ui_cmd_rect_outline(ctx.popup_rect, style.color_border);

        for i : 0..items.count-1 {
            item_id := ui_hash_fnv1a(items[i], id);
            item_rect: UI_Rect = .{
                ctx.popup_rect.x,
                ctx.popup_rect.y + cast(float32) i * style.button_height,
                ctx.popup_rect.w,
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
                <<selected = cast(s32) i;
                ctx.open_popup_id = UI_ID_NONE;
                changed = true;
                ui_emit_audio(.DROPDOWN_SELECT, id);
            }

            item_bg := ifx is_hovered then style.color_bg_hover
                        else ifx cast(s32) i == <<selected then style.color_bg_active
                        else style.color_window_bg;
            ui_cmd_rect(item_rect, item_bg);

            item_text_x := item_rect.x + style.padding;
            item_text_y := ui_text_baseline_y(item_rect, style.font_size);
            ui_cmd_text(items[i], item_text_x, item_text_y, style.font_size, style.color_text);
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

    text_w := msdf_measure_text(ctx.font, text, style.font_size);
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
    text_w := msdf_measure_text(ctx.font, label, style.font_size);
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

    ui_color_display("Preview", <<color);

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

ui_begin_window :: (title: string, default_x: float32 = 50, default_y: float32 = 50, default_w: float32 = 300, default_h: float32 = 400) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(title);

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
        text_w := msdf_measure_text(ctx.font, tab_names[i], style.font_size);
        w := text_w + style.padding * 2;
        h := style.button_height;

        rect := ui_allocate_rect(w, h);

        ui_try_hot(tab_id, rect);
        ui_try_active(tab_id);
        if ui_was_clicked(tab_id) {
            <<selected = cast(s32) i;
            ui_emit_audio(.TAB_SELECT, tab_id);
        }

        is_selected := <<selected == cast(s32) i;

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

    return <<selected;
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
    ui_label(tprint("Draw cmds: %", ctx.draw_commands.count));
    ui_label(tprint("Layout depth: %", ctx.layout_depth));
    ui_label(tprint("FPS: %", ifx ctx.dt > 0 then cast(s32)(1.0 / ctx.dt) else 0));
}

// open/close window programmatically

ui_set_window_open :: (title: string, open: bool) {
    id := ui_get_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr != null {
        state_ptr.open = open;
    }
}

ui_is_window_open :: (title: string) -> bool {
    id := ui_get_id(title);
    state_ptr := table_find_pointer(*ui_ctx.window_states, id);
    if state_ptr != null return state_ptr.open;
    return true;
}


ui_drag_float :: (label: string, value: *float32, speed: float32 = 0.1, min_val: float32 = -1000000, max_val: float32 = 1000000) -> bool {
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label);

    h := style.input_height;
    rect := ui_allocate_rect(0, h);

    label_w := msdf_measure_text(ctx.font, label, style.font_size);
    label_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, rect.x, label_y, style.font_size, style.color_text);

    drag_x := rect.x + label_w + style.padding;
    drag_w := rect.w - label_w - style.padding;
    drag_rect: UI_Rect = .{drag_x, rect.y, drag_w, h};

    ui_try_hot(id, drag_rect);
    if ui_try_active(id)  ui_emit_audio(.SLIDER_GRAB, id);

    changed := false;
    if ui_is_active(id) && ctx.mouse.left_down {
        raw := <<value + ctx.mouse.dx * speed;
        raw = clamp(raw, min_val, max_val);
        new_value := floor(raw * 100.0 + 0.5) / 100.0;
        if new_value != <<value {
            old_value := <<value;
            <<value = new_value;
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

    value_text := tprint("%.2", <<value);
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

    label_w := msdf_measure_text(ctx.font, label, style.font_size);
    label_y := ui_text_baseline_y(rect, style.font_size);
    ui_cmd_text(label, rect.x, label_y, style.font_size, style.color_text);

    drag_x := rect.x + label_w + style.padding;
    drag_w := rect.w - label_w - style.padding;
    drag_rect: UI_Rect = .{drag_x, rect.y, drag_w, h};

    ui_try_hot(id, drag_rect);
    if ui_try_active(id)  ui_emit_audio(.SLIDER_GRAB, id);

    changed := false;
    if ui_is_active(id) && ctx.mouse.left_down {
        f := cast(float32) <<value + ctx.mouse.dx * speed;
        f = clamp(f, cast(float32) min_val, cast(float32) max_val);
        new_value := cast(s32) (f + ifx f >= 0 then 0.5 else -0.5);
        if new_value != <<value {
            old_value := <<value;
            <<value = new_value;
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

    value_text := tprint("%", <<value);
    value_x := drag_rect.x + style.padding * 0.5;
    value_y := ui_text_baseline_y(drag_rect, style.font_size);
    ui_cmd_text(value_text, value_x, value_y, style.font_size, style.color_text);

    return changed;
}

ui_toggle :: (label_on: string, label_off: string, value: *bool) -> bool {
    label := ifx <<value then label_on else label_off;
    ctx := ui_ctx;
    style := *ctx.style;
    id := ui_get_id(label_on);

    text_w := msdf_measure_text(ctx.font, label, style.font_size);
    w := text_w + style.padding * 2;
    h := style.button_height;
    rect := ui_allocate_rect(w, h);

    ui_try_hot(id, rect);
    ui_try_active(id);
    clicked := ui_was_clicked(id);
    if clicked {
        value.* = !<<value;
        ui_emit_audio(.CHECKBOX_TOGGLE, id);
    }

    bg: Vector4;
    if <<value {
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
        is_selected := cast(s32) i == <<selected;
        if ui_selectable(items[i], is_selected) {
            <<selected = cast(s32) i;
            changed = true;
        }
    }

    ui_end_scroll_region();

    return changed;
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
