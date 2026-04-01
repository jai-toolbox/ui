#import "Basic";
#import "Math";
#import "Hash_Table";
#import "GL";

#load "msdf.jai";

// identity

UI_Id :: u64;
UI_ID_NONE : UI_Id : 0;

// https://www.rfc-editor.org/rfc/rfc9923
// a hash function that we use to turn a string into a ui id
ui_hash_fnv1a :: (data: string, seed: UI_Id = 14695981039346656037) -> UI_Id {
    hash := seed;
    for i : 0..data.count-1 {
        hash ^= cast(UI_Id) data[i];
        hash *= 1099511628211;
    }
    return hash;
}

// rect

UI_Rect :: struct {
    x, y, w, h: float32;
}

rect_contains :: (r: UI_Rect, px: float32, py: float32) -> bool {
    return px >= r.x && px <= r.x + r.w &&
           py >= r.y && py <= r.y + r.h;
}

rect_intersect :: (a: UI_Rect, b: UI_Rect) -> UI_Rect {
    x0 := max(a.x, b.x);
    y0 := max(a.y, b.y);
    x1 := min(a.x + a.w, b.x + b.w);
    y1 := min(a.y + a.h, b.y + b.h);
    if x1 <= x0 || y1 <= y0 return .{0, 0, 0, 0};
    return .{x0, y0, x1 - x0, y1 - y0};
}

rect_expand :: (r: UI_Rect, amount: float32) -> UI_Rect {
    return .{r.x - amount, r.y - amount, r.w + amount * 2, r.h + amount * 2};
}

rect_shrink :: (r: UI_Rect, amount: float32) -> UI_Rect {
    return .{r.x + amount, r.y + amount, r.w - amount * 2, r.h - amount * 2};
}

// mouse state

UI_Mouse_State :: struct {
    x, y:          float32;
    dx, dy:        float32;
    left_down:     bool;
    left_pressed:  bool;
    left_released: bool;
    right_down:    bool;
    right_pressed: bool;
    right_released: bool;
    scroll_y:      float32;
}

// keyboard state

UI_Key :: enum {
    NONE;
    BACKSPACE;
    DELETE;
    LEFT;
    RIGHT;
    HOME;
    END;
    ENTER;
    ESCAPE;
    TAB;

    // used for text editing ctrl-(a/c/v/x/z)
    // all, copy, paste, cut undo
    A; C; V; X; Z;
}

UI_Keyboard_State :: struct {
    keys_pressed:  [32] UI_Key;
    key_count:     s32;
    chars_entered: [64] u8;
    char_count:    s32;
    ctrl_held:     bool;
    shift_held:    bool;
}

// draw commands

UI_Draw_Cmd_Type :: enum {
    GEOMETRY;
    TEXT;
    SCISSOR_PUSH;
    SCISSOR_POP;
}

UI_Draw_Cmd :: struct {
    type: UI_Draw_Cmd_Type;

    // GEOMETRY
    indices:     [] u32;
    positions:   [] Vector3;
    rgba_colors: [] Vector4;

    // TEXT
    text:      string;
    text_x:    float32;
    text_y:    float32;
    font_size: float32;
    color:     Vector4;

    // SCISSOR
    scissor_rect: UI_Rect;
}

// style

UI_Style :: struct {
    color_bg:              Vector4;
    color_bg_hover:        Vector4;
    color_bg_active:       Vector4;
    color_border:          Vector4;
    color_text:            Vector4;
    color_text_disabled:   Vector4;
    color_accent:          Vector4;
    color_accent_hover:    Vector4;
    color_accent_active:   Vector4;
    color_slider_track:    Vector4;
    color_slider_grab:     Vector4;
    color_window_bg:       Vector4;
    color_window_title_bg: Vector4;
    color_panel_bg:        Vector4;
    color_separator:       Vector4;
    color_input_bg:        Vector4;
    color_input_cursor:    Vector4;
    color_selection:       Vector4;
    color_scrollbar_bg:    Vector4;
    color_scrollbar_grab:  Vector4;
    color_tooltip_bg:      Vector4;
    color_tree_line:       Vector4;

    font_size:        float32;
    font_size_title:  float32;
    padding:          float32;
    item_spacing:     float32;
    border_width:     float32;
    indent_width:     float32;
    scrollbar_width:  float32;

    button_height:    float32;
    checkbox_size:    float32;
    slider_height:    float32;
    input_height:     float32;
    window_title_height: float32;
    tree_indent:      float32;
    tooltip_delay:    float32;
}

ui_default_style :: () -> UI_Style {
    s: UI_Style;

    s.color_bg              = .{0.20, 0.20, 0.22, 1.0};
    s.color_bg_hover        = .{0.28, 0.28, 0.30, 1.0};
    s.color_bg_active       = .{0.35, 0.35, 0.38, 1.0};
    s.color_border          = .{0.45, 0.45, 0.48, 1.0};
    s.color_text            = .{0.95, 0.95, 0.95, 1.0};
    s.color_text_disabled   = .{0.50, 0.50, 0.50, 1.0};
    s.color_accent          = .{0.26, 0.59, 0.98, 1.0};
    s.color_accent_hover    = .{0.33, 0.66, 1.00, 1.0};
    s.color_accent_active   = .{0.20, 0.50, 0.85, 1.0};
    s.color_slider_track    = .{0.15, 0.15, 0.17, 1.0};
    s.color_slider_grab     = .{0.40, 0.70, 1.00, 1.0};
    s.color_window_bg       = .{0.15, 0.15, 0.17, 0.95};
    s.color_window_title_bg = .{0.10, 0.10, 0.12, 1.0};
    s.color_panel_bg        = .{0.18, 0.18, 0.20, 1.0};
    s.color_separator       = .{0.40, 0.40, 0.42, 1.0};
    s.color_input_bg        = .{0.12, 0.12, 0.14, 1.0};
    s.color_input_cursor    = .{1.00, 1.00, 1.00, 1.0};
    s.color_selection        = .{0.26, 0.59, 0.98, 0.40};
    s.color_scrollbar_bg    = .{0.12, 0.12, 0.14, 1.0};
    s.color_scrollbar_grab  = .{0.40, 0.40, 0.43, 1.0};
    s.color_tooltip_bg      = .{0.10, 0.10, 0.12, 0.95};
    s.color_tree_line       = .{0.35, 0.35, 0.38, 1.0};

    s.font_size        = 16.0;
    s.font_size_title  = 18.0;
    s.padding          = 8.0;
    s.item_spacing     = 4.0;
    s.border_width     = 1.0;
    s.indent_width     = 20.0;
    s.scrollbar_width  = 12.0;

    s.button_height       = 30.0;
    s.checkbox_size       = 18.0;
    s.slider_height       = 20.0;
    s.input_height        = 28.0;
    s.window_title_height = 30.0;
    s.tree_indent         = 18.0;
    s.tooltip_delay       = 0.5;

    return s;
}

// layout

UI_Layout_Mode :: enum {
    VERTICAL;
    HORIZONTAL;
}

UI_Layout :: struct {
    mode:       UI_Layout_Mode;
    cursor_x:   float32;
    cursor_y:   float32;
    origin_x:   float32;
    origin_y:   float32;
    max_w:      float32;
    max_h:      float32;
    row_height: float32;
    indent:     float32;
    content_max_y: float32;
}

MAX_LAYOUT_STACK  :: 64;
MAX_ID_STACK      :: 32;
MAX_SCISSOR_STACK :: 16;

// window state (persisted across frames)

UI_Window_State :: struct {
    rect:       UI_Rect;
    collapsed:  bool;
    scroll_y:   float32;
    content_h:  float32;
    open:       bool;
    was_moved:  bool;
    z_order:    s32;
    scroll_region_rect: UI_Rect;  // stored by begin_scroll_region for end to use
}

UI_Text_Input_State :: struct { // (persisted across frames)
    buffer:       [256] u8;
    length:       s32;
    cursor:       s32;
    selection_start: s32;
    has_selection: bool;
}


UI_Tooltip_State :: struct {
    hover_id:     UI_Id;
    hover_time:   float64;
    show:         bool;
    text:         string;
    x, y:         float32;
}



UI_Context :: struct {
    hot:     UI_Id;
    active:  UI_Id;
    focused: UI_Id;

    mouse:      UI_Mouse_State;
    mouse_prev: UI_Mouse_State;
    keyboard:   UI_Keyboard_State;

    layout_stack: [MAX_LAYOUT_STACK] UI_Layout;
    layout_depth: s32;

    id_stack:       [MAX_ID_STACK] UI_Id;
    id_stack_depth: s32;

    scissor_stack:       [MAX_SCISSOR_STACK] UI_Rect;
    scissor_stack_depth: s32;

    draw_commands: [..] UI_Draw_Cmd;

    // draw commands that render last, with no scissor (popups, tooltips)
    overlay_draw_commands: [..] UI_Draw_Cmd;
    drawing_overlay: bool;

    style: UI_Style;

    window_w: float32;
    window_h: float32;

    // could be extracted out so people can do their own impl, but until that request is made, this remains.
    font:          *MSDF_Font;
    msdf_renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer;
    rect_renderer: *Absolute_Position_Color_Alpha_Renderer;

    window_states:     Table(UI_Id, UI_Window_State);
    text_input_states: Table(UI_Id, UI_Text_Input_State);

    tooltip: UI_Tooltip_State;

    dt:           float64;
    time_elapsed: float64;

    next_z_order:     s32;
    top_window_id:    UI_Id;
    any_window_hovered: bool;

    open_popup_id: UI_Id;
    popup_rect:    UI_Rect;

    scroll_consumed: bool;
    popup_blocking_input: bool;
}

// global context

ui_ctx: *UI_Context;

ui_init :: (
    ctx: *UI_Context,
    font: *MSDF_Font,
    msdf_renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer,
    rect_renderer: *Absolute_Position_Color_Alpha_Renderer
) {
    ctx.style = ui_default_style();
    ctx.font = font;
    ctx.msdf_renderer = msdf_renderer;
    ctx.rect_renderer = rect_renderer;
    ctx.layout_depth = 0;
    ctx.id_stack_depth = 0;
    ctx.scissor_stack_depth = 0;
    ctx.hot = UI_ID_NONE;
    ctx.active = UI_ID_NONE;
    ctx.focused = UI_ID_NONE;
    ctx.next_z_order = 0;
    ctx.open_popup_id = UI_ID_NONE;
    ctx.drawing_overlay = false;
    init(*ctx.window_states);
    init(*ctx.text_input_states);
    ui_ctx = ctx;
}

ui_destroy :: (ctx: *UI_Context) {
    deinit(*ctx.window_states);
    deinit(*ctx.text_input_states);
    array_free(ctx.draw_commands);
    array_free(ctx.overlay_draw_commands);
}

// frame lifecycle

ui_begin_frame :: (
    mouse_x: float32,
    mouse_y: float32,
    mouse_left_down: bool,
    mouse_right_down: bool,
    scroll_y: float32,
    window_w: float32,
    window_h: float32,
    dt: float64
) {
    ctx := ui_ctx;

    ctx.mouse_prev = ctx.mouse;

    ctx.mouse.dx = mouse_x - ctx.mouse.x;
    ctx.mouse.dy = mouse_y - ctx.mouse.y;
    ctx.mouse.x  = mouse_x;
    ctx.mouse.y  = mouse_y;
    ctx.mouse.left_down     = mouse_left_down;
    ctx.mouse.left_pressed  = mouse_left_down && !ctx.mouse_prev.left_down;
    ctx.mouse.left_released = !mouse_left_down && ctx.mouse_prev.left_down;
    ctx.mouse.right_down     = mouse_right_down;
    ctx.mouse.right_pressed  = mouse_right_down && !ctx.mouse_prev.right_down;
    ctx.mouse.right_released = !mouse_right_down && ctx.mouse_prev.right_down;
    ctx.mouse.scroll_y = scroll_y;

    ctx.window_w = window_w;
    ctx.window_h = window_h;
    ctx.dt = dt;
    ctx.time_elapsed += dt;

    array_reset_keeping_memory(*ctx.draw_commands);
    array_reset_keeping_memory(*ctx.overlay_draw_commands);
    ctx.drawing_overlay = false;

    ctx.hot = UI_ID_NONE;
    ctx.any_window_hovered = false;

    ctx.layout_depth = 0;
    ctx.id_stack_depth = 0;
    ctx.scissor_stack_depth = 0;
    ctx.scroll_consumed = false;

    // if a popup is open and mouse is over it, block all normal widget interaction
    ctx.popup_blocking_input = false;
    if ctx.open_popup_id != UI_ID_NONE {
        if rect_contains(ctx.popup_rect, ctx.mouse.x, ctx.mouse.y) {
            ctx.popup_blocking_input = true;
        }
    }

    ui_push_layout(.{
        mode       = .VERTICAL,
        cursor_x   = ctx.style.padding,
        cursor_y   = ctx.style.padding,
        origin_x   = ctx.style.padding,
        origin_y   = ctx.style.padding,
        max_w      = window_w - ctx.style.padding * 2,
        max_h      = window_h - ctx.style.padding * 2,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });
}

ui_end_frame :: () {
    ctx := ui_ctx;

    if ctx.mouse.left_released {
        ctx.active = UI_ID_NONE;
    }

    popup_blocking := ctx.open_popup_id != UI_ID_NONE &&
                      rect_contains(ctx.popup_rect, ctx.mouse.x, ctx.mouse.y);

    if ctx.mouse.left_pressed && ctx.hot == UI_ID_NONE && !popup_blocking {
        ctx.focused = UI_ID_NONE;
    }

    // close popup if clicked outside both the popup and any widget that claimed hot
    if ctx.open_popup_id != UI_ID_NONE && ctx.mouse.left_pressed && ctx.hot == UI_ID_NONE {
        if !rect_contains(ctx.popup_rect, ctx.mouse.x, ctx.mouse.y) {
            ctx.open_popup_id = UI_ID_NONE;
        }
    }

    if ctx.tooltip.hover_id != UI_ID_NONE && ctx.tooltip.hover_id == ctx.hot {
        ctx.tooltip.hover_time += ctx.dt;
        if ctx.tooltip.hover_time >= ctx.style.tooltip_delay {
            ctx.tooltip.show = true;
        }
    } else {
        ctx.tooltip.hover_id = ctx.hot;
        ctx.tooltip.hover_time = 0;
        ctx.tooltip.show = false;
    }

    if ctx.tooltip.show && ctx.tooltip.text.count > 0 {
        ui_draw_tooltip_internal();
    }

    ui_flush_draw_commands();

    ctx.keyboard.key_count = 0;
    ctx.keyboard.char_count = 0;
}

// keyboard input (call from your event loop)

ui_push_key :: (key: UI_Key) {
    ctx := ui_ctx;
    if ctx.keyboard.key_count < 32 {
        ctx.keyboard.keys_pressed[ctx.keyboard.key_count] = key;
        ctx.keyboard.key_count += 1;
    }
}

ui_push_char :: (c: u8) {
    ctx := ui_ctx;
    if ctx.keyboard.char_count < 64 {
        ctx.keyboard.chars_entered[ctx.keyboard.char_count] = c;
        ctx.keyboard.char_count += 1;
    }
}

ui_set_modifiers :: (ctrl: bool, shift: bool) {
    ctx := ui_ctx;
    ctx.keyboard.ctrl_held = ctrl;
    ctx.keyboard.shift_held = shift;
}

// layout

ui_current_layout :: () -> *UI_Layout {
    ctx := ui_ctx;
    assert(ctx.layout_depth > 0, "No layout on stack");
    return *ctx.layout_stack[ctx.layout_depth - 1];
}

ui_push_layout :: (layout: UI_Layout) {
    ctx := ui_ctx;
    assert(ctx.layout_depth < MAX_LAYOUT_STACK, "Layout stack overflow");
    ctx.layout_stack[ctx.layout_depth] = layout;
    ctx.layout_depth += 1;
}

ui_pop_layout :: () {
    ctx := ui_ctx;
    assert(ctx.layout_depth > 0, "Layout stack underflow");
    ctx.layout_depth -= 1;
}

ui_allocate_rect :: (desired_w: float32, desired_h: float32) -> UI_Rect {
    layout := ui_current_layout();
    style := *ui_ctx.style;

    result: UI_Rect;

    if layout.mode == .VERTICAL {
        w := desired_w;
        if w <= 0  w = layout.max_w - layout.indent;

        result = .{
            layout.cursor_x + layout.indent,
            layout.cursor_y,
            w,
            desired_h
        };

        layout.cursor_y += desired_h + style.item_spacing;

    } else {
        result = .{
            layout.cursor_x,
            layout.cursor_y,
            desired_w,
            desired_h
        };

        layout.cursor_x += desired_w + style.item_spacing;

        if desired_h > layout.row_height {
            layout.row_height = desired_h;
        }
    }

    bottom := result.y + result.h;
    if bottom > layout.content_max_y {
        layout.content_max_y = bottom;
    }

    return result;
}

ui_available_width :: () -> float32 {
    layout := ui_current_layout();
    return layout.max_w - layout.indent;
}

// ID Stack

ui_push_id :: (label: string) {
    ctx := ui_ctx;
    assert(ctx.id_stack_depth < MAX_ID_STACK, "ID stack overflow");
    parent := ui_current_id_seed();
    ctx.id_stack[ctx.id_stack_depth] = ui_hash_fnv1a(label, parent);
    ctx.id_stack_depth += 1;
}

ui_pop_id :: () {
    ctx := ui_ctx;
    assert(ctx.id_stack_depth > 0, "ID stack underflow");
    ctx.id_stack_depth -= 1;
}

ui_current_id_seed :: () -> UI_Id {
    ctx := ui_ctx;
    if ctx.id_stack_depth > 0 return ctx.id_stack[ctx.id_stack_depth - 1];
    return 14695981039346656037;
}

ui_get_id :: (label: string) -> UI_Id {
    return ui_hash_fnv1a(label, ui_current_id_seed());
}

// interaction helpers

ui_is_hot :: (id: UI_Id) -> bool {
    return ui_ctx.hot == id;
}

ui_is_active :: (id: UI_Id) -> bool {
    return ui_ctx.active == id;
}

ui_is_focused :: (id: UI_Id) -> bool {
    return ui_ctx.focused == id;
}

ui_try_hot :: (id: UI_Id, rect: UI_Rect) -> bool {
    ctx := ui_ctx;
    // if a popup is blocking input, only popup items can become hot
    if ctx.popup_blocking_input return false;
    if rect_contains(rect, ctx.mouse.x, ctx.mouse.y) {
        ctx.hot = id;
        return true;
    }
    return false;
}

ui_try_active :: (id: UI_Id) -> bool {
    ctx := ui_ctx;
    if ui_is_hot(id) && ctx.mouse.left_pressed {
        ctx.active = id;
        return true;
    }
    return false;
}

ui_was_clicked :: (id: UI_Id) -> bool {
    ctx := ui_ctx;
    return ui_is_hot(id) && ui_is_active(id) && ctx.mouse.left_released;
}

// pixel-to-ndc helpers

ui_pixel_to_ndc :: (px: float32, py: float32) -> Vector3 {
    ctx := ui_ctx;
    ndc_x := (px / ctx.window_w) * 2.0 - 1.0;
    ndc_y := -((py / ctx.window_h) * 2.0 - 1.0);
    return .{ndc_x, ndc_y, 0};
}

ui_pixels_to_ndc :: (pixels: [] Vector2) -> [] Vector3 {
    result := NewArray(pixels.count, Vector3,, allocator = temp);
    for i : 0..pixels.count-1 {
        result[i] = ui_pixel_to_ndc(pixels[i].x, pixels[i].y);
    }
    return result;
}

ui_solid_colors :: (count: s64, color: Vector4) -> [] Vector4 {
    result := NewArray(count, Vector4,, allocator = temp);
    for i : 0..count-1  result[i] = color;
    return result;
}

ui_make_quad_ndc :: (rect: UI_Rect, color: Vector4) -> (positions: [] Vector3, colors: [] Vector4, indices: [] u32) {
    ctx := ui_ctx;

    ndc_x0 := (rect.x / ctx.window_w) * 2.0 - 1.0;
    ndc_x1 := ((rect.x + rect.w) / ctx.window_w) * 2.0 - 1.0;
    ndc_y0 := -((rect.y / ctx.window_h) * 2.0 - 1.0);
    ndc_y1 := -(((rect.y + rect.h) / ctx.window_h) * 2.0 - 1.0);

    positions := NewArray(4, Vector3,, allocator = temp);
    positions[0] = .{ndc_x0, ndc_y0, 0};
    positions[1] = .{ndc_x1, ndc_y0, 0};
    positions[2] = .{ndc_x1, ndc_y1, 0};
    positions[3] = .{ndc_x0, ndc_y1, 0};

    colors := NewArray(4, Vector4,, allocator = temp);
    colors[0] = color;
    colors[1] = color;
    colors[2] = color;
    colors[3] = color;

    indices := NewArray(6, u32,, allocator = temp);
    indices[0] = 0;  indices[1] = 2;  indices[2] = 1;
    indices[3] = 0;  indices[4] = 3;  indices[5] = 2;

    return positions, colors, indices;
}

// draw command emitters

ui_cmd_geometry :: (positions: [] Vector3, rgba_colors: [] Vector4, indices: [] u32) {
    ctx := ui_ctx;
    cmd: UI_Draw_Cmd;
    cmd.type = .GEOMETRY;
    cmd.positions = positions;
    cmd.rgba_colors = rgba_colors;
    cmd.indices = indices;
    if ctx.drawing_overlay {
        array_add(*ctx.overlay_draw_commands, cmd);
    } else {
        array_add(*ctx.draw_commands, cmd);
    }
}

ui_cmd_rect :: (rect: UI_Rect, color: Vector4) {
    positions, colors, indices := ui_make_quad_ndc(rect, color);
    ui_cmd_geometry(positions, colors, indices);
}

ui_cmd_rect_outline :: (rect: UI_Rect, color: Vector4) {
    t := ui_ctx.style.border_width;
    ui_cmd_rect(.{rect.x,              rect.y,              rect.w, t},              color);
    ui_cmd_rect(.{rect.x,              rect.y + rect.h - t, rect.w, t},              color);
    ui_cmd_rect(.{rect.x,              rect.y + t,          t,      rect.h - t * 2}, color);
    ui_cmd_rect(.{rect.x + rect.w - t, rect.y + t,          t,      rect.h - t * 2}, color);
}

ui_cmd_text :: (text: string, x: float32, y: float32, font_size: float32, color: Vector4) {
    ctx := ui_ctx;
    cmd: UI_Draw_Cmd;
    cmd.type = .TEXT;
    cmd.text = text;
    cmd.text_x = x;
    cmd.text_y = y;
    cmd.font_size = font_size;
    cmd.color = color;
    if ctx.drawing_overlay {
        array_add(*ctx.overlay_draw_commands, cmd);
    } else {
        array_add(*ctx.draw_commands, cmd);
    }
}

ui_cmd_scissor_push :: (rect: UI_Rect) {
    ctx := ui_ctx;

    actual_rect: UI_Rect;
    if ctx.scissor_stack_depth > 0 {
        parent_scissor := ctx.scissor_stack[ctx.scissor_stack_depth - 1];
        actual_rect = rect_intersect(rect, parent_scissor);
    } else {
        actual_rect = rect;
    }

    cmd: UI_Draw_Cmd;
    cmd.type = .SCISSOR_PUSH;
    cmd.scissor_rect = actual_rect;
    array_add(*ctx.draw_commands, cmd);

    if ctx.scissor_stack_depth < MAX_SCISSOR_STACK {
        ctx.scissor_stack[ctx.scissor_stack_depth] = actual_rect;
        ctx.scissor_stack_depth += 1;
    }
}

ui_cmd_scissor_pop :: () {
    ctx := ui_ctx;

    if ctx.scissor_stack_depth > 0 {
        ctx.scissor_stack_depth -= 1;
    }

    if ctx.scissor_stack_depth > 0 {
        parent_scissor := ctx.scissor_stack[ctx.scissor_stack_depth - 1];
        cmd: UI_Draw_Cmd;
        cmd.type = .SCISSOR_PUSH;
        cmd.scissor_rect = parent_scissor;
        array_add(*ctx.draw_commands, cmd);
    } else {
        cmd: UI_Draw_Cmd;
        cmd.type = .SCISSOR_POP;
        array_add(*ctx.draw_commands, cmd);
    }
}

// render backend

ui_flush_command_list :: (commands: [] UI_Draw_Cmd) {
    ctx := ui_ctx;

    for cmd : commands {
        if cmd.type == {
            case .GEOMETRY;
                if cmd.indices.count > 0 {
                    glUseProgram(ctx.rect_renderer.shader_program_gl_handle);
                    set_aspect_ratio_uniform(ctx.rect_renderer, .{1.0, 1.0});
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    immediate_render(ctx.rect_renderer, cmd.indices, cmd.positions, cmd.rgba_colors);
                }

            case .TEXT;
                msdf_draw_text_immediate(
                    ctx.msdf_renderer,
                    ctx.font,
                    cmd.text,
                    cmd.text_x,
                    cmd.text_y,
                    cmd.font_size,
                    cmd.color,
                    ctx.window_w,
                    ctx.window_h
                );

            case .SCISSOR_PUSH;
                glEnable(GL_SCISSOR_TEST);
                gl_y := ctx.window_h - (cmd.scissor_rect.y + cmd.scissor_rect.h);
                glScissor(
                    cast(GLint) cmd.scissor_rect.x,
                    cast(GLint) gl_y,
                    cast(GLsizei) max(cmd.scissor_rect.w, 0),
                    cast(GLsizei) max(cmd.scissor_rect.h, 0)
                );

            case .SCISSOR_POP;
                glDisable(GL_SCISSOR_TEST);
        }
    }
}

ui_flush_draw_commands :: () {
    ctx := ui_ctx;

    ui_flush_command_list(ctx.draw_commands);

    // render overlay on top with no scissor
    if ctx.overlay_draw_commands.count > 0 {
        glDisable(GL_SCISSOR_TEST);
        ui_flush_command_list(ctx.overlay_draw_commands);
    }
}

// shape helpers

ui_draw_x_mark :: (rect: UI_Rect, color: Vector4, thickness: float32 = 2.0) {
    center_x := rect.x + rect.w * 0.5;
    center_y := rect.y + rect.h * 0.5;
    arm_length := min(rect.w, rect.h) * 0.15;
    half_thickness := thickness * 0.5;

    arm_dx := arm_length;
    arm_dy := arm_length;
    arm_len := sqrt(arm_dx * arm_dx + arm_dy * arm_dy);
    
    // perpendicular offset (across the arm) gives the arm its width
    perp_x := (-arm_dy / arm_len) * half_thickness;
    perp_y := (arm_dx / arm_len) * half_thickness;
    
    // parallel offset (along the arm) extends tips by half-thickness
    // we do this because sometimes those pixels don't get rasterized due to the 
    // rasterization algorithm
    extend_x := (arm_dx / arm_len) * half_thickness;
    extend_y := (arm_dy / arm_len) * half_thickness;

    corners := NewArray(8, Vector2,, allocator = temp);
    // arm 1: top-left to bottom-right (extended at both tips)
    corners[0] = .{center_x - arm_dx - extend_x + perp_x, center_y - arm_dy - extend_y + perp_y};
    corners[1] = .{center_x - arm_dx - extend_x - perp_x, center_y - arm_dy - extend_y - perp_y};
    corners[2] = .{center_x + arm_dx + extend_x - perp_x, center_y + arm_dy + extend_y - perp_y};
    corners[3] = .{center_x + arm_dx + extend_x + perp_x, center_y + arm_dy + extend_y + perp_y};
    // arm 2: top-right to bottom-left (extended at both tips)
    corners[4] = .{center_x + arm_dx + extend_x + perp_x, center_y - arm_dy - extend_y - perp_y};
    corners[5] = .{center_x + arm_dx + extend_x - perp_x, center_y - arm_dy - extend_y + perp_y};
    corners[6] = .{center_x - arm_dx - extend_x - perp_x, center_y + arm_dy + extend_y + perp_y};
    corners[7] = .{center_x - arm_dx - extend_x + perp_x, center_y + arm_dy + extend_y - perp_y};

    positions := ui_pixels_to_ndc(corners);
    colors := ui_solid_colors(8, color);

    indices := NewArray(12, u32,, allocator = temp);
    indices[0]  = 0;  indices[1]  = 1;  indices[2]  = 2;
    indices[3]  = 0;  indices[4]  = 2;  indices[5]  = 3;
    indices[6]  = 4;  indices[7]  = 5;  indices[8]  = 6;
    indices[9]  = 4;  indices[10] = 6;  indices[11] = 7;

    ui_cmd_geometry(positions, colors, indices);
}

ui_draw_triangle_down :: (cx: float32, cy: float32, size: float32, color: Vector4) {
    half := size * 0.5;

    pixels := NewArray(3, Vector2,, allocator = temp);
    pixels[0] = .{cx - half, cy - half};
    pixels[1] = .{cx + half, cy - half};
    pixels[2] = .{cx,        cy + half};

    positions := ui_pixels_to_ndc(pixels);
    colors := ui_solid_colors(3, color);

    indices := NewArray(3, u32,, allocator = temp);
    indices[0] = 0;  indices[1] = 1;  indices[2] = 2;

    ui_cmd_geometry(positions, colors, indices);
}

ui_draw_triangle_right :: (cx: float32, cy: float32, size: float32, color: Vector4) {
    half := size * 0.5;

    pixels := NewArray(3, Vector2,, allocator = temp);
    pixels[0] = .{cx - half, cy - half};
    pixels[1] = .{cx - half, cy + half};
    pixels[2] = .{cx + half, cy};

    positions := ui_pixels_to_ndc(pixels);
    colors := ui_solid_colors(3, color);

    indices := NewArray(3, u32,, allocator = temp);
    indices[0] = 0;  indices[1] = 1;  indices[2] = 2;

    ui_cmd_geometry(positions, colors, indices);
}

// text helpers

ui_text_baseline_y :: (rect: UI_Rect, font_size: float32) -> float32 {
    ctx := ui_ctx;
    ascender := ctx.font.ascender;
    descender := ctx.font.descender;  // typically negative, e.g. -0.2
    text_height := (ascender - descender) * font_size;
    return rect.y + (rect.h - text_height) * 0.5 + ascender * font_size;
}

ui_text_centered_x :: (rect: UI_Rect, text: string, font_size: float32) -> float32 {
    text_w := msdf_measure_text(ui_ctx.font, text, font_size);
    return rect.x + (rect.w - text_w) * 0.5;
}


#load "widgets.jai";

