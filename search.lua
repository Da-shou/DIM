-- # DASHOU'S ITEM MANAGER

-- ## search program

-- When this program is called, the database is browsed
-- to see if an item corresponding to the query is found.

-- Created : 17/08/2025
-- Updated : 18/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR
local DEBUG = config.LOGTYPE_DEBUG

utils.reset_terminal()

-- Getting the search query
local search_query = arg[1]

-- Display the list of where items are
local do_display_list = false

local usage = "usage : search <query[string]> <do_display_list[bool]>"

if arg[1] == nil or arg[1] == "" then
    utils.log("Search query is empty!", ERROR)
    utils.log(usage, INFO)
    return
end

if arg[2] == nil and arg[2] ~= "false" then
    utils.log("do_display_list parameter wasn't found. Defaulting to false.", WARN)
elseif arg[2] == "true" then
    do_display_list = true
end

utils.log(("Starting search program with search query <%s>"):format(search_query), BEGIN)

-- Opening the minecraft item ID list and storing it in a lua
-- object called itemreg
local itemreg = utils.get_json_file_as_object(config.REGISTRY_MINECRAFT_ITEMS_PATH)

local candidates = {}

for _,id in ipairs(itemreg) do  
    if string.find(id, search_query, 1, true) then
        table.insert(candidates, id)
    end
end

-- Opening and unserializing the database for search and storing
-- it in a lua object called database.
local database = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)
if not database then return end

local display_list = {}

for _,c in ipairs(candidates) do
    local item_type = database[c]
    local total = 0
    local display_name = nil

    if item_type then
        for _,item in ipairs(item_type) do
            total = total + item.details.count
            display_name = item.details.displayName
            if do_display_list then
                print(("%s - %d x <%s> at slot %d"):format(
                        item.source, 
                        item.details.count, 
                        item.details.displayName, 
                        item.slot
                ))
            end
        end
        table.insert(display_list, {display_name, total})
    end
end

utils.log(("Search program with search query <%s> found below results.\n"):format(search_query), INFO)
textutils.tabulate({"Name", "Count"}, {"",""}, table.unpack(display_list))
print()
utils.log(("Search program ended"):format(search_query), END)