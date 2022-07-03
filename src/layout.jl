abstract type AbstractLayout end

mutable struct BoxLayout <: AbstractLayout
    bounding_box::SD.Rectangle{Int}
    padding::Int
end

abstract type AbstractDirection end

struct Vertical <: AbstractDirection end
const VERTICAL = Vertical()

struct Horizontal <: AbstractDirection end
const HORIZONTAL = Horizontal()

@enum Alignment begin
    TOP_LEFT
    MIDDLE_LEFT
    BOTTOM_LEFT
    TOP_MIDDLE
    CENTER
    BOTTOM_MIDDLE
    TOP_RIGHT
    MIDDLE_RIGHT
    BOTTOM_RIGHT
end

function get_alignment_offset(total_height, total_width, content_height, content_width, alignment)
    I = typeof(total_height)

    if alignment == TOP_LEFT
        return (zero(I), zero(I))
    elseif alignment == MIDDLE_LEFT
        return (convert(I, (total_height - content_height) ÷ 2), zero(I))
    elseif alignment == BOTTOM_LEFT
        return (convert(I, (total_height - content_height)), zero(I))
    elseif alignment == TOP_MIDDLE
        return (zero(I), convert(I, (total_width - content_width) ÷ 2))
    elseif alignment == CENTER
        return (convert(I, (total_height - content_height) ÷ 2), convert(I, (total_width - content_width) ÷ 2))
    elseif alignment == BOTTOM_MIDDLE
        return (convert(I, (total_height - content_height)), convert(I, (total_width - content_width) ÷ 2))
    elseif alignment == TOP_RIGHT
        return (zero(I), convert(I, total_width - content_width))
    elseif alignment == MIDDLE_RIGHT
        return (convert(I, (total_height - content_height) ÷ 2), convert(I, total_width - content_width))
    else
        return (convert(I, total_height - content_height), convert(I, total_width - content_width))
    end
end

function get_bounding_box(shapes...)
    shape1 = shapes[1]
    i_min = SD.get_i_min(shape1)
    j_min = SD.get_j_min(shape1)
    i_max = SD.get_i_max(shape1)
    j_max = SD.get_j_max(shape1)

    for shape in shapes
        i_min = min(i_min, SD.get_i_min(shape))
        j_min = min(j_min, SD.get_j_min(shape))
        i_max = max(i_max, SD.get_i_max(shape))
        j_max = max(j_max, SD.get_j_max(shape))
    end

    return SD.Rectangle(SD.Point(i_min, j_min), i_max - i_min + one(i_min), j_max - j_min + one(j_min))
end

function get_next_widget_position(layout::BoxLayout, ::Vertical)
    i_max = SD.get_i_max(layout.bounding_box)
    return SD.Point(i_max + one(i_max), SD.get_j_min(layout.bounding_box) + layout.padding)
end

function get_next_widget_position(layout::BoxLayout, ::Horizontal)
    j_max = SD.get_j_max(layout.bounding_box)
    return SD.Point(SD.get_i_min(layout.bounding_box) + layout.padding, j_max + one(j_max))
end

function get_next_widget_bounding_box(layout::BoxLayout, direction::AbstractDirection, height, width)
    position = get_next_widget_position(layout, direction)
    return SD.Rectangle(position, height, width)
end

function add_widget!(layout::BoxLayout, direction::Vertical, bounding_box::SD.Rectangle)
    layout.bounding_box = SD.Rectangle(
                                       layout.bounding_box.position,
                                       layout.bounding_box.height + bounding_box.height + layout.padding,
                                       max(layout.bounding_box.width, bounding_box.width + oftype(layout.padding, 2)),
                                      )
    return bounding_box
end

function add_widget!(layout::BoxLayout, direction::Horizontal, bounding_box::SD.Rectangle)
    layout.bounding_box = SD.Rectangle(
                                       layout.bounding_box.position,
                                       max(layout.bounding_box.height, bounding_box.height + oftype(layout.padding, 2)),
                                       layout.bounding_box.width + bounding_box.width + layout.padding,
                                      )
    return bounding_box
end

function add_widget!(layout::BoxLayout, direction::AbstractDirection, height, width)
    bounding_box = get_next_widget_bounding_box(layout, direction, height, width)
    add_widget!(layout, direction, bounding_box)
    return bounding_box
end
