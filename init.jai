init_font :: () {
    the_font = Simp.get_font_at_size(".", "FiraCode-Retina.ttf", 16);
    assert(the_font != null);
    char_size.x = xx the_font.em_width;
    char_size.y = xx the_font.character_height;
    // line_height = xx the_font.character_height + the_font.default_line_spacing;
}

init_pointer_images :: () {
    using Pointer_Image;

    pointers[HAND] = XCreateFontCursor(x_global_display, 60);
    pointers[ARROW] = XCreateFontCursor(x_global_display, 2);
    pointers[SLIDE]= XCreateFontCursor(x_global_display, 96);
    pointers[CURSOR]= XCreateFontCursor(x_global_display, 152);
}