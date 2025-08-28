-- # DASHOU'S ITEM MANAGER

-- ## Window utilities

-- Contains most functions that are used to make windows on the
-- terminal.

local window_utils = {}

local utils = require("lib/utils")

-- Returns a centered window for a pop taking half the screen.
function window_utils.centered_window(title, strings, width, height, bg_color, border_color, padding, visible)
    local x_max,y_max = term.getSize()
    local padded_width = math.floor(width - padding)
    local padded_height = math.floor(height - padding)
    local x = math.floor((x_max - width*1.5))
    local y = math.floor((y_max - height*1.5))
    local screen = term.current()
    local popup = window.create(screen,x,y,width,height, visible)

    -- Clearing the total area
    popup.setBackgroundColour(bg_color)
    popup.setTextColour(term.getTextColor())
    popup.clear()

    -- Drawing the box and border
    paintutils.drawFilledBox(
        x,
        y,
        math.floor(width*1.5),
        math.floor(height*1.5),
        bg_color
    )

    paintutils.drawBox(
        x,
        y,
        math.floor(width*1.5),
        math.floor(height*1.5),
        border_color
    )

    -- Creating the text area
    popup = window.create(
        screen,
        x+padding,
        y+padding,
        math.floor(padded_width),
        math.floor(padded_height)
    )

    popup.setBackgroundColour(bg_color)
    popup.setTextColour(term.getTextColour())
    popup.clear()

    term.redirect(popup)

    -- Inserting the text in the text area.
    popup.setCursorPos(1,1)
    
    utils.print_centered(title)
    utils.print_centered(string.rep("=", string.len(title)))
    print()

    for _,s in ipairs(strings) do
        print(s)
    end

    return popup
end

-- Returns a centered window for a pop taking half the screen.
function window_utils.centered_window_choice(custom_w, option1, option2)
    term.redirect(custom_w)
    local x,_ = custom_w.getSize()
    return utils.choice(option1, option2, math.floor(x/4))
end

return window_utils