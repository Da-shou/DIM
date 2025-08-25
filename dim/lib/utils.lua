-- # DASHOU'S ITEM MANAGER

-- ## Utilities

-- Contains most functions and variables that are used in the
-- different projects files. This is not a file to be touched by
-- the user.

local constants = require("lib/constants")


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

-- Is used to check if the new database size is writable on disk.
-- Returns the size of the database with unit added and a boolean
-- indicating if there is enough storage for the database.
-- size[number] : size in bytes.
function utils.check_db_size(size)
    local unit_char = ""
    local unit_div = 1

    -- Picking an adequate size for the size printing.
    if size >= 1000*1000 then
        unit_char = "M"
        unit_div = 100000
    elseif size >= 1000 then
        unit_char = "K"
        unit_div = 100
    end

    local formatted_size = nil
    if unit_div == 1 then
        formatted_size = ("%d"):format((size/unit_div)/10)..unit_char.."B"
    else
        formatted_size = ("%.1f"):format((size/unit_div)/10)..unit_char.."B"
    end

    utils.log(("New item storage database size is %s"):format(formatted_size), INFO)

    return formatted_size, size >= fs.getFreeSpace(constants.BASE_PATH)
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

-- Safely gets content of JSON file as lua object.
-- Returns nil if an error occured.
-- Return object otherwise.
-- path[string] : path to the JSON file.
function utils.get_json_file_as_object(path)
    local file = utils.open_file(path, "r")
    if not file then return nil end

    local file_content = file.readAll()

    if not file_content then
        utils.log("An error occured during the reading of the file.", ERROR)
        return nil
    end

    local JSON, e = textutils.unserializeJSON(file_content)
    if not JSON then
        utils.log("The file could not unserialized from JSON. Reason will be printed below.", ERROR)
        utils.log(("%s"):format(e), ERROR)
        return nil
    end

    local did_close = utils.close_file(file)
    if not did_close then return nil end

    return JSON
end

-- Write a string containing JSON to the file at specified path.
-- Returns true if successful, false otherwise.
-- CAUTION : This overwrites the JSON file !
-- path[string]     : path to the JSON file that will be written in.
-- object[string]   : JSON-Serialized string to be written in the file.
function utils.write_json_string_in_file(path, object)
    local file = utils.open_file(path, "w")
    if not file then return false end

    local did_write = utils.write_file(file, object)
    if not did_write then return false end

    local did_close = utils.close_file(file)
    if not did_close then return false end

    return true
end

-- Pads the string with left or right spacing
-- text[string]         : string to be padded.
-- width[string]        : how many spaces of padding.
-- rightAlign[boolean]  : if true, adds spaces to the right. Defaults to false.
local function padCell(text, width, right_align)
    local text_len = string.len(text)
    if text_len > width then
        -- truncate if too long
        text = text:sub(1, width)
    end

    if right_align then
        return string.rep(" ", width - text_len)..text
    else
        return text..string.rep(" ", width - text_len)
    end
end

-- Custom tabulate function allowing for custom widths of colums.
-- rows[{{s1,s2},{s3,s4},...}]  : table of strings to be printed.
-- widths[{number,...}]         : width for each column
-- rightAlign[boolean]          : if true, adds spaces to the right. Defaults to false.
-- left_space[number]           : space to add to the left of each row, defaults to 0
local function tabulate_fixed(rows, widths, right_align, left_space)
    if left_space == nil then left_space = 0 end
    for _, row in ipairs(rows) do
        local out = {}
        if left_space > 0 then table.insert(out, string.rep(" ", left_space)) end
        for i, cell in ipairs(row) do
            local w = widths[i] or 8  -- default width
            local r = right_align and right_align[i] or false
            table.insert(out, padCell(cell, w, r))
        end
        print(table.concat(out, " ")) -- space between cols
    end
end

-- Allows for a paged tabulated print of a table because the one
-- that ships with ComputerCraft is complete dogshit
-- rows[{{s1,s2},{s3,s4},...}] : Table of strings to be printed.
-- headers[{string,...}]       : Names of the headers of each columns.
-- widths[{number,...}]        : width for each column
-- rightAlign[boolean]  : if true, adds spaces to the right. Defaults to false.
function utils.paged_tabulate_fixed(data, headers, widths, right_align, left_space)
    local w, h = term.getSize()

    utils.reset_terminal()

    -- Space for the headers + spacing + rows.
    local h_space = h-5

    -- Space for rows only.
    local h_space_rows = h_space-2

    local current_page_rows = {}

    -- Calculate number of pages needed
    local count = 0

    local nb_page_needed = math.ceil(table.getn(data)/h_space_rows)

    for current_page = 1, nb_page_needed do
        -- Clears
        current_page_rows = {}

        -- Fill current page array with rows
        for i=1,h_space do
            local k = count + i
            if k <= table.getn(data) then
                table.insert(current_page_rows, data[k])
                if table.getn(current_page_rows) == h_space_rows then break end
            end
        end

        local spacing = {}
        
        for _=1, table.getn(headers) do
            table.insert(spacing,string.rep("-",w))
        end

        -- Add column names and spacing at start
        table.insert(current_page_rows, 1, spacing)


        table.insert(current_page_rows, 1, headers)

        -- Update the row counter
        count = count + h_space_rows

        -- Display the paged results
        tabulate_fixed(current_page_rows, widths, right_align, left_space)

        print()
        utils.log(("%d results shown - Page %d/%d"):format(
            table.getn(current_page_rows) - 2,
            current_page, 
            nb_page_needed), 
            constants.LOGTYPE_INFO)

        -- If this was the last page, leave
        if (current_page == nb_page_needed) then 
            -- Prompt the user to hit a key before showing next page.
            utils.log(("Last page reached. Press any key to exit search..."), constants.LOGTYPE_INFO)
            os.pullEvent("key")
            utils.reset_terminal()
            return
        end

        -- Prompt the user to hit a key before showing next page.
        utils.log(("%s"):format(PAGED_TABULATE_MESSAGE), constants.LOGTYPE_INFO)
        os.pullEvent("key")

        utils.reset_terminal()
    end
end

-- Basically the same function as above but allows the user to return a
-- choice using the arrow keys and enter. Going below last results 
-- with the arrows makes the next page show, same with going above first.
function utils.paged_tabulate_fixed_choice(data, headers, widths, right_align, left_space)
    local w, h = term.getSize()

    utils.reset_terminal()

    -- Where the cursor will begin
    local cursor_char = "->"
    local cursor_pos = 1

    -- Add the cursor column
    for i,row in ipairs(data) do
        table.insert(row,1,utils.fif(i==1, cursor_char,""))
    end

    table.insert(headers, 1, "<Crsr>")
    table.insert(right_align, 1, true)
    table.insert(widths, 1, 6)

    -- Space for the headers + spacing + rows.
    local h_space = h-5

    -- Space for rows only.
    local h_space_rows = h_space-5
    local current_page_rows = {}

    -- Calculate number of pages needed
    local start_id = 0
    local nb_page_needed = math.ceil(table.getn(data)/h_space_rows)

    local key = nil

    local current_page = 1

    -- Start input loop
    while true do
        -- Clears
        current_page_rows = {}

        if key then
            local pressed_key_name = keys.getName(key)
            
            -- Updating cursor position based on input
            if pressed_key_name == "down" then
                cursor_pos = cursor_pos + 1
            elseif pressed_key_name == "up" then 
                cursor_pos = cursor_pos - 1
            -- Confirmation of choice
            elseif pressed_key_name == "right" then
                if current_page < nb_page_needed then
                    current_page = current_page + 1
                    cursor_pos = 1
                end
            elseif pressed_key_name == "left" then
                if current_page > 1 then
                    current_page = current_page - 1
                    cursor_pos = 1
                end
            elseif pressed_key_name == "backspace" then
                return nil
            elseif pressed_key_name == "enter" then
                -- Removing the cursor column
                for _,row in ipairs(data) do
                    table.remove(row,1)
                end
                -- Returns the data on the line of the cursor.
                return data[(cursor_pos) + start_id]
            end
        end


        local y_limit = h_space_rows

        if current_page == nb_page_needed then
            if table.getn(data) % h_space_rows > 0 then
                y_limit = table.getn(data) % h_space_rows
            end
        end

        -- Changing page if we hit bottom or top.
        if cursor_pos > y_limit then
            -- Going to next page
            if current_page == nb_page_needed then
                -- If last page, go to first page.
                current_page = 1
            elseif current_page < nb_page_needed then
                -- If not page, go to next page.
                current_page = current_page + 1
            end
            cursor_pos = 1
        elseif cursor_pos < 1 then
            -- Going to previous page
            if current_page == 1 then
                -- If first page, go to last page.
                current_page = nb_page_needed
                if table.getn(data) % h_space_rows > 0 then
                    cursor_pos = table.getn(data) % h_space_rows
                else
                    cursor_pos = h_space_rows
                end
            elseif current_page > 1 then
                -- If not, go to previous
                current_page = current_page - 1
                cursor_pos = h_space_rows
            end
        end

        start_id = h_space_rows*(current_page-1)

        -- Fill current page array with rows
        for i=1,h_space do
            local k = start_id + i
            if k <= table.getn(data) then
                if i == cursor_pos then
                    data[k][1] = cursor_char
                else
                    data[k][1] = ""
                end

                table.insert(current_page_rows, data[k])

                if table.getn(current_page_rows) == h_space_rows then break end
            end
        end

        local spacing = {}
        
        for _=1, table.getn(headers) do
            table.insert(spacing,string.rep("-",w))
        end

        -- Add column names and spacing at start
        table.insert(current_page_rows, 1, spacing)
        table.insert(current_page_rows, 1, headers)

        -- Prompt the user to hit a key before showing next page.
        utils.log(("%s"):format("Choose with <UP>, <DOWN>, <LEFT> and <RIGHT>"), constants.LOGTYPE_INFO)
        utils.log(("%s"):format("Confirm with <ENTER>. Cancel with <BACKSPACE>"), constants.LOGTYPE_INFO)

        print()

        -- Display the paged results
        tabulate_fixed(current_page_rows, widths, right_align, left_space)

        print()

        utils.log(("%d results shown - Page %d/%d"):format(
            table.getn(current_page_rows) - 2,
            current_page, 
            nb_page_needed), 
            constants.LOGTYPE_INFO
        )

        -- If this was the last page, leave
        if (current_page == nb_page_needed) then 
            utils.log(("End of list reached."), constants.LOGTYPE_INFO)
        end

        _, key, _ = os.pullEvent("key")

        utils.reset_terminal()
    end
end

-- Returns a lua obejct containing all of the id contained in the
-- files at the path mentioned in the config file.
function utils.prepare_registries()
    local registry = {}
    for _,path in ipairs(constants.REG_PATHS) do
        local reg = utils.get_json_file_as_object(path)
        if not reg then return registry end
        for _,s in ipairs(reg) do
            table.insert(registry, s)
        end
    end
    return registry
end

-- Search for an item in the JSON database.
-- Has two modes, depending on the value of detailed_output.
-- If true, returns ONE object containing the display 
-- name and total count of said item.
-- If false, returns a TABLE of the 
-- informations about each separate stack of said item.
--
-- database[Object]         : Lua object taken from the JSON file.
-- name[string]             : Name (ID) of the item being searched.
-- detailed_output[boolean] : Changes the output return a list of stacks if true.
-- nbt[string]              : NBT string if stack has one. Can be nil.
-- partial_only[boolean]    : if true, returns only stacks that aren't at their maxCount. 
--                            default to false. has no effect on simple display.
function utils.search_database_for_item(database, name, by_stack, nbt, partial_only)
    local detailed_results = {}
    local item_type = database[name]
    local display_name = ""

    if item_type then
        local item_type_stacks = item_type["stacks"]
        local total = 0
        local stack_max_size = 1
        local stack_nbt = nil

        -- If nbt == nil, will insert all stacks without NBTs.
        -- If nbt has a value, will insert all stacks with hash = nbt
        for _,stack in ipairs(item_type_stacks) do
            if stack.details.nbt == nbt then
                display_name = stack.details.displayName
                total = total + stack.details.count
                stack_max_size = stack.details.maxCount
                stack_nbt = stack.details.nbt
                if by_stack then
                    if not partial_only or (partial_only and stack.details.count < stack.details.maxCount) then
                        table.insert(detailed_results,{
                            source=stack.source,
                            at="@",
                            slot=stack.slot,
                            name=name,
                            x="x",
                            count=stack.details.count,
                            nbt=stack.details.nbt,
                            maxCount=stack.details.maxCount,
                            displayName=stack.details.displayName
                        })
                    end
                end
            end
        end

        if not by_stack then
            return {
                displayName=display_name, 
                x="x", 
                total=total, 
                stackMaxSize=stack_max_size,
                name=name,
                nbt=stack_nbt
            }
        else
            return detailed_results
        end
    end
end

-- Sorts a table from the database results in descending order.
-- results[table]       : the results table to sort
-- field_nb[number]     : the index of the field to sort with.
-- ascending[boolean]   : (optional) if false, sorts in descending order. defaults to true.
function utils.sort_results_from_db_search(results, field_id, ascending)
    if ascending == nil then ascending = true end
    table.sort(results, 
        function(a,b) 
            return utils.fif(
                (ascending), 
                (a[field_id] < b[field_id]), 
                (a[field_id] > b[field_id])
            )
        end
    )
end

-- Adds a stack of items to the JSON database. Is used when a new empty slot is
-- filled with items.
--
-- database[Object]     : Lua object taken from the JSON file.
-- section[string]      : Name (ID) of the item being added.
-- slot[number]         : Slot of the storage where the stack is stored in-game.
-- inv_name[string]     : Name of the inventory where the stack is stored.
-- details[Object]      : Object containing item details from getItemDetail
function utils.add_stack_to_db(database, section, slot, inv_name, details)
    if not database then 
        utils.log("Could not get database JSON object.", ERROR)
        return 
    end

    local stats = utils.get_json_file_as_object(constants.STATS_FILE_PATH)
    if not stats then
        utils.log("Could not get statistics JSON object.", ERROR)
        return
    end

    -- Remove the empty slot that is now taken by the stack
    if database["empty_slot"] then
        for i,empty_slot in ipairs(database["empty_slot"]["stacks"]) do
            if empty_slot.source == inv_name and empty_slot.slot == slot then
                table.remove(database["empty_slot"]["stacks"], i)
                break
            end
        end
    end

    -- Checking if item has a section, if not, create it with
    -- both the stacks and nbt groups.
    if not database[section] then
        database[section] = {}
        database[section]["stacks"] = {}
        database[section]["nbt"] = {}
    end

    -- Insert the NBT of the current object to the nbt table.
    if details.nbt then
        for _,nbt in ipairs(database[section]["nbt"]) do
            if nbt == details.nbt then 
                goto nbt_end
            end
        end
        table.insert(database[section]["nbt"], details.nbt)
        ::nbt_end::
    end

    -- Insert the information about the current stack to the stack table.
    table.insert(database[section]["stacks"],{
            slot = slot,
            source = inv_name,
            ["details"] = details
    })
end

-- Removes a stack of items to the JSON database. Used when extracting an
-- entire stack of items.
--
-- database[Object]     : Lua object taken from the JSON file.
-- section[string]      : Name (ID) of the item being added.
-- slot[number]         : Slot of the storage where the stack is stored in-game.
-- inv_name[string]     : Name of the inventory where the stack is stored.
-- details[Object]      : Object containing item details from getItemDetail
function utils.remove_stack_from_db(database, section, slot, source, nbt)
    if not database then return end
    if not database[section] then return end

    local remove_nbt = true

    for i,stack in ipairs(database[section]["stacks"]) do
        if stack.slot == slot and stack.source == source then
            utils.log(("Removed stack from %s at slot %s from database."):format(
                stack.source, stack.slot
            ), DEBUG)
            table.remove(database[section]["stacks"], i)
        end
    end

    -- Check if another item of this type has this NBT.
    for _,stack in ipairs(database[section]["stacks"]) do
        if stack.details.nbt == nbt then
            remove_nbt = false
        end
    end

    -- If the stack removed was the last having this NBT,
    -- remove it from the NBT list.
    if remove_nbt then
        utils.log("Last item with this NBT found. Removing NBT from database.", DEBUG)
        for i,hash in ipairs(database[section]["nbt"]) do
            if hash == nbt then
                table.remove(database[section]["nbt"], i)
            end
        end
    end

    utils.add_stack_to_db(database,"empty_slot",slot,source,{count=0, maxCount=0})
end

-- Updates a stack of items to the JSON database. Used when extracting a
-- certain number of items from a stack.
--
-- database[Object]     : Lua object taken from the JSON file.
-- section[string]      : Name (ID) of the item being added.
-- slot[number]         : Slot of the storage where the stack is stored in-game.
-- inv_name[string]     : Name of the inventory where the stack is stored.
-- details[Object]      : Object containing item details from getItemDetail
function utils.update_stack_count_in_db(database, section, slot, source, new_count)
    if not database then return end
    if not database[section] then return end

    for i,stack in ipairs(database[section]["stacks"]) do
        if stack.slot == slot and stack.source == source then
            utils.log(("Stack updated (%d => %d) from %s at slot %s."):format(
                stack.details.count, new_count, stack.source, stack.slot
            ), DEBUG)

            database[section]["stacks"][i]["details"].count = new_count
        end

        ::next_stack::
    end
end

function utils.save_database_to_JSON(database)
    -- Serializing our new db to JSON
    local UPDATED_JSON_DB = textutils.serializeJSON(database)
    local db_size = string.len(UPDATED_JSON_DB)

    if not utils.check_db_size(db_size) then
        utils.log("Not enough free space on disk left to save new database. Exiting...", ERROR)
        return false
    end

    -- Overwring the old db if enough space is found
    utils.log("Overwriting old JSON database...", DEBUG)

    if not utils.write_json_string_in_file(constants.DATABASE_FILE_PATH, UPDATED_JSON_DB) then
        return false
    end

    utils.log("Successfully updated JSON database", DEBUG)
    return true
end

-- Returns UNIX timestamp at this moment in milliseconds.
function utils.start_stopwatch()
    return os.epoch("local")
end

-- Returns time that passed since begin was created in ms in a string.
function utils.stop_stopwatch(start)
    local time = 0
    local unit = ""

    local ms = (os.epoch("local") - start)

    if ms / 1000 < 1 then
        time = ms
        unit = "ms"
    else 
        time = ms / 1000
        unit = "s"
    end

    return (time.." "..unit):format(".3%f")
end

return utils