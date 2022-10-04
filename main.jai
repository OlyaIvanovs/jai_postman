#import "Basic";
#import "File";
#import "String";
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
color_green : Vector4 = .{0, 0.49, 0.12, 1};
color_1 : Vector4 = .{0.33, 0.37, 0.41, 1};
color_2 : Vector4 = .{0.13, 0.15, 0.18, 1};
color_3 : Vector4 = .{0.176, 0.2, 0.23, 1};
color_button : Vector4 = .{0, 0.3, 0.4, 1};
color_button_hover : Vector4 = .{0, 0.35, 0.47, 1};
color_button_active : Vector4 = .{0, 0.39, 0.52, 1};
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

frame_time: float64;
request_input: Text_Input;
response_field: Response_Field;
ui_state : UI_State;
dropdown: Dropdown;

Text_Input :: struct {
    text: [..] u8;
    focused: bool;
    offset: s64;
    capacity: s64;

    cursor: struct {
        pos: s64;
        sel: s64;
        visible: bool;
        BLINKING_SPEED :: .4;
    };
}

Response_Field :: struct {
    show: bool;
    text: [..] u8;
    focused: bool;

    cursor: struct {
        pos: s64;
        sel: s64;
        visible: bool;
        BLINKING_SPEED :: .4;
    };
}

Dropdown :: struct {
    value: string;
    is_open: bool;
}

UI_State :: struct {
    mouse_x: s64;
    mouse_y: s64;
    mouse_down: bool;
    mouse_just_pressed: bool;
    mouse_just_released: bool;
    pointer_image: Pointer_Image;

    hot_item: int;
    active_item: int;
}

Request_Type :: enum {
        GET      :: 1;
        POST     :: 2;
        PUT      :: 3;
        PATCH    :: 4;
        DELETE   :: 5;
}




main :: () {
    the_window = create_window(window_width, window_height, "MY POSTMAN", background_color_rgb =  float.[.55,.01,.9]);
    window_width, window_height = Simp.get_render_dimensions(the_window);

    Simp.set_render_target(the_window);

    init_font();
    init_pointer_images();
    set_pointer_image(Pointer_Image.ARROW);

    quit : bool;
    while !quit {
        Input.update_window_events();

        ui_state.mouse_down = key_state(.MOUSE_BUTTON_LEFT) & .DOWN != 0;
        ui_state.mouse_just_pressed = key_state(.MOUSE_BUTTON_LEFT) & .START != 0;
        ui_state.mouse_just_released = key_state(.MOUSE_BUTTON_LEFT) & .END != 0;

        frame_time = get_time();
        
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
        }

        draw_one_frame();

        // ui_state.hot_last_frame =
        ui_state.hot_item = 0;
        ui_state.active_item = 0;
        ui_state.pointer_image = 0;

        sleep_milliseconds(10);
        reset_temporary_storage();
    }

}

request_input_process_event :: (event: Input.Event) -> processed: bool {
    text   := *request_input.text;
    cursor := *request_input.cursor;

    if event.type == .TEXT_INPUT {

        if cursor.sel != cursor.pos && cursor.pos > 0 && cursor.sel > 0 {
            array_remove_by_range(text, min(cursor.pos, cursor.sel), abs(cursor.pos - cursor.sel));
            cursor.pos = min(cursor.pos,cursor.sel);
            cursor.sel = cursor.pos;
        }

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

        if event.key_pressed {
            cursor.visible = true;
            if event.key_code == {
                case .BACKSPACE; 
                    if cursor.pos < 0 || text.count <= 0 then return true;

                    if cursor.pos == cursor.sel && cursor.pos > 0 {
                        array_remove_by_range(text, cursor.pos-1, 1);
                        cursor.pos -= 1;
                    } else {
                        array_remove_by_range(text, min(cursor.pos, cursor.sel), abs(cursor.pos - cursor.sel));
                        cursor.pos = min(cursor.pos,cursor.sel);
                    } 
                    if cursor.pos < 0 then cursor.pos = 0;
                    cursor.sel = cursor.pos;

                case .ARROW_LEFT;
                    if event.shift_pressed {
                        cursor.pos -= 1;
                        if cursor.pos < 0 then cursor.pos = 0;
                    } else {
                        if cursor.pos == cursor.sel {
                            cursor.pos -= 1;
                        } else {
                            cursor.pos = min(cursor.sel, cursor.pos);
                        }
                        if cursor.pos < 0 then cursor.pos = 0;
                        cursor.sel = cursor.pos;
                    }                
                case .ARROW_RIGHT;
                    if cursor.pos >= text.count then return true;
                    if event.shift_pressed {
                        cursor.pos += 1; // move only cursor.pos
                    } else {
                        if cursor.pos == cursor.sel {
                            cursor.pos += 1;
                        } else {
                            cursor.pos = max(cursor.sel, cursor.pos);
                        }
                        cursor.sel = cursor.pos;
                    }
                case; 
                    return false;
            }
            return true;
        }
    }

    return false;
}

draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    // Check mouse position
    update_mouse_pointer();

    Simp.set_shader_for_color();

    side_bar, side_bar_header, side_bar_scroll, side_bar_scroll_q, top_bar, move_bar, bar, rect : Rect;
    screen = make_rect(0, 0, xx window_width, xx window_height);
    rect, side_bar = cut_left(xx (window_width / 5), screen);
    side_bar, side_bar_header = cut_top(side_bar.h / 10, side_bar);
    side_bar, side_bar_scroll = cut_right(side_bar.w / 30, side_bar);
    side_bar_scroll, side_bar_scroll_q = cut_top(side_bar_scroll.h / 30, side_bar_scroll);
    rect, top_bar = cut_top(xx (window_height / 6), rect);

    draw_rect(rect, color_1);
    draw_rect(side_bar, color_2);
    draw_rect(side_bar_header, color_2);
    draw_rect(side_bar_scroll, color_green);
    draw_rect(side_bar_scroll_q, color_orange);
    draw_rect(top_bar, color_3);

    // Sidebar text
    t := tprint("Requests:");
    Simp.draw_text(the_font, xx (side_bar_header.x + 10), xx (side_bar_header.y + side_bar_header.h * 0.3), t, color_orange);
    text_from_file := read_entire_file("history.txt");
    draw_formatted_text(text_from_file, shrink(10, side_bar), color_orange);


    // Draw move bar
    bar, move_bar = cut_right(5, side_bar);
    move_bar.x += 2; 
    move_bar_hover := expand_x(2, move_bar);
    // TODO move move bar!!!!

    // Draw buttons 
    set_button(132, (top_bar.x + 0.9 * top_bar.w), (top_bar.y + 0.7 * top_bar.h), 120, 40, color_orange, "Clear");
    set_button(122, (top_bar.x + 0.9 * top_bar.w), (top_bar.y + 0.2 * top_bar.h), 120, 40, color_button, "Send");

    // Read from file by clicking on button 'Send'
    if ui_state.active_item == 122 {
        response_field.show = true;
        f, success := file_open("history.txt", for_writing = true, keep_existing_content=true);
        if !success {
            print("Could not write to file history.txt.\n");
            return;
        }
        advance :=  file_length(f); // advance the file pointer to ensure we append to the file instead of overwrite!
        file_set_position(f, advance);
        s := "new line \n";
        file_write(*f, s);
        file_close(*f);
    }


    // Draw text input
    {
        using request_input;

        text_input_rect := make_rect(top_bar.x + 0.4 * top_bar.w, top_bar.y + 0.2 * top_bar.h, 520, 40);
        request_input.capacity = cast(int) ((text_input_rect.w - 20) / char_size.x);

        // Calulate offset
        cursor_min := offset;
        cursor_max := offset + capacity;
        if cursor.pos < cursor_min {
            offset = cursor.pos;
        }
        if cursor.pos > cursor_max {
            offset += cursor.pos - cursor_max;
        }

        if mouse_left_just_pressed() {
            if mouse_pointer_is_within(text_input_rect) {
                request_input.focused = true;
            } else {
                request_input.focused = false;
            }
        }
        color := ifx request_input.focused then color_white else color_input;
        draw_rect(text_input_rect, color);

        // Cursor animation
        num_frame := cast(int) (frame_time / request_input.cursor.BLINKING_SPEED);
        cursor_show := num_frame % 2 == 0;

        // Draw selection
        if cursor.pos != cursor.sel {
            selection := shrink(5, text_input_rect);
            selection.x += (cursor.pos - offset) * char_size.x + 5;
            selection.w = (clamp(cursor.sel, cursor_min, cursor_max) - cursor.pos) * char_size.x;
            draw_rect(selection, color_selection);
        }

        // Draw cursor
        if focused && (cursor.visible || cursor_show) {
            text_cursor_rect: Rect = ---;
            x := text_input_rect.x + 10 + char_size.x * (cursor.pos - request_input.offset); 
            text_cursor_rect.x =  x;
            text_cursor_rect.y = text_input_rect.y + 5;
            text_cursor_rect.w = 2;
            text_cursor_rect.h = text_input_rect.h - 10;
            draw_rect(text_cursor_rect, color_button);
        }

        // TEXT
        visible_text := slice(to_string(text), request_input.offset, request_input.capacity); 
        Simp.draw_text(the_font, xx (text_input_rect.x + 10), xx text_input_rect.y + 10, visible_text, color_button);
    }


    // Draw response field
    {
        text_input_rect := make_rect(rect.x + 0.1 * rect.w, rect.y + 0.1 * rect.h, 0.8 * rect.w, 0.8 * rect.h);
        draw_rect(text_input_rect, color_input);

        // Read from file by clicking on button 'Send'
        if response_field.show {
            text_from_file := read_entire_file("text.txt");
            draw_formatted_text(text_from_file, text_input_rect, color_button);
        }

        t := tprint("Status: 200 OK");
        Simp.draw_text(the_font, xx (text_input_rect.x + 10), xx text_input_rect.y + 10, t, color_green);
    } 

    // Dropdown: Request type
    {
        request_types :: Request_Type.[.GET, .POST, .PUT, .PATCH, .DELETE];
        val := tprint("%", dropdown.value);
        if val == "" then val = "GET";

        if dropdown.is_open {
            set_button(142, (top_bar.x + 0.3 * top_bar.w), (top_bar.y + 0.2 * top_bar.h), 120, 40, color_orange, val);
            drop:Rect = ---;
            drop.x = top_bar.x + 0.3 * top_bar.w;
            drop.y = (top_bar.y + 0.2 * top_bar.h) - 150;
            drop.w = 120;
            drop.h = 150;
            draw_rect(drop, color_red);

            diff := 0;      
            for request_types {
                d := drop;
                d.y += diff;
                d.h = 30;
                if mouse_pointer_is_within(d) && ui_state.mouse_just_pressed {
                    dropdown.value = copy_string(tprint("%", it));
                    draw_rect(d, color_green);
                } else if mouse_pointer_is_within(d) || tprint("%", it) == val {
                    draw_rect(d, color_orange);
                } 
                    
                Simp.draw_text(the_font, xx (d.x + 5), xx (d.y + (d.h / 2) ), tprint("%", it));  
                diff += 30;        
            } 
        } else {
            set_button(142, (top_bar.x + 0.3 * top_bar.w), (top_bar.y + 0.2 * top_bar.h), 120, 40, color_orange, val);
        }

        if ui_state.active_item == 142 {
            dropdown.is_open = true;
        }
    }

    // Draw pointer
    if ui_state.pointer_image == 0 {
        set_pointer_image(Pointer_Image.ARROW);
    }

/*         Check mouse pointer image
    if mouse_pointer_is_within(move_bar) {
        set_pointer_image(Pointer_Image.SLIDE);
    } else if mouse_pointer_is_within(text_input_rect) {
        input_focus = true;
        set_pointer_image(Pointer_Image.CURSOR); */

    // Simp.immediate_flush();
    Simp.swap_buffers(the_window);
}



set_button :: (id: int, x: float, y: float, w: float, h: float, color: Vector4, label: string) {
    
    button:Rect = ---; 
    button.x = x;
    button.y = y;
    button.w = w;
    button.h = h;

    if mouse_pointer_is_within(button) {
        set_pointer_image(Pointer_Image.HAND);
        ui_state.pointer_image = Pointer_Image.HAND;
        ui_state.hot_item = id;
        if ui_state.active_item == 0 && (ui_state.mouse_down || ui_state.mouse_just_pressed) {
            ui_state.active_item = id;
        }
    } 

    if ui_state.active_item == id {
        button = draw_button(xx x, xx y, w, h, color_button_active, label);
    } else if ui_state.hot_item == id {
        button = draw_button(xx x, xx y, w, h, color_button_hover, label);
    } else {
        button = draw_button(xx x, xx y, w, h, color, label);
    }
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

array_remove_by_range :: (array_pointer: *[..] $T, index: s64, len: s64) {
    assert(index >= 0);
    assert(index < array_pointer.count);
    if len < 0 return;

    memcpy(array_pointer.data+index, array_pointer.data+index+len, (array_pointer.count - index - len));
    array_pointer.count -= len;
}