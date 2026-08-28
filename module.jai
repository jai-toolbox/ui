#import "Basic";
#import "Math";
#import "Hash_Table";
#import "GL";
#import "File";
#import "File_Utilities";
#import "System";
#import "String";

#import "tbx/opengl";

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
    UP;
    DOWN;
    HOME;
    END;
    ENTER;
    ESCAPE;
    SPACE;
    TAB;

    // used for text editing ctrl-(a/c/v/x/z/y)
    // all, copy, paste, cut, undo, redo
    A; C; F; V; X; Z; Y;
}

UI_Keyboard_State :: struct {
    keys_pressed:  [32] UI_Key;
    key_ctrl_pressed:  [32] bool;
    key_shift_pressed: [32] bool;
    key_shift_chord_clean: [32] bool;
    key_count:     s32;
    chars_entered: [64] u8;
    char_count:    s32;
    ctrl_held:     bool;
    shift_held:    bool;
    alt_held:      bool;
}

// draw commands

UI_Draw_Cmd_Type :: enum {
    GEOMETRY;
    TEXT;
    IMAGE;
    SCISSOR_PUSH;
    SCISSOR_POP;
}

UI_Draw_Cmd :: struct {
    type: UI_Draw_Cmd_Type;

    // GEOMETRY
    vertex_offset: s64;
    vertex_count:  s64;
    index_offset: s64;
    index_count:  s64;
    indices:     [] u32;
    positions:   [] Vector3;
    rgba_colors: [] Vector4;

    // TEXT
    text:      string;
    text_x:    float32;
    text_y:    float32;
    font:      *MSDF_Font;
    font_size: float32;
    color:     Vector4;
    font_override: *MSDF_Font;

    // IMAGE
    texture_id: GLuint;
    tint:       Vector4;

    // SCISSOR
    scissor_rect: UI_Rect;
}

UI_RENDER_BATCH_MAX_VERTICES :: 65536;
UI_RENDER_BATCH_MAX_INDICES  :: 65536;

UI_Render_Batch_Type :: enum {
    NONE;
    GEOMETRY;
    TEXT;
    IMAGE;
}

UI_Render_Batch :: struct {
    type: UI_Render_Batch_Type;

    indices: [..] u32;
    positions: [..] Vector3;
    rgba_colors: [..] Vector4;
    texture_coordinates: [..] Vector2;

    text_font_size: float32;
    text_font: *MSDF_Font;
}

UI_Frame_Draw_Buffers :: struct {
    commands: [..] UI_Draw_Cmd;

    geometry_indices: [..] u32;
    geometry_positions: [..] Vector3;
    geometry_rgba_colors: [..] Vector4;

    text_indices: [..] u32;
    text_positions: [..] Vector3;
    text_texture_coordinates: [..] Vector2;
    text_rgba_colors: [..] Vector4;

    image_indices: [..] u32;
    image_positions: [..] Vector3;
    image_texture_coordinates: [..] Vector2;
    image_rgba_colors: [..] Vector4;
}

UI_Image_Renderer :: struct {
    shader_program_gl_handle: GLuint;
    vertex_attribute_array_gl_handle: GLuint;
    index_buffer_gl_handle: GLuint;
    positions_buffer_gl_handle: GLuint;
    texture_coordinates_buffer_gl_handle: GLuint;
    rgba_colors_buffer_gl_handle: GLuint;

    texture_sampler_uniform_location: GLint = -1;
}

UI_Render_Target :: struct {
    framebuffer: GLuint;
    color_texture: GLuint;
    depth_renderbuffer: GLuint;
    width: s32;
    height: s32;

    previous_framebuffer: GLint;
    previous_viewport: [4] GLint;
    active: bool;
}

UI_Render_Target_View_Input :: struct {
    rect: UI_Rect;
    hovered: bool;
    active: bool;
    focused: bool;

    local_mouse_x: float32;
    local_mouse_y: float32;
    normalized_mouse_x: float32;
    normalized_mouse_y: float32;

    left_down: bool;
    left_pressed: bool;
    left_released: bool;
    right_down: bool;
    right_pressed: bool;
    right_released: bool;
    scroll_y: float32;

    target_width: s32;
    target_height: s32;
}

ui_color_equal :: (a: Vector4, b: Vector4) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
}

// audio events

UI_Audio_Event_Type :: enum u8 {
    BUTTON_CLICK;
    BUTTON_HOVER;
    CHECKBOX_TOGGLE;
    SLIDER_CHANGE;
    SLIDER_GRAB;
    SLIDER_RELEASE;
    TEXT_INPUT_CHAR;
    TEXT_INPUT_BACKSPACE;
    TEXT_INPUT_CONFIRM;
    DROPDOWN_OPEN;
    DROPDOWN_CLOSE;
    DROPDOWN_SELECT;
    TAB_SELECT;
    TREE_EXPAND;
    TREE_COLLAPSE;
    WINDOW_OPEN;
    WINDOW_CLOSE;
    WINDOW_COLLAPSE;
    WINDOW_EXPAND;
    TOOLTIP_SHOW;
    SCROLL;
    FOCUS_GAINED;
    FOCUS_LOST;
}

UI_Audio_Event :: struct {
    type:      UI_Audio_Event_Type;
    source_id: UI_Id;              // which widget emitted it
    // optional payload for the consumer to use for pitch/volume variation
    intensity: float32;            // 0..1, e.g. slider delta magnitude, scroll speed
}

MAX_AUDIO_EVENTS_PER_FRAME :: 64;

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
    visible_h:  float32;
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
    is_window:  bool;
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
    prev_hot: UI_Id;

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

    drawing_overlay: bool;

    draw_buffers: UI_Frame_Draw_Buffers;
    overlay_draw_buffers: UI_Frame_Draw_Buffers;

    render_batch: UI_Render_Batch;

    style: UI_Style;

    window_w: float32;
    window_h: float32;
    work_area: UI_Rect;

    // could be extracted out so people can do their own impl, but until that request is made, this remains.
    font:          *MSDF_Font;
    msdf_renderer: *Multi_Channel_Signed_Distance_Field_Text_Renderer;
    rect_renderer: *Absolute_Position_Color_Alpha_Renderer;
    image_renderer: UI_Image_Renderer;
    text_vertex_upload_capacity: s64;
    text_index_upload_capacity: s64;

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
    in_popup_content: bool;
    current_popup_id: UI_Id;
    popup_previous_overlay: bool;

    audio_events:      [MAX_AUDIO_EVENTS_PER_FRAME] UI_Audio_Event;
    audio_event_count: s32;
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
    ctx.text_vertex_upload_capacity = UI_RENDER_BATCH_MAX_VERTICES;
    ctx.text_index_upload_capacity = UI_RENDER_BATCH_MAX_INDICES;
    ctx.layout_depth = 0;
    ctx.id_stack_depth = 0;
    ctx.scissor_stack_depth = 0;
    ctx.hot = UI_ID_NONE;
    ctx.active = UI_ID_NONE;
    ctx.focused = UI_ID_NONE;
    ctx.next_z_order = 0;
    ctx.open_popup_id = UI_ID_NONE;
    ctx.drawing_overlay = false;
    ctx.in_popup_content = false;
    ctx.current_popup_id = UI_ID_NONE;
    ui_image_renderer_init(*ctx.image_renderer);
    ui_ctx = ctx;
}

ui_destroy :: (ctx: *UI_Context) {
    deinit(*ctx.window_states);
    deinit(*ctx.text_input_states);
    ui_frame_draw_buffers_deinit(*ctx.draw_buffers);
    ui_frame_draw_buffers_deinit(*ctx.overlay_draw_buffers);
    ui_render_batch_deinit(*ctx.render_batch);
    ui_image_renderer_deinit(*ctx.image_renderer);
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
    ctx.audio_event_count = 0;

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
    ctx.work_area = .{0, 0, window_w, window_h};
    ctx.dt = dt;
    ctx.time_elapsed += dt;

    ui_frame_draw_buffers_reset(*ctx.draw_buffers);
    ui_frame_draw_buffers_reset(*ctx.overlay_draw_buffers);
    ctx.drawing_overlay = false;

    ctx.hot = UI_ID_NONE;
    ctx.any_window_hovered = false;

    ctx.layout_depth = 0;
    ctx.id_stack_depth = 0;
    ctx.scissor_stack_depth = 0;
    ctx.scroll_consumed = false;
    ctx.in_popup_content = false;
    ctx.current_popup_id = UI_ID_NONE;

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
        visible_h  = window_h - ctx.style.padding * 2,
        row_height = 0,
        indent     = 0,
        content_max_y = 0,
    });
}

ui_set_work_area :: (rect: UI_Rect) {
    ui_ctx.work_area = rect;
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


    // close popup if clicked outside it. If the popup trigger claimed hot this
    // frame, keep it open so button toggles do not immediately close themselves.
    if ctx.open_popup_id != UI_ID_NONE && ctx.mouse.left_pressed {
        if !rect_contains(ctx.popup_rect, ctx.mouse.x, ctx.mouse.y) {
            if ctx.hot != ctx.open_popup_id {
                ctx.open_popup_id = UI_ID_NONE;
            }
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

    if ctx.hot != UI_ID_NONE && ctx.hot != ctx.prev_hot {
        ui_emit_audio(.BUTTON_HOVER, ctx.hot, 0.3);
    }
    ctx.prev_hot = ctx.hot;

    ctx.keyboard.key_count = 0;
    ctx.keyboard.char_count = 0;
}

// keyboard input (call from your event loop)

ui_push_key :: (key: UI_Key, ctrl_pressed: bool = false, shift_pressed: bool = false, shift_chord_clean: bool = false) {
    ctx := ui_ctx;
    if ctx.keyboard.key_count < 32 {
        index := ctx.keyboard.key_count;
        ctx.keyboard.keys_pressed[index] = key;
        ctx.keyboard.key_ctrl_pressed[index] = ctrl_pressed;
        ctx.keyboard.key_shift_pressed[index] = shift_pressed;
        ctx.keyboard.key_shift_chord_clean[index] = shift_chord_clean;
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

ui_set_modifiers :: (ctrl: bool, shift: bool, alt: bool = false) {
    ctx := ui_ctx;
    ctx.keyboard.ctrl_held = ctrl;
    ctx.keyboard.shift_held = shift;
    ctx.keyboard.alt_held = alt;
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

ui_available_height :: () -> float32 {
    layout := ui_current_layout();
    bottom := layout.origin_y + ifx layout.visible_h > 0 then layout.visible_h else layout.max_h;
    result := bottom - layout.cursor_y;
    if result < 0 return 0;
    return result;
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
    // if a popup is open, only popup items can become hot through the normal
    // widget path. Popup triggers may still claim hot explicitly when toggled.
    if ctx.open_popup_id != UI_ID_NONE && !ctx.in_popup_content return false;
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

ui_close_current_popup :: () {
    ctx := ui_ctx;
    if ctx.current_popup_id != UI_ID_NONE {
        ctx.open_popup_id = UI_ID_NONE;
    }
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


// emission of commands

// audio

ui_emit_audio :: (type: UI_Audio_Event_Type, source_id: UI_Id = UI_ID_NONE, intensity: float32 = 1.0) {
    ctx := ui_ctx;
    if ctx.audio_event_count >= MAX_AUDIO_EVENTS_PER_FRAME return; // drop if full
    ctx.audio_events[ctx.audio_event_count] = .{
        type      = type,
        source_id = source_id,
        intensity = intensity,
    };
    ctx.audio_event_count += 1;
}

/*

used client side in your loop, you can do something like this:

for event : ui_drain_audio_events() {
    if event.type == {
        case .BUTTON_CLICK;    audio_play("click.wav");
        ...
    }
}

*/
ui_drain_audio_events :: () -> [] UI_Audio_Event {
    ctx := ui_ctx;
    result: [] UI_Audio_Event;
    result.data  = ctx.audio_events.data;
    result.count = ctx.audio_event_count;
    return result;
}

// draw command

ui_current_draw_buffers :: () -> *UI_Frame_Draw_Buffers {
    ctx := ui_ctx;
    if ctx.drawing_overlay return *ctx.overlay_draw_buffers;
    return *ctx.draw_buffers;
}

ui_draw_cmd_can_merge :: (a: UI_Draw_Cmd, b: UI_Draw_Cmd) -> bool {
    if a.type != b.type return false;
    if a.index_offset + a.index_count != b.index_offset return false;
    if a.vertex_offset + a.vertex_count != b.vertex_offset return false;

    if a.type == {
        case .GEOMETRY;
            return true;

        case .TEXT;
            return a.font == b.font && a.font_size == b.font_size;

        case;
            return false;
    }

    return false;
}

ui_add_draw_cmd :: (cmd: UI_Draw_Cmd) {
    buffers := ui_current_draw_buffers();
    if buffers.commands.count > 0 {
        last := *buffers.commands[buffers.commands.count - 1];
        if ui_draw_cmd_can_merge(last.*, cmd) {
            last.index_count += cmd.index_count;
            last.vertex_count += cmd.vertex_count;
            return;
        }
    }

    array_add(*buffers.commands, cmd);
}

ui_cmd_geometry :: (positions: [] Vector3, rgba_colors: [] Vector4, indices: [] u32) {
    if indices.count == 0 return;

    buffers := ui_current_draw_buffers();
    vertex_offset := cast(u32) buffers.geometry_positions.count;

    cmd: UI_Draw_Cmd;
    cmd.type = .GEOMETRY;
    cmd.vertex_offset = buffers.geometry_positions.count;
    cmd.vertex_count = positions.count;
    cmd.index_offset = buffers.geometry_indices.count;
    cmd.index_count = indices.count;

    array_reserve(*buffers.geometry_positions, buffers.geometry_positions.count + positions.count);
    array_reserve(*buffers.geometry_rgba_colors, buffers.geometry_rgba_colors.count + rgba_colors.count);
    array_reserve(*buffers.geometry_indices, buffers.geometry_indices.count + indices.count);

    for positions    array_add(*buffers.geometry_positions, it);
    for rgba_colors  array_add(*buffers.geometry_rgba_colors, it);
    for indices      array_add(*buffers.geometry_indices, vertex_offset + it);

    ui_add_draw_cmd(cmd);
}

ui_cmd_rect :: (rect: UI_Rect, color: Vector4) {
    ctx := ui_ctx;
    buffers := ui_current_draw_buffers();

    ndc_x0 := (rect.x / ctx.window_w) * 2.0 - 1.0;
    ndc_x1 := ((rect.x + rect.w) / ctx.window_w) * 2.0 - 1.0;
    ndc_y0 := -((rect.y / ctx.window_h) * 2.0 - 1.0);
    ndc_y1 := -(((rect.y + rect.h) / ctx.window_h) * 2.0 - 1.0);

    vertex_offset := cast(u32) buffers.geometry_positions.count;

    cmd: UI_Draw_Cmd;
    cmd.type = .GEOMETRY;
    cmd.vertex_offset = buffers.geometry_positions.count;
    cmd.vertex_count = 4;
    cmd.index_offset = buffers.geometry_indices.count;
    cmd.index_count = 6;

    array_reserve(*buffers.geometry_positions, buffers.geometry_positions.count + 4);
    array_reserve(*buffers.geometry_rgba_colors, buffers.geometry_rgba_colors.count + 4);
    array_reserve(*buffers.geometry_indices, buffers.geometry_indices.count + 6);

    array_add(*buffers.geometry_positions, .{ndc_x0, ndc_y0, 0});
    array_add(*buffers.geometry_positions, .{ndc_x1, ndc_y0, 0});
    array_add(*buffers.geometry_positions, .{ndc_x1, ndc_y1, 0});
    array_add(*buffers.geometry_positions, .{ndc_x0, ndc_y1, 0});

    array_add(*buffers.geometry_rgba_colors, color);
    array_add(*buffers.geometry_rgba_colors, color);
    array_add(*buffers.geometry_rgba_colors, color);
    array_add(*buffers.geometry_rgba_colors, color);

    array_add(*buffers.geometry_indices, vertex_offset + 0);
    array_add(*buffers.geometry_indices, vertex_offset + 2);
    array_add(*buffers.geometry_indices, vertex_offset + 1);
    array_add(*buffers.geometry_indices, vertex_offset + 0);
    array_add(*buffers.geometry_indices, vertex_offset + 3);
    array_add(*buffers.geometry_indices, vertex_offset + 2);

    ui_add_draw_cmd(cmd);
}

ui_cmd_rect_outline :: (rect: UI_Rect, color: Vector4) {
    t := ui_ctx.style.border_width;
    ui_cmd_rect(.{rect.x,              rect.y,              rect.w, t},              color);
    ui_cmd_rect(.{rect.x,              rect.y + rect.h - t, rect.w, t},              color);
    ui_cmd_rect(.{rect.x,              rect.y + t,          t,      rect.h - t * 2}, color);
    ui_cmd_rect(.{rect.x + rect.w - t, rect.y + t,          t,      rect.h - t * 2}, color);
}

ui_cmd_image :: (texture_id: GLuint, rect: UI_Rect, tint: Vector4 = .{1, 1, 1, 1}) {
    if texture_id == 0 || rect.w <= 0 || rect.h <= 0 return;

    ctx := ui_ctx;
    buffers := ui_current_draw_buffers();

    ndc_x0 := (rect.x / ctx.window_w) * 2.0 - 1.0;
    ndc_x1 := ((rect.x + rect.w) / ctx.window_w) * 2.0 - 1.0;
    ndc_y0 := -((rect.y / ctx.window_h) * 2.0 - 1.0);
    ndc_y1 := -(((rect.y + rect.h) / ctx.window_h) * 2.0 - 1.0);

    vertex_offset := cast(u32) buffers.image_positions.count;

    cmd: UI_Draw_Cmd;
    cmd.type = .IMAGE;
    cmd.vertex_offset = buffers.image_positions.count;
    cmd.vertex_count = 4;
    cmd.index_offset = buffers.image_indices.count;
    cmd.index_count = 6;
    cmd.texture_id = texture_id;
    cmd.tint = tint;

    array_reserve(*buffers.image_positions, buffers.image_positions.count + 4);
    array_reserve(*buffers.image_texture_coordinates, buffers.image_texture_coordinates.count + 4);
    array_reserve(*buffers.image_rgba_colors, buffers.image_rgba_colors.count + 4);
    array_reserve(*buffers.image_indices, buffers.image_indices.count + 6);

    array_add(*buffers.image_positions, .{ndc_x0, ndc_y0, 0});
    array_add(*buffers.image_positions, .{ndc_x1, ndc_y0, 0});
    array_add(*buffers.image_positions, .{ndc_x1, ndc_y1, 0});
    array_add(*buffers.image_positions, .{ndc_x0, ndc_y1, 0});

    array_add(*buffers.image_texture_coordinates, .{0, 1});
    array_add(*buffers.image_texture_coordinates, .{1, 1});
    array_add(*buffers.image_texture_coordinates, .{1, 0});
    array_add(*buffers.image_texture_coordinates, .{0, 0});

    array_add(*buffers.image_rgba_colors, tint);
    array_add(*buffers.image_rgba_colors, tint);
    array_add(*buffers.image_rgba_colors, tint);
    array_add(*buffers.image_rgba_colors, tint);

    array_add(*buffers.image_indices, vertex_offset + 0);
    array_add(*buffers.image_indices, vertex_offset + 2);
    array_add(*buffers.image_indices, vertex_offset + 1);
    array_add(*buffers.image_indices, vertex_offset + 0);
    array_add(*buffers.image_indices, vertex_offset + 3);
    array_add(*buffers.image_indices, vertex_offset + 2);

    ui_add_draw_cmd(cmd);
}

// we should rename this to queue draw command or something like that.
// x and y are the 
ui_cmd_text :: (text: string, left_edge_x: float32, baseline_y: float32, font_size: float32, color: Vector4) {
    ui_cmd_text_font(ui_ctx.font, text, left_edge_x, baseline_y, font_size, color);
}

ui_cmd_text_font :: (font: *MSDF_Font, text: string, left_edge_x: float32, baseline_y: float32, font_size: float32, color: Vector4) {
    if text.count == 0 return;
    if font == null return;

    buffers := ui_current_draw_buffers();
    vertex_offset := buffers.text_positions.count;
    index_offset := buffers.text_indices.count;

    msdf_append_text_geometry(
        font,
        text,
        left_edge_x,
        baseline_y,
        font_size,
        ui_ctx.window_w,
        ui_ctx.window_h,
        color,
        *buffers.text_positions,
        *buffers.text_texture_coordinates,
        *buffers.text_rgba_colors,
        *buffers.text_indices
    );

    index_count := buffers.text_indices.count - index_offset;
    if index_count == 0 return;

    cmd: UI_Draw_Cmd;
    cmd.type = .TEXT;
    cmd.vertex_offset = vertex_offset;
    cmd.vertex_count = buffers.text_positions.count - vertex_offset;
    cmd.index_offset = index_offset;
    cmd.index_count = index_count;
    cmd.font = font;
    cmd.font_size = font_size;
    cmd.color = color;
    cmd.font_override = font;
    ui_add_draw_cmd(cmd);
}

ui_cmd_texture :: (texture_id: GLuint, rect: UI_Rect, tint: Vector4 = .{1, 1, 1, 1}) {
    ui_cmd_image(texture_id, rect, tint);
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
    ui_add_draw_cmd(cmd);

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
        ui_add_draw_cmd(cmd);
    } else {
        cmd: UI_Draw_Cmd;
        cmd.type = .SCISSOR_POP;
        ui_add_draw_cmd(cmd);
    }
}

// render backend

ui_render_batch_reset :: (batch: *UI_Render_Batch) {
    batch.type = .NONE;
    array_reset_keeping_memory(*batch.indices);
    array_reset_keeping_memory(*batch.positions);
    array_reset_keeping_memory(*batch.rgba_colors);
    array_reset_keeping_memory(*batch.texture_coordinates);
}

ui_render_batch_deinit :: (batch: *UI_Render_Batch) {
    array_free(batch.indices);
    array_free(batch.positions);
    array_free(batch.rgba_colors);
    array_free(batch.texture_coordinates);
}

ui_frame_draw_buffers_reset :: (buffers: *UI_Frame_Draw_Buffers) {
    array_reset_keeping_memory(*buffers.commands);
    array_reset_keeping_memory(*buffers.geometry_indices);
    array_reset_keeping_memory(*buffers.geometry_positions);
    array_reset_keeping_memory(*buffers.geometry_rgba_colors);
    array_reset_keeping_memory(*buffers.text_indices);
    array_reset_keeping_memory(*buffers.text_positions);
    array_reset_keeping_memory(*buffers.text_texture_coordinates);
    array_reset_keeping_memory(*buffers.text_rgba_colors);
    array_reset_keeping_memory(*buffers.image_indices);
    array_reset_keeping_memory(*buffers.image_positions);
    array_reset_keeping_memory(*buffers.image_texture_coordinates);
    array_reset_keeping_memory(*buffers.image_rgba_colors);
}

ui_frame_draw_buffers_deinit :: (buffers: *UI_Frame_Draw_Buffers) {
    array_free(buffers.commands);
    array_free(buffers.geometry_indices);
    array_free(buffers.geometry_positions);
    array_free(buffers.geometry_rgba_colors);
    array_free(buffers.text_indices);
    array_free(buffers.text_positions);
    array_free(buffers.text_texture_coordinates);
    array_free(buffers.text_rgba_colors);
    array_free(buffers.image_indices);
    array_free(buffers.image_positions);
    array_free(buffers.image_texture_coordinates);
    array_free(buffers.image_rgba_colors);
}

ui_flush_render_batch :: (batch: *UI_Render_Batch) {
    ctx := ui_ctx;
    if batch.type == .NONE || batch.indices.count == 0 {
        ui_render_batch_reset(batch);
        return;
    }

    if batch.type == {
        case .GEOMETRY;
            glUseProgram(ctx.rect_renderer.shader_program_gl_handle);
            set_aspect_ratio_uniform(ctx.rect_renderer, .{1.0, 1.0});
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            immediate_render(ctx.rect_renderer, batch.indices, batch.positions, batch.rgba_colors);

        case .TEXT;
            font := ifx batch.text_font != null then batch.text_font else ctx.font;
            glUseProgram(ctx.msdf_renderer.shader_program_gl_handle);

            glActiveTexture(GL_TEXTURE0);
            font := ifx batch.text_font != null then batch.text_font else ctx.font;
            glBindTexture(GL_TEXTURE_2D, font.texture_id);

            set_texture_sampler_uniform(ctx.msdf_renderer, 0);
            set_aspect_ratio_uniform(ctx.msdf_renderer, .{1.0, 1.0});

            px_range := msdf_screen_pixels_per_distance_range(font, batch.text_font_size);
            set_screen_pixels_per_distance_range_uniform(ctx.msdf_renderer, px_range);

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            immediate_render(ctx.msdf_renderer, batch.indices, batch.positions, batch.texture_coordinates, batch.rgba_colors);

        case .IMAGE;
            // This legacy batch path is kept for compatibility with older helpers.
            // Image commands are rendered directly from frame draw buffers below.
    }

    ui_render_batch_reset(batch);
}

ui_render_batch_has_room :: (batch: *UI_Render_Batch, vertex_count: s64, index_count: s64) -> bool {
    return batch.positions.count + vertex_count <= UI_RENDER_BATCH_MAX_VERTICES &&
           batch.indices.count   + index_count  <= UI_RENDER_BATCH_MAX_INDICES;
}

ui_render_batch_append_geometry :: (batch: *UI_Render_Batch, cmd: UI_Draw_Cmd) {
    vertex_offset := cast(u32) batch.positions.count;

    for cmd.positions    array_add(*batch.positions, it);
    for cmd.rgba_colors  array_add(*batch.rgba_colors, it);
    for cmd.indices      array_add(*batch.indices, vertex_offset + it);
}

ui_render_batch_append_geometry_range :: (batch: *UI_Render_Batch, buffers: *UI_Frame_Draw_Buffers, cmd: UI_Draw_Cmd) {
    vertex_offset := cast(u32) batch.positions.count;

    array_reserve(*batch.positions, batch.positions.count + cmd.vertex_count);
    array_reserve(*batch.rgba_colors, batch.rgba_colors.count + cmd.vertex_count);
    array_reserve(*batch.indices, batch.indices.count + cmd.index_count);

    for i : 0..cmd.vertex_count-1 {
        array_add(*batch.positions, buffers.geometry_positions[cmd.vertex_offset + i]);
        array_add(*batch.rgba_colors, buffers.geometry_rgba_colors[cmd.vertex_offset + i]);
    }

    for i : 0..cmd.index_count-1 {
        index := buffers.geometry_indices[cmd.index_offset + i];
        array_add(*batch.indices, vertex_offset + index - cast(u32) cmd.vertex_offset);
    }
}

ui_render_batch_append_text :: (batch: *UI_Render_Batch, cmd: UI_Draw_Cmd) {
    font := ifx cmd.font != null then cmd.font else ui_ctx.font;
    msdf_append_text_geometry(
        font,
        cmd.text,
        cmd.text_x,
        cmd.text_y,
        cmd.font_size,
        ui_ctx.window_w,
        ui_ctx.window_h,
        cmd.color,
        *batch.positions,
        *batch.texture_coordinates,
        *batch.rgba_colors,
        *batch.indices
    );
    batch.text_font = font;
}

ui_render_batch_append_text_range :: (batch: *UI_Render_Batch, buffers: *UI_Frame_Draw_Buffers, cmd: UI_Draw_Cmd) {
    vertex_offset := cast(u32) batch.positions.count;

    array_reserve(*batch.positions, batch.positions.count + cmd.vertex_count);
    array_reserve(*batch.texture_coordinates, batch.texture_coordinates.count + cmd.vertex_count);
    array_reserve(*batch.rgba_colors, batch.rgba_colors.count + cmd.vertex_count);
    array_reserve(*batch.indices, batch.indices.count + cmd.index_count);

    for i : 0..cmd.vertex_count-1 {
        array_add(*batch.positions, buffers.text_positions[cmd.vertex_offset + i]);
        array_add(*batch.texture_coordinates, buffers.text_texture_coordinates[cmd.vertex_offset + i]);
        array_add(*batch.rgba_colors, buffers.text_rgba_colors[cmd.vertex_offset + i]);
    }

    for i : 0..cmd.index_count-1 {
        index := buffers.text_indices[cmd.index_offset + i];
        array_add(*batch.indices, vertex_offset + index - cast(u32) cmd.vertex_offset);
    }
}

UI_IMAGE_VERTEX_SHADER :: #string END
#version 330 core

in vec3 position;
in vec2 texture_coordinate_in;
in vec4 rgba_color_in;

out vec2 texture_coordinate;
out vec4 rgba_color;

void main() {
    texture_coordinate = texture_coordinate_in;
    rgba_color = rgba_color_in;
    gl_Position = vec4(position.xy, 0.0, 1.0);
}
END

UI_IMAGE_FRAGMENT_SHADER :: #string END
#version 330 core

in vec2 texture_coordinate;
in vec4 rgba_color;

uniform sampler2D texture_sampler;

out vec4 frag_color;

void main() {
    frag_color = texture(texture_sampler, texture_coordinate) * rgba_color;
}
END

ui_image_renderer_init_attribute :: (program: GLuint, vao: GLuint, buffer: GLuint, name: *u8, components: GLint) {
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);

    location := glGetAttribLocation(program, name);
    if location >= 0 {
        glEnableVertexAttribArray(xx location);
        glVertexAttribPointer(xx location, components, GL_FLOAT, GL_FALSE, 0, null);
    }

    glBindVertexArray(0);
}

ui_image_renderer_init_buffer :: (buffer: *GLuint, element_size: s64) {
    glGenBuffers(1, buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer.*);
    glBufferData(GL_ARRAY_BUFFER, UI_RENDER_BATCH_MAX_VERTICES * element_size, null, GL_STREAM_DRAW);
}

ui_image_renderer_init :: (renderer: *UI_Image_Renderer) {
    program, ok := create_shader_program(UI_IMAGE_VERTEX_SHADER, UI_IMAGE_FRAGMENT_SHADER);
    if !ok {
        log_error("Failed to create UI image shader program");
        return;
    }

    renderer.shader_program_gl_handle = program;
    renderer.texture_sampler_uniform_location = glGetUniformLocation(program, "texture_sampler");

    glGenVertexArrays(1, *renderer.vertex_attribute_array_gl_handle);
    glBindVertexArray(renderer.vertex_attribute_array_gl_handle);

    glGenBuffers(1, *renderer.index_buffer_gl_handle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer.index_buffer_gl_handle);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, UI_RENDER_BATCH_MAX_INDICES * size_of(u32), null, GL_STREAM_DRAW);

    ui_image_renderer_init_buffer(*renderer.positions_buffer_gl_handle, size_of(Vector3));
    ui_image_renderer_init_attribute(program, renderer.vertex_attribute_array_gl_handle, renderer.positions_buffer_gl_handle, "position", 3);

    ui_image_renderer_init_buffer(*renderer.texture_coordinates_buffer_gl_handle, size_of(Vector2));
    ui_image_renderer_init_attribute(program, renderer.vertex_attribute_array_gl_handle, renderer.texture_coordinates_buffer_gl_handle, "texture_coordinate_in", 2);

    ui_image_renderer_init_buffer(*renderer.rgba_colors_buffer_gl_handle, size_of(Vector4));
    ui_image_renderer_init_attribute(program, renderer.vertex_attribute_array_gl_handle, renderer.rgba_colors_buffer_gl_handle, "rgba_color_in", 4);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

ui_image_renderer_deinit :: (renderer: *UI_Image_Renderer) {
    if renderer.shader_program_gl_handle != 0 glDeleteProgram(renderer.shader_program_gl_handle);
    if renderer.vertex_attribute_array_gl_handle != 0 glDeleteVertexArrays(1, *renderer.vertex_attribute_array_gl_handle);
    if renderer.index_buffer_gl_handle != 0 glDeleteBuffers(1, *renderer.index_buffer_gl_handle);
    if renderer.positions_buffer_gl_handle != 0 glDeleteBuffers(1, *renderer.positions_buffer_gl_handle);
    if renderer.texture_coordinates_buffer_gl_handle != 0 glDeleteBuffers(1, *renderer.texture_coordinates_buffer_gl_handle);
    if renderer.rgba_colors_buffer_gl_handle != 0 glDeleteBuffers(1, *renderer.rgba_colors_buffer_gl_handle);
}

ui_upload_geometry_draw_buffers :: (buffers: *UI_Frame_Draw_Buffers) {
    ctx := ui_ctx;
    if buffers.geometry_indices.count == 0 return;

    glBindVertexArray(ctx.rect_renderer.immediate_vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, ctx.rect_renderer.immediate_positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.geometry_positions.count * size_of(Vector3), buffers.geometry_positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, ctx.rect_renderer.immediate_passthrough_rgba_colors_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.geometry_rgba_colors.count * size_of(Vector4), buffers.geometry_rgba_colors.data);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ctx.rect_renderer.immediate_index_buffer_gl_handle);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, buffers.geometry_indices.count * size_of(u32), buffers.geometry_indices.data);
}

ui_upload_image_draw_buffers :: (buffers: *UI_Frame_Draw_Buffers) {
    ctx := ui_ctx;
    if buffers.image_indices.count == 0 return;

    renderer := *ctx.image_renderer;
    glBindVertexArray(renderer.vertex_attribute_array_gl_handle);

    glBindBuffer(GL_ARRAY_BUFFER, renderer.positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.image_positions.count * size_of(Vector3), buffers.image_positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, renderer.texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.image_texture_coordinates.count * size_of(Vector2), buffers.image_texture_coordinates.data);

    glBindBuffer(GL_ARRAY_BUFFER, renderer.rgba_colors_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.image_rgba_colors.count * size_of(Vector4), buffers.image_rgba_colors.data);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer.index_buffer_gl_handle);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, buffers.image_indices.count * size_of(u32), buffers.image_indices.data);
}

ui_upload_text_draw_buffers :: (buffers: *UI_Frame_Draw_Buffers) {
    ctx := ui_ctx;
    if buffers.text_indices.count == 0 return;

    glBindVertexArray(ctx.msdf_renderer.immediate_vertex_attribute_array_gl_handle);

    if buffers.text_positions.count > ctx.text_vertex_upload_capacity {
        new_capacity := max(cast(s64) UI_RENDER_BATCH_MAX_VERTICES, ctx.text_vertex_upload_capacity);
        while new_capacity < buffers.text_positions.count  new_capacity *= 2;

        glBindBuffer(GL_ARRAY_BUFFER, ctx.msdf_renderer.immediate_positions_buffer_gl_handle);
        glBufferData(GL_ARRAY_BUFFER, new_capacity * size_of(Vector3), null, GL_STREAM_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, ctx.msdf_renderer.immediate_passthrough_texture_coordinates_buffer_gl_handle);
        glBufferData(GL_ARRAY_BUFFER, new_capacity * size_of(Vector2), null, GL_STREAM_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, ctx.msdf_renderer.immediate_passthrough_rgba_colors_buffer_gl_handle);
        glBufferData(GL_ARRAY_BUFFER, new_capacity * size_of(Vector4), null, GL_STREAM_DRAW);

        ctx.text_vertex_upload_capacity = new_capacity;
    }

    if buffers.text_indices.count > ctx.text_index_upload_capacity {
        new_capacity := max(cast(s64) UI_RENDER_BATCH_MAX_INDICES, ctx.text_index_upload_capacity);
        while new_capacity < buffers.text_indices.count  new_capacity *= 2;

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ctx.msdf_renderer.immediate_index_buffer_gl_handle);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, new_capacity * size_of(u32), null, GL_STREAM_DRAW);

        ctx.text_index_upload_capacity = new_capacity;
    }

    glBindBuffer(GL_ARRAY_BUFFER, ctx.msdf_renderer.immediate_positions_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.text_positions.count * size_of(Vector3), buffers.text_positions.data);

    glBindBuffer(GL_ARRAY_BUFFER, ctx.msdf_renderer.immediate_passthrough_texture_coordinates_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.text_texture_coordinates.count * size_of(Vector2), buffers.text_texture_coordinates.data);

    glBindBuffer(GL_ARRAY_BUFFER, ctx.msdf_renderer.immediate_passthrough_rgba_colors_buffer_gl_handle);
    glBufferSubData(GL_ARRAY_BUFFER, 0, buffers.text_rgba_colors.count * size_of(Vector4), buffers.text_rgba_colors.data);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ctx.msdf_renderer.immediate_index_buffer_gl_handle);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, buffers.text_indices.count * size_of(u32), buffers.text_indices.data);
}

ui_flush_command_list :: (buffers: *UI_Frame_Draw_Buffers) {
    ctx := ui_ctx;

    // save depth state and disable for UI rendering
    depth_test_was_enabled := glIsEnabled(GL_DEPTH_TEST);
    depth_write_was_enabled: GLboolean;
    glGetBooleanv(GL_DEPTH_WRITEMASK, *depth_write_was_enabled);

    // the depth test checks each fragments depth and discards fragments that are behind something
    // we don't want this for multiple reasons, first we don't want it to interact with the 3d scene we're already probably rendering
    // also we don't want z-fighting, instead we'll handle the ordering ourselves
    glDisable(GL_DEPTH_TEST);
    // make it so that the ui doesn't write to the depth buffer, is this redundant?
    glDepthMask(GL_FALSE);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    ui_upload_geometry_draw_buffers(buffers);
    ui_upload_text_draw_buffers(buffers);
    ui_upload_image_draw_buffers(buffers);

    active_type := UI_Render_Batch_Type.NONE;
    active_text_font_size: float32 = 0;
    active_text_font: *MSDF_Font = null;
    active_image_texture_id: GLuint = 0;

    for cmd : buffers.commands {
        if cmd.type == {
            case .GEOMETRY;
                if cmd.index_count == 0 continue;

                if active_type != .GEOMETRY {
                    glUseProgram(ctx.rect_renderer.shader_program_gl_handle);
                    set_aspect_ratio_uniform(ctx.rect_renderer, .{1.0, 1.0});
                    glBindVertexArray(ctx.rect_renderer.immediate_vertex_attribute_array_gl_handle);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ctx.rect_renderer.immediate_index_buffer_gl_handle);
                    active_type = .GEOMETRY;
                }

                offset := cmd.index_offset * size_of(u32);
                glDrawElements(GL_TRIANGLES, xx cmd.index_count, GL_UNSIGNED_INT, cast(*void) offset);

            case .IMAGE;
                if cmd.index_count == 0 continue;

                same_image_state := active_type == .IMAGE &&
                                    active_image_texture_id == cmd.texture_id;

                if !same_image_state {
                    renderer := *ctx.image_renderer;
                    glUseProgram(renderer.shader_program_gl_handle);
                    glBindVertexArray(renderer.vertex_attribute_array_gl_handle);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer.index_buffer_gl_handle);

                    glActiveTexture(GL_TEXTURE0);
                    glBindTexture(GL_TEXTURE_2D, cmd.texture_id);
                    glUniform1i(renderer.texture_sampler_uniform_location, 0);

                    active_type = .IMAGE;
                    active_image_texture_id = cmd.texture_id;
                }

                offset := cmd.index_offset * size_of(u32);
                glDrawElements(GL_TRIANGLES, xx cmd.index_count, GL_UNSIGNED_INT, cast(*void) offset);

            case .TEXT;
                if cmd.index_count == 0 continue;

                font := ifx cmd.font != null then cmd.font else ctx.font;
                same_text_state := active_type == .TEXT &&
                                   active_text_font == font &&
                                   active_text_font_size == cmd.font_size;

                if !same_text_state {
                    glUseProgram(ctx.msdf_renderer.shader_program_gl_handle);
                    glBindVertexArray(ctx.msdf_renderer.immediate_vertex_attribute_array_gl_handle);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ctx.msdf_renderer.immediate_index_buffer_gl_handle);

                    glActiveTexture(GL_TEXTURE0);
                    glBindTexture(GL_TEXTURE_2D, font.texture_id);

                    set_texture_sampler_uniform(ctx.msdf_renderer, 0);
                    set_aspect_ratio_uniform(ctx.msdf_renderer, .{1.0, 1.0});

                    px_range := msdf_screen_pixels_per_distance_range(font, cmd.font_size);
                    set_screen_pixels_per_distance_range_uniform(ctx.msdf_renderer, px_range);

                    active_type = .TEXT;
                    active_text_font = font;
                    active_text_font_size = cmd.font_size;
                }

                offset := cmd.index_offset * size_of(u32);
                glDrawElements(GL_TRIANGLES, xx cmd.index_count, GL_UNSIGNED_INT, cast(*void) offset);

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

    glBindVertexArray(0);
    glUseProgram(0);

    // restore depth state
    if depth_test_was_enabled {
        glEnable(GL_DEPTH_TEST);
    } else {
        glDisable(GL_DEPTH_TEST);
    }
    glDepthMask(depth_write_was_enabled);
}

ui_flush_draw_commands :: () {
    ctx := ui_ctx;

    ui_flush_command_list(*ctx.draw_buffers);

    // render overlay on top with no scissor
    if ctx.overlay_draw_buffers.commands.count > 0 {
        glDisable(GL_SCISSOR_TEST);
        ui_flush_command_list(*ctx.overlay_draw_buffers);
    }
}

ui_render_target_deinit :: (target: *UI_Render_Target) {
    if target.framebuffer != 0 glDeleteFramebuffers(1, *target.framebuffer);
    if target.color_texture != 0 glDeleteTextures(1, *target.color_texture);
    if target.depth_renderbuffer != 0 glDeleteRenderbuffers(1, *target.depth_renderbuffer);
    target.* = .{};
}

ui_render_target_ensure_size :: (target: *UI_Render_Target, width: s32, height: s32) -> bool {
    if width <= 0 || height <= 0 return false;
    if target.framebuffer != 0 && target.width == width && target.height == height return true;

    ui_render_target_deinit(target);
    target.width = width;
    target.height = height;

    glGenTextures(1, *target.color_texture);
    glBindTexture(GL_TEXTURE_2D, target.color_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glGenRenderbuffers(1, *target.depth_renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, target.depth_renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, xx width, xx height);

    glGenFramebuffers(1, *target.framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, target.framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, target.color_texture, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, target.depth_renderbuffer);

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE {
        log_error("UI render target framebuffer is incomplete");
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        return false;
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return true;
}

ui_render_target_begin :: (target: *UI_Render_Target) -> bool {
    if target.framebuffer == 0 return false;

    glGetIntegerv(GL_FRAMEBUFFER_BINDING, *target.previous_framebuffer);
    glGetIntegerv(GL_VIEWPORT, target.previous_viewport.data);

    glBindFramebuffer(GL_FRAMEBUFFER, target.framebuffer);
    glViewport(0, 0, xx target.width, xx target.height);
    target.active = true;
    return true;
}

ui_render_target_end :: (target: *UI_Render_Target) {
    if !target.active return;

    glBindFramebuffer(GL_FRAMEBUFFER, xx target.previous_framebuffer);
    glViewport(
        target.previous_viewport[0],
        target.previous_viewport[1],
        xx target.previous_viewport[2],
        xx target.previous_viewport[3]
    );
    target.active = false;
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
    ascender := ctx.font.ascender_em;
    descender := ctx.font.descender_em;  // typically negative, e.g. -0.2
    text_height := (ascender - descender) * font_size;
    return rect.y + (rect.h - text_height) * 0.5 + ascender * font_size;
}

ui_text_centered_x :: (rect: UI_Rect, text: string, font_size: float32) -> float32 {
    text_w := msdf_measure_text_pixels(ui_ctx.font, text, font_size);
    return rect.x + (rect.w - text_w) * 0.5;
}


#load "widgets.jai";
