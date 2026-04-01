An immediate-mode UI system where widgets are declared via function calls every frame rather than stored as persistent objects.

Renders using two OpenGL backends: one for colored rectangles (Absolute_Position_Color_Alpha_Renderer) and one for text (MSDF text renderer).
If there is a request, then it can be renderer agnostic, it already has most of the infra for that.

usage:
  1. ui_begin_frame()   feed in mouse/keyboard/timing, reset per-frame state
  2. call widgets       ui_button(), ui_slider(), etc. each allocate layout space, hit-test the mouse, and emit draw commands
  3. ui_end_frame()     resolve interactions, draw tooltips, flush all accumulated draw commands to OpenGL

a ui element can be one of: 
    hot (hovered), 
    active (being clicked/dragged), 
    focused (receives keyboard input). 

Only one widget can hold each role at a time.

identity:
  Every widget gets a 64-bit ID via FNV-1a hash of its label, seeded by
  an ID stack so identically-labeled widgets in different scopes don't collide.

layout:
  A stack of layout regions, each either VERTICAL (top-to-bottom) or
  HORIZONTAL (left-to-right). ui_allocate_rect() consumes space from the
  current layout and advances its cursor. Nested layouts enable windows,
  panels, scroll regions, and row groupings.

draw commands:
  Widgets don't render directly instead they push commands (geometry, text,
  scissor push/pop) into a buffer. At frame end, the buffer is walked
  in order: geometry is sent through the rect renderer as arbitrary
  indexed triangles, text goes through the MSDF renderer, and scissor
  commands map to glScissor calls.

persisted state:
  Window positions/scroll/collapse and text-input buffers/cursors survive
  across frames in hash tables keyed by widget ID.

style:
  All colors, sizes, spacing, and timing are in one UI_Style struct.
  ui_default_style() provides a dark theme.

coordinates:
  Pixel-space, top-left origin, Y-down. Converted to OpenGL NDC only at render time.
