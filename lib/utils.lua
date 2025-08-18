-- # DASHOU'S ITEM MANAGER

-- ## Utilities

-- Contains most functions and variables that are used in the
-- different projects files. This is not a file to be touched by
-- the user.

local config = require("lib/config")

local utils = {}

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

return utils
