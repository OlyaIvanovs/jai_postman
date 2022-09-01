make_rect :: (width: float, height: float, x: float, y: float) -> Rect{
    rect : Rect;

    rect.w = width;
    rect.h = height;
    rect.x = x;
    rect.y = y;

    return rect;
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
