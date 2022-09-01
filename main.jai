#import "Basic";
#import "Window_Creation";
#import "Math";
#import "X11";
Input :: #import "Input";
Simp :: #import "Simp";

#load "layout.jai";
#load "init.jai";
#load "draw.jai";
#load "unicode.jai";

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
color_input : Vector4 = .{0.59, 0.59, 0.62, 1};

the_font : *Simp.Dynamic_Font;

// Pointers
mouse_pointer: Vector2;
NUM_POINTERS :: #run enum_highest_value(Pointer_Image)+1;
Pointer_Image :: enum u16 {
    ARROW;
    HAND;
    SLIDE;
    CURSOR;
}
pointers: [NUM_POINTERS] Cursor;

Key_State :: enum u16 {
    REALISED;
    PRESSED;
    UNTOUCHED;

}

side_bar_w : float;
move_bar_grab : bool;
key_pressed : Key_State;
text_input: [..] u8;
input_focus : bool;

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
        key_pressed = .UNTOUCHED;
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

            if it.type == .TEXT_INPUT && input_focus {
                print("n is %\n", it);
                key, count := key_utf32_to_utf8(it.utf32);  
                print("kez %", key);
                for 0..count-1 {
                    array_add(*text_input, key[it]);
                }
            }
            if it.type == .KEYBOARD {
                print("n is %\n", it);
                if it.key_pressed == 0 {
                    key_pressed = .REALISED;
                    continue;
                }
                if it.key_pressed == 1 {
                    key_pressed = .PRESSED;
                }
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
        if left_click && key_pressed == .PRESSED {
            move_bar_grab = true;
        }
    }

    if left_click && move_bar_grab {
        side_bar_w = mouse_pointer.x;
    }
    if key_pressed == .REALISED && move_bar_grab {
        move_bar_grab = false;
    }

    // Draw button
    button := draw_button(xx (top_bar.x + 0.9 * top_bar.w), xx (top_bar.y + 0.2 * top_bar.h), 120, 40, color_button, "Send");

     // Draw text input
    c : Vector4;
    if input_focus {
        c = color_white;
    } else {
        c = color_input;
    }
    text_input_rect := draw_text_input(xx (top_bar.x + 0.4 * top_bar.w), xx (top_bar.y + 0.2 * top_bar.h), 520, 40, c);  

    // Check mouse pointer image
    input_focus = false;
    if mouse_pointer_is_within(button) {
        set_pointer_image(Pointer_Image.HAND);
    } else if mouse_pointer_is_within(move_bar) {
        set_pointer_image(Pointer_Image.SLIDE);
    } else if mouse_pointer_is_within(text_input_rect) {
        input_focus = true;
        set_pointer_image(Pointer_Image.CURSOR);
    } else {
        set_pointer_image(Pointer_Image.ARROW);
    }  

    text := tprint("Mouse position is: %", mouse_pointer);
    Simp.draw_text(the_font, xx top_bar.x, xx (0.5*top_bar.y), text);

    text = tprint("%", to_string(text_input));
    Simp.draw_text(the_font, xx (text_input_rect.x + 10), xx text_input_rect.y + 10, text, color_button);

    // Simp.immediate_flush();
    Simp.swap_buffers(the_window);
}

set_points :: (r: Rect, color: Vector4) {
    using r;
    Simp.set_shader_for_color();
    Simp.immediate_quad(x, y, x + w, y + h, color);
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