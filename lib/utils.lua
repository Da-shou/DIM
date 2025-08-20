-- # DASHOU'S ITEM MANAGER

-- ## Utilities

-- Contains most functions and variables that are used in the
-- different projects files. This is not a file to be touched by
-- the user.

local config = require("lib/config")

local ERROR = config.LOGTYPE_ERROR
local INFO = config.LOGTYPE_INFO
local DEBUG = config.LOGTYPE_DEBUG

local utils = {}

local PAGED_TABULATE_MESSAGE = "Press any key for next page of results..."

-- Ternary operator implementation (Thanks Lua)
function utils.fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

-- Clears terminal and sets cursor pos to 1,1
function utils.reset_terminal()
    term.clear()
    term.setCursorPos(1,1)
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
    for _, allowed_type in ipairs(config.displayed_logtypes) do        
        if type == config.LOGTYPE_ERROR then
            printError(log_pattern:
                format(os.getComputerID(),utils.get_local_time(),type,content))
            break
        elseif type == allowed_type then    
            print(log_pattern:
                format(os.getComputerID(),utils.get_local_time(),type,content))
            break
        end
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
    if size >= 1000000 then
        unit_char = "M"
        unit_div = 1048576
    elseif size >= 1000 then
        unit_char = "k"
        unit_div = 1024
    end

    local formatted_size = nil
    if unit_div == 1 then
        formatted_size = ("%d"):format(size/unit_div)..unit_char.."B"
    else
        formatted_size = ("%.1f"):format(size/unit_div)..unit_char.."B"
    end

    utils.log(("New item storage database size is %s"):format(formatted_size), INFO)

    return formatted_size, size >= fs.getFreeSpace(config.BASE_PATH)
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
local function padCell(text, width, rightAlign)
    local text_len = string.len(text)
    if text_len > width then
        -- truncate if too long
        text = text:sub(1, width)
    end

    if rightAlign then
        return string.rep(" ", width - text_len)..text
    else
        return text..string.rep(" ", width - text_len)
    end
end

-- Custom tabulate function allowing for custom widths of colums.
-- rows[{{s1,s2},{s3,s4},...}] : table of strings to be printed.
-- widths[{number,...}]        : width for each column
-- rightAlign[boolean]  : if true, adds spaces to the right. Defaults to false.
local function tabulate_fixed(rows, widths, rightAlign)
    for _, row in ipairs(rows) do
        local out = {}
        for i, cell in ipairs(row) do
            local w = widths[i] or 8  -- default width
            local r = rightAlign and rightAlign[i] or false
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
function utils.paged_tabulate_fixed(data, headers, widths, rightAlign)
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
        tabulate_fixed(current_page_rows, widths, rightAlign)

        print()
        utils.log(("%d results shown - Page %d/%d"):format(
            table.getn(current_page_rows) - 2,
            current_page, 
            nb_page_needed), 
            config.LOGTYPE_INFO)

        -- If this was the last page, leave
        if (current_page == nb_page_needed) then 
            -- Prompt the user to hit a key before showing next page.
            utils.log(("Last page reached. Press any key to exit search..."), config.LOGTYPE_INFO)
            os.pullEvent("key")
            utils.reset_terminal()
            return
        end

        -- Prompt the user to hit a key before showing next page.
        utils.log(("%s"):format(PAGED_TABULATE_MESSAGE), config.LOGTYPE_INFO)
        os.pullEvent("key")

        utils.reset_terminal()
    end
end

-- Returns a lua obejct containing all of the id contained in the
-- files at the path mentioned in the config file.
function utils.prepare_registries()
    local registry = {}
    for _,path in ipairs(config.REG_PATHS) do
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
-- detailed_output[boolean] : Changes the output to detailed results if true.
-- nbt[string]              : NBT string if stack has one. Can be nil. 
function utils.search_database_for_item(database, name, detailed_output, nbt)
    local detailed_results = {}
    local item_type = database[name]

    if item_type then
        local item_type_stacks = item_type["stacks"]
        local total = 0
        local display_name = nil

        for _,stack in ipairs(item_type_stacks) do
            if not nbt or stack.details.nbt == nbt then
                display_name = stack.details.displayName
                total = total + stack.details.count
                
                if detailed_output then

                    table.insert(detailed_results,{
                        stack.source,
                        "@",
                        stack.slot,
                        name,
                        "x",
                        stack.details.count,
                        nbt,
                        stack.details.maxCount
                    })
                end
            end
        end

        if not detailed_output then
            return {display_name, "x", total}
        else
            return detailed_results
        end
    end
end

-- Sorts a table from the database results in descending order.
-- results[table]       : the results table to sort
-- field_nb[number]     : the index of the field to sort with.
-- ascending[boolean]   : (optional) if false, sorts in descending order. defaults to true.
function utils.sort_results_from_db_search(results, field_nb, ascending)
    if ascending == nil then ascending = true end
    table.sort(results, 
        function(a,b) 
            return utils.fif(
                (ascending), 
                (a[field_nb] < b[field_nb]), 
                (a[field_nb] > b[field_nb])
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
    if not database then return end

    -- Checking if item has a section, if not, create it with
    -- both the stacks and nbt groups.
    if not database[section] then
        database[section] = {}
        database[section]["stacks"] = {}
        database[section]["nbt"] = {}
    end

    -- Insert the NBT of the current object to the nbt table.
    if details.nbt then
        table.insert(database[section]["nbt"], details.nbt)
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
function utils.remove_stack_from_db(database, section, slot, source)
    if not database then return end
    if not database[section] then return end

    for i,stack in ipairs(database[section]["stacks"]) do
        if stack.slot == slot and stack.source == source then
            utils.log(("Removed a stack from %s at slot %s from JSON Database."):format(
                stack.source, stack.slot
            ), DEBUG)
            table.remove(database[section]["stacks"], i)
        end
    end
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
            utils.log(("Updated a stack from %s at slot %s from JSON Database."):format(
                stack.source, stack.slot
            ), DEBUG)

            utils.log(("%d => %d"):format(
                stack.details.count, new_count
            ), DEBUG)


            database[section]["stacks"][i]["details"].count = new_count
        end
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

    if not utils.write_json_string_in_file(config.DATABASE_FILE_PATH, UPDATED_JSON_DB) then
        return false
    end

    utils.log("Successfully updated JSON database", DEBUG)
    return true
end

return utils
