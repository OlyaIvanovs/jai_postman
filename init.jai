init_font :: () {
    the_font = Simp.get_font_at_size(".", "OpenSans-BoldItalic.ttf", 16);
    assert(the_font != null);
}

init_pointer_images :: () {
    using Pointer_Image;

    pointers[HAND] = XCreateFontCursor(x_global_display, 60);
    pointers[ARROW] = XCreateFontCursor(x_global_display, 2);
    pointers[SLIDE]= XCreateFontCursor(x_global_display, 96);
    pointers[CURSOR]= XCreateFontCursor(x_global_display, 152);
}