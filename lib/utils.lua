-- # DASHOU'S ITEM MANAGER

-- ## Utilities

-- Contains most functions and variables that are used in the
-- different projects files. This is not a file to be touched by
-- the user.

local config = require("lib/config")

local ERROR = config.LOGTYPE_ERROR

local utils = {}

local PAGED_TABULATE_MESSAGE = "Press any key for next page of results..."

-- Clears terminal and sets cursor pos to 1,1
function utils.reset_terminal()
    term.clear()
    term.setCursorPos(1,1)
end


-- Return a string containing the local time from 
-- the computer running the game in a 12-hour format.
function utils.get_local_time()
    return textutils.formatTime(os.time("local", false))
end

-- Prints in a prettified format for nice logging
function utils.log(content, type)
    for _, allowed_type in ipairs(config.displayed_logtypes) do        
        if type == config.LOGTYPE_ERROR then
            printError(("C%d@%s <%s> : %s"):
                format(os.getComputerID(),utils.get_local_time(),type,content))
            break
        elseif type == allowed_type then    
            print(("C%d@%s <%s> %s"):
                format(os.getComputerID(),utils.get_local_time(),type,content))
            break
        end
    end
end

-- Is used to check if the new database size is writable on disk.
-- Returns the size of the database with unit added and a boolean
-- indicating if there is enough storage for the database.
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

    return formatted_size, size >= fs.getFreeSpace(config.BASE_PATH)
end


-- Safely opens a file and display a warning if en error occurs.
-- Returns the file handle is successful
-- Returns nil if an error occured.
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
function utils.write_file(file_handle, content)
    -- No error managing ? Need to investigate
    file_handle.write(content)
    return true
end

-- Safely closes a file and display a warning if en error occurs.
-- Returns true if successful
-- Returns false if an error occured.
function utils.close_file(file_handle)
    -- No error managing ? Need to investigate
    file_handle.close()
    return true
end

-- Safely gets content of JSON file as lua object.
-- Returns false if an error occured.
-- Return true otherwise.
function utils.get_json_file_as_object(path)
    local file = utils.open_file(path, "r")
    if not file then return false end

    local file_content = file.readAll()

    if not file_content then
        utils.log("An error occured during the reading of the file.", ERROR)
        return false
    end

    local JSON, e = textutils.unserializeJSON(file_content)
    if not JSON then
        utils.log("The file could not unserialized from JSON. Reason will be printed below.", ERROR)
        utils.log(("%s"):format(e), ERROR)
        return false
    end

    local did_close = utils.close_file(file)
    if not did_close then return false end

    return JSON
end

-- Write a string containing JSON to the file at specified path.
-- Returns true if successfull, false otherwise.
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
function utils.paged_tabulate_fixed(data, headers, spacing, widths, rightAlign)
    local _, h = term.getSize()

    -- Space for the headers + spacing + rows.
    local h_space = h-5

    -- Space for rows only.
    local h_space_rows = h_space-2

    local current_page_rows = {}

    -- Calculate number of pages needed
    local nb_page_needed = math.ceil(table.getn(data)/h_space)
    local count = 0

    for current_page = 1, nb_page_needed do
        -- Clears
        utils.reset_terminal()
        current_page_rows = {}

        -- Fill current page array with rows
        for i=1,h_space do
            local k = count + i
            if k <= table.getn(data) then
                table.insert(current_page_rows, data[k])
                if table.getn(current_page_rows) == h_space_rows then break end
            end
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
        if (current_page == nb_page_needed) then return end

        -- Prompt the user to hit a key before showing next page.
        utils.log(("%s"):format(PAGED_TABULATE_MESSAGE), config.LOGTYPE_INFO)
        os.pullEvent("key")
    end
end

-- Returns a lua obejct containing all of the id contained in the
-- files at the path mentioned in the config file.
function utils.prepare_registries()
    local registry = {}
    for _,path in ipairs(config.REG_PATHS) do
        local reg = utils.get_json_file_as_object(path)
        for _,s in ipairs(reg) do
            table.insert(registry, s)
        end
    end
    return registry
end

function utils.search_database_for_item(database, name, detailed_output, nbt)
    local detailed_results = {}
    local item_type = database[name]

    if item_type then
        local item_type_stacks = item_type["stacks"]
        local total = 0
        local display_name = nil
        local has_nbt = "NO"

        for _,stack in ipairs(item_type_stacks) do
            if nbt then
                has_nbt = "YES"
            end

            if not nbt or stack.details.nbt == nbt then
                display_name = stack.details.displayName
                total = total + stack.details.count
                if detailed_output then
                    -- Removing the first part of the id to only get the name and
                    -- id of storage.
                    local source = stack.source:match(":(.*)") or stack.source

                    
                    table.insert(detailed_results,{
                        source,
                        "@",
                        stack.slot,
                        display_name,
                        "x",
                        stack.details.count
                    })
                end
            end
        end

        if not detailed_output then
            return {total, "x", display_name, has_nbt}
        else
            return detailed_results
        end
    end
end

function utils.add_stack_to_db(database, section, slot, inv_name, details)
    if not database then return end

    local section_name = section

    if not database[section_name] then
        database[section_name] = {}
    end

    if not database[section_name]["nbt"] then
        database[section_name]["nbt"] = {}
    end

    if details.nbt then
        table.insert(database[section_name]["nbt"], details.nbt)
    end

    if not database[section_name]["stacks"] then
        database[section_name]["stacks"] = {}
    end

    table.insert(database[section_name]["stacks"],{
            slot = slot,
            source = inv_name,
            ["details"] = details
    })
end
return utils
