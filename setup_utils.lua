-- # DASHOU'S ITEM MANAGER

-- ## Utilities

-- Contains most functions and variables that are used in the
-- different projects files. This is not a file to be touched by
-- the user.

local constants = require("dim/lib/constants")

local ERROR = constants.LOGTYPE_ERROR
local INFO = constants.LOGTYPE_INFO
local DEBUG = constants.LOGTYPE_DEBUG

local utils = {}

local PAGED_TABULATE_MESSAGE = "Press any key for next page of results..."

-- Ternary operator implementation (Thanks Lua)
function utils.fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

function utils.print_centered(text, bg_colour, text_colour)
    local cur_bg_colour = term.getBackgroundColour()
    local cur_text_colour = term.getTextColour()

    if bg_colour == nil then bg_colour = term.getBackgroundColour() end
    if text_colour == nil then text_colour = term.getTextColour() end
    
    local max_x, _ = term.getSize()
    local _, current_y = term.getCursorPos()
    local x_mid = math.floor(max_x/2)
    local x_start = x_mid - math.floor(string.len(text)/2)
    term.setCursorPos(x_start, current_y)
    term.setBackgroundColor(bg_colour)
    term.setTextColor(text_colour)
    print(text)
    term.setBackgroundColor(cur_bg_colour)
    term.setTextColor(cur_text_colour)
end

function utils.print_align_left(text, bg_colour, text_colour, margin)
    local cur_bg_colour = term.getBackgroundColour()
    local cur_text_colour = term.getTextColour()

    if not bg_colour then bg_colour = term.getBackgroundColour() end
    if not text_colour then text_colour = term.getTextColour() end
    
    local max_x, _ = term.getSize()
    local _, current_y = term.getCursorPos()

    if not margin then margin = math.floor(max_x/6) end
    local x_start = margin

    term.setCursorPos(x_start, current_y)
    term.setBackgroundColor(bg_colour)
    term.setTextColor(text_colour)
    print(text)
    term.setBackgroundColor(cur_bg_colour)
    term.setTextColor(cur_text_colour)
end

-- Clears terminal and sets cursor pos to 1,1
function utils.reset_terminal(bg_colour, text_colour)
    if not bg_colour then bg_colour = term.getBackgroundColour() end
    if not text_colour then text_colour = term.getTextColour() end
    term.setBackgroundColour(bg_colour)
    term.setTextColour(text_colour)
    term.clear()
    term.setCursorPos(1,1)
end

local function switchTo(bgColor, textColor) 
    term.setTextColor(textColor)
    term.setBackgroundColor(bgColor)
end

-- Presents the user with a choice.
-- <first[string]> Text in the first choice
-- <second[string]> Text in the second choice.
function utils.choice(first,second, startsOn)
    if not startsOn then startsOn = 1 end
    print()
    print()
    local choice = startsOn
    local x,_ = term.getSize()
    local _,y = term.getCursorPos()

    while true do
        local cur = term.getBackgroundColour()
        term.setBackgroundColour(cur)

        term.setCursorPos(1,y-1)
        term.clearLine()

        term.setCursorPos(1,y)
        term.clearLine()

        term.setCursorPos(1,y+1)
        term.clearLine()
        
        -- how many chars inbetween options
        local spacing = 15

        local middle_pos = math.floor(x/2)
        local start_f = middle_pos - (math.floor(string.len(first)/2)) - spacing
        local start_s = middle_pos - (math.floor(string.len(second)/2)) + spacing
        
        if choice == 1 then
            switchTo(colours.white, colours.blue)
            term.setCursorPos(start_f-1, y-1)
            write(string.rep(" ",string.len(first)+2))
            term.setCursorPos(start_f-1, y)
            write("<"..first..">")
            term.setCursorPos(start_f-1, y+1)
            write(string.rep(" ",string.len(first)+2))
            term.setCursorPos(start_s, y)
            switchTo(colours.blue, colours.white)
            write(second)
        else
            term.setCursorPos(start_f, y)
            switchTo(colours.blue, colours.white)
            write(first)
            switchTo(colours.white, colours.blue)
            term.setCursorPos(start_s-1, y-1)
            write(string.rep(" ",string.len(second)+2))
            term.setCursorPos(start_s-1, y)
            write("<"..second..">")
            term.setCursorPos(start_s-1, y+1)
            write(string.rep(" ",string.len(second)+2))
            switchTo(colours.blue, colours.white)
        end

        local _, key, _ = os.pullEvent("key")
        local pressed = keys.getName(key)

        if pressed == "left" then
            choice = utils.fif(choice == 1, 2, 1)
        elseif pressed == "right" then
            choice = utils.fif(choice == 2, 1, 2)
        elseif pressed == "enter" then
            if choice == 1 then
                return 1
            else
                return 2
            end
        end
    end
end

-- Return a string containing the local time from 
-- the computer running the game in a 12-hour format.
function utils.get_local_time()
---@diagnostic disable-next-line: param-type-mismatch, redundant-parameter
    return textutils.formatTime(os.time("local", false))
end

-- Prints in a prettified format for nice logging
-- content[string] : content to show on screen
-- type[config.displayed_logtypes] : logtype to show on screen, before log.
function utils.log(content, type)
    local log_pattern = "C%d@%s <%s> %s"   
    if type == constants.LOGTYPE_ERROR then
        printError(log_pattern:
            format(os.getComputerID(),utils.get_local_time(),type,content))
    elseif type ~= constants.LOGTYPE_DEBUG or (type == constants.LOGTYPE_DEBUG and constants.SHOW_DEBUG) then
        print(log_pattern:
            format(os.getComputerID(),utils.get_local_time(),type,content))
    end
end

-- Safely opens a file and display a warning if en error occurs.
-- Returns the file handle is successful
-- Returns nil if an error occured.
-- path[string] : file path.
-- mode[string] : in which mod to open the file. ("w","r", etc...)
function utils.open_file(path, mode)
    local file, e = fs.open(path, mode)
    if not file then
        utils.log("The file could not be opened correctly. Reason will be printed below,", ERROR)
        utils.log(("%s"):format(e), ERROR)
        return nil
    end
    return file
end

-- Safely writes on a file and display a warning if en error occurs.
-- Returns true if successful
-- Returns false if an error occured.
-- file_handle[Handle]  : Handle pointing to the opened file.
-- content[string]      : string to write to the file.
function utils.write_file(file_handle, content)
    -- No error managing ? Need to investigate
    file_handle.write(content)
    return true
end

-- Safely closes a file and display a warning if en error occurs.
-- Returns true if successful
-- Returns false if an error occured.
-- file_handle[Handle]  : Handle pointing to the opened file.
function utils.close_file(file_handle)
    -- No error managing ? Need to investigate
    file_handle.close()
    return true
end

function utils.loading_bar(progress, width, bg_color, fg_color)
    term.clearLine()
    local chars = math.floor(progress*width)
    utils.print_align_left(string.rep(" ", width), bg_color, bg_color)
    local _,y = term.getCursorPos()
    term.setCursorPos(1,y-1)
    utils.print_align_left(string.rep(" ", chars), fg_color, fg_color)
    print()
    utils.print_align_left(("%.1f%%"):format(progress*100))
    _,y = term.getCursorPos()
    term.setCursorPos(1,y-3)
end

-- Returns a centered window for a pop taking half the screen.
function utils.centered_window(title, strings, bg_color, border_color, padding)
    local x_max,y_max = term.getSize()
    local width = math.floor((x_max + padding)/2)
    local height = math.floor((y_max + padding)/2)
    local x = math.floor((x_max - padding)/4)
    local y = math.floor((y_max - padding)/4)
    local screen = term.current()
    local popup = window.create(screen,x,y,width,height)

    -- Clearing the total area
    popup.setBackgroundColour(bg_color)
    popup.setTextColour(term.getTextColor())
    popup.clear()

    -- Drawing the border
    paintutils.drawBox(
        x,
        y,
        math.floor(width*1.5)-1,
        math.floor(height*1.5)-1,
        border_color
    )

    -- Creating the text area
    popup = window.create(
        screen,
        x+padding,
        y+padding,
        width-padding-1,
        height-padding-1
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

return utils