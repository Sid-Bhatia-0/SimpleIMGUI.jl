import ModernGL as MGL
import DataStructures as DS
import GLFW
import SimpleDraw as SD
import SimpleWidgets as SW

include("opengl_utils.jl")
include("widget_utils.jl")

mutable struct UserInteractionState <: SW.AbstractUserInteractionState
    hot_widget::SW.WidgetID
    active_widget::SW.WidgetID
    null_widget::SW.WidgetID
end

mutable struct UserInputState
    cursor::SW.Point
    key_escape::SW.InputButton
    key_up::SW.InputButton
    key_down::SW.InputButton
    key_left::SW.InputButton
    key_right::SW.InputButton
    mouse_left::SW.InputButton
    mouse_right::SW.InputButton
    mouse_middle::SW.InputButton
    characters::Vector{Char}
end

function reset!(user_input_state::UserInputState)
    user_input_state.key_escape = SW.reset(user_input_state.key_escape)
    user_input_state.key_up = SW.reset(user_input_state.key_up)
    user_input_state.key_down = SW.reset(user_input_state.key_down)
    user_input_state.key_left = SW.reset(user_input_state.key_left)
    user_input_state.key_right = SW.reset(user_input_state.key_right)
    user_input_state.mouse_left = SW.reset(user_input_state.mouse_left)
    user_input_state.mouse_right = SW.reset(user_input_state.mouse_right)
    user_input_state.mouse_middle = SW.reset(user_input_state.mouse_middle)
    empty!(user_input_state.characters)

    return nothing
end

function update_button(button, action)
    if action == GLFW.PRESS
        return SW.press_button(button)
    elseif action == GLFW.RELEASE
        return SW.release_button(button)
    else
        return button
    end
end

function start()
    height_image = 720
    width_image = 1280
    window_name = "Example"
    background_color = 0x00c0c0c0
    text_color = 0x00000000
    slider_color = 0x00ffffff
    sliding_window_size = 30
    font = SD.TERMINUS_32_16

    image = zeros(MGL.GLuint, height_image, width_image)

    SD.draw!(image, SD.Background(), background_color)

    i = 0

    time_stamp_buffer = DS.CircularBuffer{typeof(time_ns())}(sliding_window_size)
    push!(time_stamp_buffer, time_ns())

    compute_time_buffer = DS.CircularBuffer{typeof(time_ns())}(sliding_window_size)
    push!(compute_time_buffer, zero(UInt))

    user_interaction_state = SW.UserInteractionState(SW.NULL_WIDGET_ID, SW.NULL_WIDGET_ID, SW.NULL_WIDGET_ID)

    user_input_state = UserInputState(
                                      SW.Point(1, 1),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      SW.InputButton(false, 0),
                                      Char[],
                                     )

    slider = 1
    text_input = collect("Text box")

    setup_window_hints()
    window = GLFW.CreateWindow(width_image, height_image, window_name)
    GLFW.MakeContextCurrent(window)

    function cursor_position_callback(window, x, y)::Cvoid
        user_input_state.cursor = SW.Point(round(Int, y, RoundDown) + 1, round(Int, x, RoundDown) + 1)

        return nothing
    end

    function key_callback(window, key, scancode, action, mods)::Cvoid
        if key == GLFW.KEY_ESCAPE
            user_input_state.key_escape = update_button(user_input_state.key_escape, action)
        elseif key == GLFW.KEY_UP
            user_input_state.key_up = update_button(user_input_state.key_up, action)
        elseif key == GLFW.KEY_DOWN
            user_input_state.key_down = update_button(user_input_state.key_down, action)
        elseif key == GLFW.KEY_LEFT
            user_input_state.key_left = update_button(user_input_state.key_left, action)
        elseif key == GLFW.KEY_RIGHT
            user_input_state.key_right = update_button(user_input_state.key_right, action)
        elseif key == GLFW.KEY_BACKSPACE && (action == GLFW.PRESS || action == GLFW.REPEAT)
            push!(user_input_state.characters, '\b')
        end

        return nothing
    end

    function mouse_button_callback(window, button, action, mods)::Cvoid
        if button == GLFW.MOUSE_BUTTON_LEFT
            user_input_state.mouse_left = update_button(user_input_state.mouse_left, action)
        elseif button == GLFW.MOUSE_BUTTON_RIGHT
            user_input_state.mouse_right = update_button(user_input_state.mouse_right, action)
        elseif button == GLFW.MOUSE_BUTTON_MIDDLE
            user_input_state.mouse_middle = update_button(user_input_state.mouse_middle, action)
        end

        return nothing
    end

    function character_callback(window, unicode_codepoint)::Cvoid
        push!(user_input_state.characters, Char(unicode_codepoint))

        return nothing
    end

    GLFW.SetCursorPosCallback(window, cursor_position_callback)
    GLFW.SetKeyCallback(window, key_callback)
    GLFW.SetMouseButtonCallback(window, mouse_button_callback)
    GLFW.SetCharCallback(window, character_callback)

    MGL.glViewport(0, 0, width_image, height_image)

    vertex_shader = setup_vertex_shader()
    fragment_shader = setup_fragment_shader()
    shader_program = setup_shader_program(vertex_shader, fragment_shader)

    VAO_ref, VBO_ref, EBO_ref = setup_vao_vbo_ebo()

    texture_ref = setup_texture(image)

    MGL.glUseProgram(shader_program)
    MGL.glBindVertexArray(VAO_ref[])

    clear_display()

    while !GLFW.WindowShouldClose(window)
        if SW.went_down(user_input_state.key_escape)
            GLFW.SetWindowShouldClose(window, true)
            break
        end

        compute_time_start = time_ns()

        layout = SW.BoxLayout(SW.BoundingBox(1, 1, 0, 0))

        SD.draw!(image, SD.Background(), background_color)

        layout, button1 = SW.do_widget!(
                                image,
                                user_interaction_state,
                                user_input_state,
                                SW.BUTTON,
                                SW.WidgetID(@__LINE__, @__FILE__),
                                layout,
                                SW.VERTICAL,
                                32,
                                200,
                                "Button 1",
                                font,
                                text_color,
                               )

        layout, button2 = SW.do_widget!(
                                image,
                                user_interaction_state,
                                user_input_state,
                                SW.BUTTON,
                                SW.WidgetID(@__LINE__, @__FILE__),
                                layout,
                                SW.VERTICAL,
                                32,
                                200,
                                "Button 2",
                                font,
                                text_color,
                               )

        layout, slider = SW.do_widget!(
                                image,
                                user_interaction_state,
                                user_input_state,
                                SW.SLIDER,
                                SW.WidgetID(@__LINE__, @__FILE__),
                                slider,
                                layout,
                                SW.VERTICAL,
                                32,
                                200,
                                "Slider",
                                font,
                                text_color,
                                slider_color,
                               )

        layout, _ = SW.do_widget!(
                                image,
                                user_interaction_state,
                                user_input_state,
                                SW.TEXT_INPUT,
                                SW.WidgetID(@__LINE__, @__FILE__),
                                text_input,
                                layout,
                                SW.VERTICAL,
                                32,
                                200,
                                font,
                                text_color,
                               )

        text = "Press the escape key to quit"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "previous frame number: $(i)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "average total time spent per frame (averaged over previous $(length(time_stamp_buffer)) frames): $(round((last(time_stamp_buffer) - first(time_stamp_buffer)) / (1e6 * length(time_stamp_buffer)), digits = 2)) ms"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "average compute time spent per frame (averaged over previous $(length(compute_time_buffer)) frames): $(round(sum(compute_time_buffer) / (1e6 * length(compute_time_buffer)), digits = 2)) ms"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "cursor: $(user_input_state.cursor)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "mouse_left: $(user_input_state.mouse_left)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "mouse_right: $(user_input_state.mouse_right)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "mouse_middle: $(user_input_state.mouse_middle)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "hot_widget: $(user_interaction_state.hot_widget)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "active_widget: $(user_interaction_state.active_widget)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "button1: $(button1)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "button2: $(button2)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "slider: $(slider)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        text = "text_input: $(text_input)"
        layout, text_bounding_box = SW.add_widget(layout, SW.VERTICAL, SD.get_height(font), length(text))
        text_rectangle = convert(SD.Rectangle{Int}, text_bounding_box)
        SD.draw!(image, SD.TextLine(text_rectangle.position, text, font), text_color)

        compute_time_end = time_ns()
        push!(compute_time_buffer, compute_time_end - compute_time_start)

        update_back_buffer(image)

        GLFW.SwapBuffers(window)

        reset!(user_input_state)

        GLFW.PollEvents()

        i = i + 1

        push!(time_stamp_buffer, time_ns())
    end

    MGL.glDeleteVertexArrays(1, VAO_ref)
    MGL.glDeleteBuffers(1, VBO_ref)
    MGL.glDeleteBuffers(1, EBO_ref)
    MGL.glDeleteProgram(shader_program)

    GLFW.DestroyWindow(window)

    return nothing
end

start()
