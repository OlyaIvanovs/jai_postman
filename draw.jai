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

draw_text_input :: (x: float, y: float, width: float, height: float, color: Vector4) -> Rect { 
    left_click := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];
    input := make_rect(width, height, x, y);
    set_points(input, color);

    return input;
}