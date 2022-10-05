draw_rect :: (r: Rect, color: Vector4) {
    using r;
    Simp.set_shader_for_color();
    Simp.immediate_quad(x, y, x + w, y + h, color);
}

draw_button :: (x: float, y: float, width: float, height: float, color: Vector4, text: string) -> Rect { 
    button := make_rect(x, y, width, height);
    draw_rect(button, color);

    // Label
    text_width := Simp.prepare_text(the_font, text);
    Simp.draw_text(the_font, xx (x + (width / 2) - text_width/2), xx (y + (height / 2) - 5), text);    

    return button;
}


draw_formatted_text :: (text: string, rect: Rect, color: Vector4) -> s64 {
    lines := split(text , "\n");
    k := 0;
    for lines {
        Simp.draw_text(the_font, xx (rect.x + 10), xx (rect.y + rect.h - 20 - k), it, color);
        k += 20;
    }
    return k;
}