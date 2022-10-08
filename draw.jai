draw_rect :: (r: Rect, color: Vector4) {
    using r;
    Simp.set_shader_for_color();
    Simp.immediate_quad(x, y, x + w, y + h, color);
}

draw_button :: (x: float, y: float, width: float, height: float, color: Vector4, text: string) -> Rect { 
    button := make_rect(x, y, width, height);
    draw_rounded_rect(button, color, 4);

    // Label
    text_width := Simp.prepare_text(the_font, text);
    Simp.draw_text(the_font, xx (x + (width / 2) - text_width/2), xx (y + (height / 2) - 5), text);    

    return button;
}


draw_rounded_rect :: (rect: Rect, color: Vector4, radius: int) {
    top, bottom, left: Rect;
    r := rect;
    r, top = cut_top(xx radius, r);
    top.x += radius;
    top.w -= radius*2;
    r, bottom = cut_bottom(xx radius, r);
    bottom.x += radius;
    bottom.w -= radius*2;
    draw_rect(r, color);
    draw_rect(top, color);
    draw_rect(bottom, color);

    base: Vector2 = ---;
    points : [7]Vector2;

    // Top left corner
    base.x = top.x;
    base.y = top.y;
    k := float.[.5, .55, .65, .75, .85, .95, 1];
    for i : 0..6 {
        points[i].x = base.x + cos(PI * k[i])*radius;
        points[i].y = base.y + sin(PI * k[i])*radius;
    }
    Simp.immediate_triangle_fan(base, points, color); 

    // Top right corner
    base.x = top.x + top.w;
    for i : 0..6 {
        points[i].x = base.x + cos(PI * (k[i] - .5))*radius;
        points[i].y = base.y + sin(PI * (k[i] - .5))*radius;
    }
    Simp.immediate_triangle_fan(base, points, color); 

    // Bottom left corner
    base.x = bottom.x;
    base.y = bottom.y + bottom.h;
    for i : 0..6 {
        points[i].x = base.x + cos(PI * (k[i] + .5))*radius;
        points[i].y = base.y + sin(PI * (k[i] + .5))*radius;
    }
    Simp.immediate_triangle_fan(base, points, color); 

    // Bottom right corner
    base.x = bottom.x + bottom.w;
    for i : 0..6 {
        points[i].x = base.x + cos(PI*(k[i] - 1))*radius;
        points[i].y = base.y + sin(PI*(k[i] - 1))*radius;
    }
    Simp.immediate_triangle_fan(base, points, color);
    
}


draw_formatted_text :: (text: string, rect: Rect, color: Vector4, width: int = 0, scroll_top: int = 0) -> s64 {
    lines := split(text , "\n");
    k := 0; // to calculate height of text block
    for lines {
        w := width;
        l := it;
        if w == 0 then w = l.count;
        x_max := cast(int) (floor(cast(float) (l.count / w)));
        x := 0;
        while x <= x_max && l.count - w * x != 0 {
            b := copy_string(l);
            b.data += w * x;
            b.count = min(w, l.count - w * x);

            Simp.draw_text(the_font, xx (rect.x + 10), xx (rect.y + rect.h - 20 - k), b, color);

            k += cast(int) (char_size.y * 1.2);
            x += 1;
        }
        k += cast(int) (char_size.y * 1.2);
    }
    return k;
} 