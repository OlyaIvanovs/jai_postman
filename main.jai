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

Rect :: struct {
    x, y: float;
    w, h: float;
}

// Colors
color_white : Vector4 = .{1, 1, 1, 1};
color_red : Vector4 = .{1, 0, 0, 1};
color_blue : Vector4 = .{0, 0, 1, 1};
color_1 : Vector4 = .{0.2, 0.3, 0.5, 1};
color_2 : Vector4 = .{0.2, 0.4, 0.4, 1};

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


main :: () {
    the_window = create_window(window_width, window_height, "MY POSTMAN", background_color_rgb =  float.[.55,.01,.9]);
    window_width, window_height = Simp.get_render_dimensions(the_window);

    Simp.set_render_target(the_window);

    init_font();
    init_pointer_images();

    quit : bool;
    while !quit {
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

    // Simp.immediate_begin();
    Simp.set_shader_for_color();

    rect := make_rect(xx window_width, xx window_height, 0, 0);
    set_points(rect, color_1);

     // Draw side bar
    w := window_width / 4;
    side_bar := make_rect(xx w, xx window_height, 0, 0);
    set_points(side_bar, color_2);

    // Draw top bar
    w = 3 * window_width / 4;
    h := window_height / 6;
    x := window_width / 4;
    y := 5 * window_height / 6;
    top_bar := make_rect(xx w, xx h, xx x, xx y);
    set_points(top_bar, color_blue);

    // Draw button
    x = window_width - 220;
    y = window_height - 150;
    button_color := color_red;
    button := make_rect(120, 40, xx x, xx y);

    if mouse_pointer_is_within(button) {
        set_pointer_image(Pointer_Image.HAND);
    } else {
        set_pointer_image(Pointer_Image.ARROW);
    }

    // Check if mouse click is over button
    if left_click && mouse_pointer_is_within(button) {
        button_color = color_white;
    }
    set_points(button, button_color);

    // Draw move bar
    w = 4;
    x = window_width / 4 - 2;
    move_bar := make_rect(xx w, xx window_height, xx x, 0);
    move_bar_color := color_white;

    // Check mouse position
    update_mouse_pointer();

    // Check if mouse pointer is within move_bar
    if mouse_pointer_is_within(move_bar) {
        move_bar_color = color_red;
        set_pointer_image(Pointer_Image.SLIDE);
    }
    set_points(move_bar, move_bar_color);

    text := sprint("Mouse position is: %", mouse_pointer);
    Simp.draw_text(the_font, xx top_bar.x, xx top_bar.y, text);

    // Simp.immediate_flush();
    Simp.swap_buffers(the_window);
}

init_font :: () {
    the_font = Simp.get_font_at_size(".", "OpenSans-BoldItalic.ttf", 40);
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

