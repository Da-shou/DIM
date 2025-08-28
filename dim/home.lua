-- # DASHOU'S ITEM MANAGER

-- ## Home file

-- This file will display the list of options to the user, mainly
-- insert, extract, search and inventory.

-- Created : 17/08/2025
-- Updated : 25/08/2025

local constants = require("lib/constants")
local utils = require("lib/utils")
local window_utils = require("lib/window-utils")
local translations = require("lang/en-gb")
local INFO = constants.LOGTYPE_INFO
local screen = term.native()

::home::
term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
local file_logo = utils.open_file(constants.ASCII_LOGO_FILE_PATH, "r")
if not file_logo then return end

-- If first boot, then run inventory at startup.
if settings.load() and settings.get("dim.scanned") == false then
    shell.run("/dim/inventory.lua")
    -- Auto-pressing enter for first inventory
    settings.set("dim.scanned", true)
    settings.save()
    os.queueEvent("key", 13, false)
end

utils.reset_terminal()

local max_x, max_y = term.getSize()
local x_start = math.floor(max_x/2)
local y_start = 2
while true do
    local line = file_logo.readLine()
    if not line then break end
    local len = string.len(line)
    term.setCursorPos(x_start-math.floor(len/2),y_start)
    y_start = y_start + 1
    if line then
        print(line)
    end
end

print()
utils.print_centered("v. "..constants.dim_version)

local function main_menu()
    local function switchTo(bgColor, textColor) 
        term.setTextColor(textColor)
        term.setBackgroundColor(bgColor)
    end

    local choice_x = 0
    local choice_y = 0
    
    local choices = {
        "INVENTORY",
        "INSERT",
        "SEARCH",
        "EXTRACT",
    }
    
    print()
    print()
    print()
    print()
    
    local _,start_y = term.getCursorPos()
    while true do
        local x,_ = term.getSize()
        local y = start_y

        local cur = term.getBackgroundColour()
        term.setBackgroundColour(cur)
        
        -- how many chars inbetween options
        local spacing = 15

        local middle_pos = math.floor(x/2)
        local start_1 = middle_pos - (math.floor(string.len(choices[1])/2)) - spacing
        local start_2 = middle_pos - (math.floor(string.len(choices[2])/2)) + spacing
        local start_3 = middle_pos - (math.floor(string.len(choices[3])/2)) - spacing
        local start_4 = middle_pos - (math.floor(string.len(choices[4])/2)) + spacing
        
        term.setCursorPos(1,y-1)
        term.clearLine()

        term.setCursorPos(1,y)
        term.clearLine()

        term.setCursorPos(1,y+1)
        term.clearLine()

        if choice_x == 0 and choice_y == 0 then
            switchTo(colors.blue, colors.white)
            term.setCursorPos(start_1-1, y-1)
            write(string.rep(" ",string.len(choices[1])+2))
            term.setCursorPos(start_1-1, y)
            write("<"..choices[1]..">")
            term.setCursorPos(start_1-1, y+1)
            write(string.rep(" ",string.len(choices[1])+2))
            term.setCursorPos(1, y)
            switchTo(colors.black, colors.white)
        else
            term.setCursorPos(start_1, y)
            write(choices[1])
        end

        if choice_x == 1 and choice_y == 0 then
            switchTo(colors.red, colors.white)
            term.setCursorPos(start_2-1, y-1)
            write(string.rep(" ",string.len(choices[2])+2))
            term.setCursorPos(start_2-1, y)
            write("<"..choices[2]..">")
            term.setCursorPos(start_2-1, y+1)
            write(string.rep(" ",string.len(choices[2])+2))
            term.setCursorPos(1, y)
            switchTo(colors.black, colors.white)
        else
            term.setCursorPos(start_2, y)
            write(choices[2])
        end
            
        y = y + 5
        term.setCursorPos(1,y-1)
        term.clearLine()

        term.setCursorPos(1,y)
        term.clearLine()

        term.setCursorPos(1,y+1)
        term.clearLine()

        if choice_x == 0 and choice_y == 1 then
            switchTo(colors.green, colors.white)
            term.setCursorPos(start_3-1, y-1)
            write(string.rep(" ",string.len(choices[3])+2))
            term.setCursorPos(start_3-1, y)
            write("<"..choices[3]..">")
            term.setCursorPos(start_3-1, y+1)
            write(string.rep(" ",string.len(choices[3])+2))
            term.setCursorPos(1, y)
            switchTo(colors.black, colors.white)
        else
            term.setCursorPos(start_3, y)
            write(choices[3])
        end

        if choice_x == 1 and choice_y == 1 then
            switchTo(colors.yellow, colors.black)
            term.setCursorPos(start_4-1, y-1)
            write(string.rep(" ",string.len(choices[4])+2))
            term.setCursorPos(start_4-1, y)
            write("<"..choices[4]..">")
            term.setCursorPos(start_4-1, y+1)
            write(string.rep(" ",string.len(choices[4])+2))
            term.setCursorPos(1, y)
            switchTo(colors.black, colors.white)
        else
            term.setCursorPos(start_4, y)
            write(choices[4])
        end

        local _, key, _ = os.pullEvent("key")
        local pressed = keys.getName(key)

        if pressed == "left" then
            choice_x = 0
        elseif pressed == "right" then
            choice_x = 1
        elseif pressed == "up" then
            choice_y = 0
        elseif pressed == "down" then
            choice_y = 1
        elseif pressed == "enter" then
            return choice_x, choice_y
        end
    end
end

while true do
    local choice_x, choice_y = main_menu()
    if choice_x == 0 then
        if choice_y == 0 then
            -- Making the window
            local confirm_popup = window_utils.centered_window(
                translations.home_confirm_inventory_window_title,
                {translations.home_confirm_inventory_window_content},
                math.floor(max_x/2), math.floor(max_y/1.75),
                colours.blue, colors.white, 2, false
            )

            -- Adding a choice to it
            local choice = window_utils.centered_window_choice(confirm_popup, translations.home_confirm_inventory_NO, translations.home_confirm_inventory_YES)
            term.redirect(screen)

            term.setBackgroundColour(colours.black)
            term.setTextColour(colours.white)

            if choice == 2 then
                shell.run("/dim/inventory.lua")
            else
                goto home
            end
        end
        if choice_y == 1 then
            utils.reset_terminal()
            print()
            print()
            utils.print_align_left("Please enter your search query.")
            print()
            write(string.rep(" ", math.floor(max_x/6)).."> ")
            local query = read()
            shell.run("/dim/search.lua", query)
        end
    end
    if choice_x == 1 then
        if choice_y == 0 then
            shell.run("/dim/insert.lua")
        end
        if choice_y == 1 then
            shell.run("/dim/extract.lua")
        end
    end
    utils.log("Press <ENTER> to return HOME.", INFO)
    while true do
        local _, key, _ = os.pullEvent("key")
        if keys.getName(key) == "enter" then
            goto home
        end
    end
end