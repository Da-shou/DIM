-- # DASHOU'S ITEM MANAGER

-- ## search program

-- When this program is called, the database is browsed
-- to see if an item corresponding to the query is found.
-- Usage : search <query[string]> <display_details[true|false]

-- Created : 17/08/2025
-- Updated : 19/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local DEBUG = config.LOGTYPE_DEBUG
local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR

utils.reset_terminal()

-- Getting the search query
local search_query = arg[1]
local search_all = false

-- Display the list of where items are
local display_details = false

local usage = "usage : search <query[string]> <display_details[bool]>"

if arg[1] == nil or arg[1] == "" then
    utils.log("Search query is empty!", ERROR)
    utils.log(usage, INFO)
    return
end

if search_query == "*" then search_all = true end

if arg[2] == nil and arg[2] ~= "false" then
    utils.log("display_details parameter wasn't found. Defaulting to false.", WARN)
elseif arg[2] == "true" then
    display_details = true
end

utils.log(("Starting search program with search query <%s>"):format(search_query), BEGIN)
utils.log("Now searching...", INFO)

-- Opening the item ID list and storing it in a lua
-- object called itemreg
local itemreg = utils.prepare_registries()

local candidates = {}

if not search_all then
    for _,id in ipairs(itemreg) do  
        if string.find(string.lower(id), string.lower(search_query), 1, true) then
            table.insert(candidates, id)
        end
    end
else
    candidates = itemreg
end

-- Opening and unserializing the database for search and storing
-- it in a lua object called database.
local database = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)
if not database then return end

-- Will contain the informations about the items returned from the search.
local display_list = {}

-- Iterate over every possible item type that matches the search
for _,c in ipairs(candidates) do
    local section = database[c]
    if section then
        local section_nbt = section["nbt"]
        if section_nbt and table.getn(section_nbt) > 0 then
            for _,nbt in ipairs(section_nbt) do
                utils.log(("Searching item with NBT %s"):format(nbt), DEBUG)
                table.insert(display_list, (utils.search_database_for_item(database, c, display_details, nbt)))
            end
        else
            table.insert(display_list, (utils.search_database_for_item(database, c, display_details)))
        end
    end
end

-- Choose what to display based on the state of the display_details boolean.
if table.getn(display_list) > 0 then
    local best = 0

    -- Finding optimal width size for name column.
    for i, row in ipairs(display_list) do
        local w = 0
        
        -- Finding the longest name or display name, depending on
        -- the state of display_details
        if display_details then
            for _,line in ipairs(row) do
                w = string.len(line[4])
            end
        else
            w = string.len(row[1])
        end

        -- Updating maximum
        if w > best then
            best = w
        end
    end

    if best > config.MAX_DISPLAY_NAME_LENGTH then best = config.MAX_DISPLAY_NAME_LENGTH end

    -- Beginning to print the results of the search
    if display_details then
        local detailed_rows = {}

        -- Extract lines from the groups returned by search_database_for_item
        for i,group in ipairs(display_list) do
            for j,line in ipairs(group) do
                -- Removing the first part of the id to only get the name and
                -- id of storage.
                line[1] = line[1]:match(":(.*)") or line[1]

                table.insert(line, 1, i)
                table.insert(detailed_rows, line)
            end
        end

        -- Print detailed display
        utils.paged_tabulate_fixed(
            detailed_rows,
            {"<#>","<Storage>", "@", "<s>", "<ID>", "x", "<Qty>", "<Nbt>"}, 
            {3,11,1,3,best,1,5,20},
            {false,true,false,false,false,false,false,false,}
        )
    else
        -- Sort results by quantity if search all
        if search_all then 
            utils.sort_results_from_db_search(display_list, 3, false)
        end

        for i,row in ipairs(display_list) do
            table.insert(row, 1, i)
        end
    
        utils.paged_tabulate_fixed(
            display_list, 
            {"<#>", "<Name>", "x", "<Qty>"}, 
            {4,best,1,6},
            {false,false,false}
        )
    end
else
    utils.log(("No results have been found for your search query <%s>"):format(search_query), INFO)
end

utils.log(("Search program ended.\n"):format(search_query), END)