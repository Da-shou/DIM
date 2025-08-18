-- # DASHOU'S ITEM MANAGER

-- ## Utilities

-- Contains most functions and variables that are used in the
-- different projects files. This is not a file to be touched by
-- the user.

local config = require("lib/config")

local ERROR = config.LOGTYPE_ERROR

local utils = {}

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
            printError(("C%d@%s %s> %s"):
                format(os.getComputerID(),utils.get_local_time(),type,content))
            break
        elseif type == allowed_type then
            print(("C%d@%s %s> %s"):
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

return utils
