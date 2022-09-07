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
color_selection : Vector4 = .{.14, .55, .69, 1};
color_orange : Vector4 = .{.65, .45, .19, 1};

the_font : *Simp.Dynamic_Font;
char_size: Vector2;

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

frame_time: float64;

request_input: Text_Input;

Text_Input :: struct {
    text: [..] u8;
    focused: bool;

    cursor: struct {
        pos: s64;
        sel: s64;
        visible: bool;
        BLINKING_SPEED :: .4;
    };
}


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
        Input.update_window_events();

        frame_time = get_time();

        key_pressed = .UNTOUCHED;
        for Input.get_window_resizes() {
            Simp.update_window(it.window);
            window_width = it.width;
            window_height = it.height;
        }

        for Input.events_this_frame {
            if it.type == .QUIT {
                quit = true;
            }

            if request_input.focused {
                processed := request_input_process_event(it);
                if processed continue;
            } 

            // if it.type == .KEYBOARD && it.key_pressed then quit = true;
        }

        draw_one_frame();
        sleep_milliseconds(10);
        reset_temporary_storage();
    }

}

request_input_process_event :: (event: Input.Event) -> processed: bool {
    text   := *request_input.text;
    cursor := *request_input.cursor;

    if event.type == .TEXT_INPUT {
        key, count := key_utf32_to_utf8(event.utf32);  
        if key[0] == 127 return true; // DEL bug
        assert(count == 1);  // only ASCII for simplicity now
        array_insert_at(text, key[0], cursor.pos);
        // for 0..count-1 {
        //     array_add(text, key[it]);  // TODO: write a function to add array into array
        // }
        cursor.pos += 1;
        cursor.sel += 1;
        return true;
    }

    cursor.visible = false;
    if event.type == .KEYBOARD {
        // print("EVENT %\n", event);

        if event.key_pressed {
            cursor.visible = true;
            if event.key_code == {
                case .BACKSPACE; 
                    text.count -= 1;
                    cursor.pos -= 1;
                    text.count = max(text.count, 0);

                case .ARROW_LEFT;
                    if event.shift_pressed {
                        cursor.pos -= 1;
                    } else {
                        if cursor.pos < cursor.sel {
                            cursor.pos -= 1;
                            cursor.sel = cursor.pos;
                        } else {
                            cursor.sel -= 1;
                            cursor.pos = cursor.sel;
                        }
                    }
                
                case .ARROW_RIGHT;
                    if event.shift_pressed {
                        cursor.pos += 1;
                    } else {
                        if cursor.pos > cursor.sel {
                            cursor.pos += 1;
                            cursor.sel = cursor.pos;
                        } else {
                            cursor.sel += 1;
                            cursor.pos = cursor.sel;
                        }
                    }

                case; 
                    return false;
            }

            cursor.pos = clamp(cursor.pos, 0, text.count);
            cursor.sel = clamp(cursor.sel, 0, text.count);
            return true;
        }
    }

    return false;
}

draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    // Events
    left_click := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];

    // Check mouse position
    update_mouse_pointer();

    Simp.set_shader_for_color();

    side_bar, top_bar, move_bar, bar, rect : Rect;
    screen = make_rect(0, 0, xx window_width, xx window_height);
    rect, side_bar = cut_left(side_bar_w, screen);
    rect, top_bar = cut_top(xx (window_height / 6), rect);

    draw_rect(rect, color_1);
    draw_rect(side_bar, color_2);
    draw_rect(top_bar, color_3);

    // TEXT
    t := tprint("Requests:");

    // Draw text
    Simp.draw_text(the_font, xx (side_bar.x + 10), xx (0.95 * side_bar.h), t, color_orange);

    // Draw move bar
    bar, move_bar = cut_right(5, side_bar);
    move_bar.x += 2; 
    move_bar_hover := expand_x(2, move_bar);

    // !!!!!!!!!!!!!!!!!
    // if mouse_pointer_is_within(move_bar_hover) {
    //     draw_rect(move_bar, color_button);
    //     if left_click && key_pressed == .PRESSED {
    //         move_bar_grab = true;
    //     }
    // }

    // if left_click && move_bar_grab {
    //     side_bar_w = mouse_pointer.x;
    // }
    // if key_pressed == .REALISED && move_bar_grab {
    //     move_bar_grab = false;
    // }

    // Draw button
    button := draw_button(xx (top_bar.x + 0.9 * top_bar.w), xx (top_bar.y + 0.2 * top_bar.h), 120, 40, color_button, "Send");

    request_type := draw_button(xx (top_bar.x + 0.3 * top_bar.w), xx (top_bar.y + 0.2 * top_bar.h), 120, 40, color_orange, "GET");

    // Draw text input
    {
        text_input_rect := make_rect(top_bar.x + 0.4 * top_bar.w, top_bar.y + 0.2 * top_bar.h, 520, 40);
        if mouse_pointer_is_within(text_input_rect) && mouse_left_just_pressed() {
            request_input.focused = true;
        }
        color := ifx request_input.focused then color_white else color_input;
        draw_rect(text_input_rect, color);

        // Cursor animation
        num_frame := cast(int) (frame_time / request_input.cursor.BLINKING_SPEED);
        cursor_show := num_frame % 2 == 0;

        // Draw selection
        using request_input;
        if cursor.pos != cursor.sel {
            text_select_rect: Rect = ---;
            x := ifx cursor.sel < cursor.pos then cursor.sel else cursor.pos
            text_select_rect.x =  text_input_rect.x + 10 + char_size.x * x; // end text
            text_select_rect.y = text_input_rect.y + 5;
            text_select_rect.w = abs(cursor.sel - cursor.pos) * char_size.x;
            text_select_rect.h = text_input_rect.h - 10;
            draw_rect(text_select_rect, color_selection);
        }

        // Draw cursor
        if request_input.focused && (cursor.visible || cursor_show) {
            text_cursor_rect: Rect = ---;
            text_cursor_rect.x =  text_input_rect.x + 10 + char_size.x * request_input.cursor.pos; // end text
            text_cursor_rect.y = text_input_rect.y + 5;
            text_cursor_rect.w = 2;
            text_cursor_rect.h = text_input_rect.h - 10;
            draw_rect(text_cursor_rect, color_button);
        }

        // TEXT
        t := tprint("%", to_string(request_input.text));

        // Draw text
        Simp.draw_text(the_font, xx (text_input_rect.x + 10), xx text_input_rect.y + 10, t, color_button);
    }


    // Draw response field
    {
        text_input_rect := make_rect(rect.x + 0.1 * rect.w, rect.y + 0.1 * rect.h, 0.8 * rect.w, 0.8 * rect.h);
        draw_rect(text_input_rect, color_input);

        // TEXT
        t := tprint("Status: 200 OK");

        // Draw text
        Simp.draw_text(the_font, xx (text_input_rect.x + 10), xx text_input_rect.y + 10, t, color_button);
    }

    // Check mouse pointer image
    if mouse_pointer_is_within(button) {
        set_pointer_image(Pointer_Image.HAND);
    } else if mouse_pointer_is_within(move_bar) {
        set_pointer_image(Pointer_Image.SLIDE);
    // } else if mouse_pointer_is_within(text_input_rect) {
    //     input_focus = true;
    //     set_pointer_image(Pointer_Image.CURSOR);
    } else {
        set_pointer_image(Pointer_Image.ARROW);
    }  

    // Simp.immediate_flush();
    Simp.swap_buffers(the_window);
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

key_state :: inline (key: Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[key];
}

mouse_left_just_pressed :: inline () -> bool {
    return key_state(.MOUSE_BUTTON_LEFT) & .START != 0;
}

mouse_left_just_released :: inline () -> bool {
    return key_state(.MOUSE_BUTTON_LEFT) & .END != 0;
}

mouse_left_is_down :: inline () -> bool {
    return key_state(.MOUSE_BUTTON_LEFT) & .DOWN != 0;
}