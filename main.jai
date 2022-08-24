#import "Basic";
#import "Window_Creation";
Input :: #import "Input";
Simp :: #import "Simp";
#import "Math";
#import "X11";

// Window
window_width : s32 = 1920;
window_height : s32 = 1080;
the_window : Window_Type; 

screen : Rect;

Rect :: struct {
    x, y: float;
    w, h: float;
}

// Colors
color_white : Vector4 = .{1, 1, 1, 1};
color_red : Vector4 = .{1, 0, 0, 1};
color_blue : Vector4 = .{0, 0, 1, 1};
color_1 : Vector4 = .{0.33, 0.37, 0.41, 1};
color_2 : Vector4 = .{0.13, 0.15, 0.18, 1};
color_3 : Vector4 = .{0.176, 0.2, 0.23, 1};
color_button : Vector4 = .{0, 0.3, 0.4, 1};

the_font : *Simp.Dynamic_Font;

// Pointers
mouse_pointer: Vector2;
NUM_POINTERS :: #run enum_highest_value(Pointer_Image)+1;
Pointer_Image :: enum u16 {
    ARROW :: 0;  // Normal arrow for pointing at stuff, or whatever.
    HAND  :: 1; 
    SLIDE :: 2;

}
pointers: [NUM_POINTERS] Cursor;

side_bar_w : float;
move_bar_grab : bool;

main :: () {
    the_window = create_window(window_width, window_height, "MY POSTMAN", background_color_rgb =  float.[.55,.01,.9]);
    window_width, window_height = Simp.get_render_dimensions(the_window);

    Simp.set_render_target(the_window);

    init_font();
    init_pointer_images();
    set_pointer_image(Pointer_Image.ARROW);
    side_bar_w = xx (window_width / 5);
    

    quit : bool;
    while !quit {
        for Input.get_window_resizes() {
            Simp.update_window(it.window);
            window_width = it.width;
            window_height = it.height;
        }

        Input.update_window_events();

        for Input.events_this_frame {
            if it.type == .QUIT {
                quit = true;
            }

            if it.type == .KEYBOARD {
                print("n is %\n", it);
                if it.key_pressed == 0 continue;

                if it.key_code == .ESCAPE {
                    quit = true;
                }
            }
        }

        draw_one_frame();
        sleep_milliseconds(10);
        reset_temporary_storage();
    }

}

draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    // Events
    left_click := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];

    // Check mouse position
    update_mouse_pointer();

    // Simp.immediate_begin();
    Simp.set_shader_for_color();

    side_bar, top_bar, move_bar, bar, rect : Rect;
    screen = make_rect(xx window_width, xx window_height, 0, 0);
    rect, side_bar = cut_left(side_bar_w, screen);
    rect, top_bar = cut_top(xx (window_height / 6), rect);

    set_points(rect, color_1);
    set_points(side_bar, color_2);
    set_points(top_bar, color_3);

    // Draw move bar
    bar, move_bar = cut_right(5, side_bar);
    move_bar.x += 2; 
    move_bar_hover := expand_x(2, move_bar);
    if mouse_pointer_is_within(move_bar_hover) {
        set_points(move_bar, color_button);
        if left_click == .DOWN  {
            move_bar_grab = true;
        }
    }

    if left_click == .DOWN && move_bar_grab {
        side_bar_w = mouse_pointer.x;
    } else {
        move_bar_grab = false;
    }

    // Draw button
    button := draw_button(xx (top_bar.x + 0.9 * top_bar.w), xx (top_bar.y + 0.2 * top_bar.h), 120, 40, color_button, "Send");

    // Check mouse pointer image
    if mouse_pointer_is_within(button) {
        set_pointer_image(Pointer_Image.HAND);
    } else if mouse_pointer_is_within(move_bar) {
        set_pointer_image(Pointer_Image.SLIDE);
    } else {
        set_pointer_image(Pointer_Image.ARROW);
    }

    text := sprint("Mouse position is: %", mouse_pointer);
    Simp.draw_text(the_font, xx top_bar.x, xx top_bar.y, text);

    // Simp.immediate_flush();
    Simp.swap_buffers(the_window);
}

init_font :: () {
    the_font = Simp.get_font_at_size(".", "OpenSans-BoldItalic.ttf", 16);
    assert(the_font != null);
}

make_rect :: (width: float, height: float, x: float, y: float) -> Rect{
    rect : Rect;

    rect.w = width;
    rect.h = height;
    rect.x = x;
    rect.y = y;

    return rect;
}

set_points :: (r: Rect, color: Vector4) {
    using r;
    Simp.immediate_quad(x, y, x + w, y + h, color);
}

init_pointer_images :: () {
    using Pointer_Image;

    pointers[HAND] = XCreateFontCursor(x_global_display, 60);
    pointers[ARROW] = XCreateFontCursor(x_global_display, 2);
    pointers[SLIDE]= XCreateFontCursor(x_global_display, 96);
}

set_pointer_image :: (image: Pointer_Image) {
    // if !initted_pointers  init_pointers();

    if (image >= 0) && (image <= cast(Pointer_Image) NUM_POINTERS) {
        XDefineCursor(x_global_display, the_window, pointers[image]);
    } else {
        log_error("Invalid pointer index %\n", image);
    }
}

update_mouse_pointer :: () {
    x, y := get_mouse_pointer_position(the_window, true);
    mouse_pointer.x = xx x;
    mouse_pointer.y = xx y;
}

point_within :: (p: Vector2, r: Rect) -> bool {
    assert(r.w >= 0 && r.h >= 0);
    return r.x <= p.x && p.x <= r.x + r.w && r.y <= p.y && p.y <= r.y + r.h;
}

mouse_pointer_is_within :: (rect: Rect) -> bool {
    return point_within(mouse_pointer, rect);
}


draw_button :: (x: float, y: float, width: float, height: float, color: Vector4, text: string) -> Rect { 
    left_click := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];
    button := make_rect(width, height, x, y);
    
    // Check if mouse click is over button
    if left_click && mouse_pointer_is_within(button) {
        set_points(button, color_white);
    } else {
        set_points(button, color);
    }

    // Label
    text_width := Simp.prepare_text(the_font, text);
    Simp.draw_text(the_font, xx (x + (width / 2) - text_width/2), xx (y + (height / 2) - 5), text);    

    return button;
}


cut_left :: (cut: float, rect: Rect) -> (remainder: Rect, left: Rect) {
    remainder := rect;
    remainder.x += cut;
    remainder.w -= cut;

    left := rect;
    left.w = cut;

    return remainder, left;
}

cut_right :: (cut: float, rect: Rect) -> (remainder: Rect, right: Rect) {
    remainder := rect;
    remainder.w -= cut;

    right := rect;
    right.w = cut;
    right.x = rect.w - cut;

    return remainder, right;
}

cut_top :: (cut: float, rect: Rect) -> (remainder: Rect, top: Rect) {
    remainder := rect;
    remainder.h -= cut;

    top := rect;
    top.h = cut;
    top.y = rect.h - cut;

    return remainder, top;
}


expand_x :: (expand: float, rect: Rect) -> (r: Rect) {
    r := rect;
    r.x -= expand;
    r.w += expand * 2;

    return rect;
}