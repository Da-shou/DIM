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
local display_details = false

local usage = "usage : search <query[string]> <display_details[bool]>"

if arg[1] == nil or arg[1] == "" then
    utils.log("Search query is empty!", ERROR)
    utils.log(usage, INFO)
    return
end

if arg[2] == nil and arg[2] ~= "false" then
    utils.log("display_details parameter wasn't found. Defaulting to false.", WARN)
elseif arg[2] == "true" then
    display_details = true
end

utils.log(("Starting search program with search query <%s>"):format(search_query), BEGIN)
utils.log("Now searching...", INFO)

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

-- Will contain the informations about the items.
local display_list = {}

-- Used to add a number to the rows when displayed without details.
local item_index = 0
local display_name = nil
local total = 0

-- Iterate over every possible item type that matches the search
for _,c in ipairs(candidates) do
    local item_type = database[c]

    -- Resetting the total item count and display_name to 0
    display_name = nil
    total = 0
    
    if item_type then
        -- For each stack of items of specified type.
        for _,item in ipairs(item_type) do
            -- Add their count to the total.
            total = total + item.details.count
            display_name = item.details.displayName
            
            -- If details are enabled, insert line that will show in which slot
            -- and which storage the stack is located. The total is not displayed.
            if display_details then
                -- Removing "minecraft:" in front of the source to shorten the output.
                local source = string.sub(item.source,11,string.len(item.source))
                table.insert(display_list, {source.." @ slot "..item.slot.." - "..display_name.." x "..item.details.count})
            end
        end
        
        -- If the detailed display is deactivated, create a row with the index, 
        -- display name and total of each type of item.
        if not display_details then
            if string.len(display_name) > config.MAX_DISPLAY_NAME_STRING_LENGTH then
                display_name = string.sub(display_name, 1, config.MAX_DISPLAY_NAME_STRING_LENGTH)
                display_name = display_name.."..."
            end
            table.insert(display_list, {item_index, display_name, total})
        end
        item_index = item_index + 1
    end
end

-- Choose what to display based on the state of the display_details boolean.
if table.getn(display_list) > 0 then
    local rows = {}
    if display_details then
        for _, row in ipairs(display_list) do
            table.insert(rows, {row[1]})
        end

        -- Setting the columns names and the white space.
        utils.paged_tabulate(rows,  {("Detailed results of search query <%s>"):format(search_query)}, {""})
    else
        for _, row in ipairs(display_list) do
            table.insert(rows, {row[1], row[2], row[3]})
        end

        utils.paged_tabulate(
            rows, 
            {"<#>", "<Name>", "<Quantity>"}, 
            {"", "", ""}
        )
    end
else
    utils.log(("No results have been found for your search query <%s>"):format(search_query), INFO)
end

utils.log(("Search program ended.\n"):format(search_query), END)