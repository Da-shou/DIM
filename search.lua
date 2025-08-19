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

local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR

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

-- Opening the item ID list and storing it in a lua
-- object called itemreg
local itemreg = utils.prepare_registries()

local candidates = {}

for _,id in ipairs(itemreg) do  
    if string.find(string.lower(id), string.lower(search_query), 1, true) then
        table.insert(candidates, id)
    end
end

-- Opening and unserializing the database for search and storing
-- it in a lua object called database.
local database = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)
if not database then return end

-- Will contain the informations about the items.
local display_list = {}

-- Iterate over every possible item type that matches the search
for _,c in ipairs(candidates) do
    if database[c] then
        if database[c]["nbt"] then
            for _,nbt in ipairs(database[c]["nbt"]) do
                table.insert(display_list, (utils.search_database_for_item(database, c, display_details, nbt)))
            end
        else
            table.insert(display_list, (utils.search_database_for_item(database, c, display_details)))
        end
    end
end

-- Choose what to display based on the state of the display_details boolean.
if table.getn(display_list) > 0 then
    local best_displayname_width = 0

    -- Inserting id and finding optimal width size for name column.
    for i, row in ipairs(display_list) do
        table.insert(row, 1, i)

        local w = 0

        if display_details then
            w = string.len(row[2][4])
        else
            w = string.len(row[4])
        end

        if w > best_displayname_width then
            best_displayname_width = w
        end
    end

    if display_details then
        local detailed_rows = {}
        for _, row in ipairs(display_list) do
            table.insert(detailed_rows, {
                row[1], 
                row[2][1], 
                row[2][2],
                row[2][3],
                row[2][4],
                row[2][5],
                row[2][6],
            })
        end

        -- Setting the columns names and the white space.
        utils.paged_tabulate_fixed(
            detailed_rows,
            {"<#>","<Storage>", "@", "<s>", "<Name>", "x", "<Qty>"}, 
            {"","","","","","",""},
            {3,11,1,3,best_displayname_width,1,5},
            {false,false,true,false,false,true,false,false}
        )
    else
        utils.paged_tabulate_fixed(
            display_list, 
            {"<#>", "<Qty>", "x", "<Name>", "<NBT?>"}, 
            {"", "", "", "", ""},
            {4,5,1,best_displayname_width,6},
            {false,true,false,false}
        )
    end
else
    utils.log(("No results have been found for your search query <%s>"):format(search_query), INFO)
end

utils.log(("Search program ended.\n"):format(search_query), END)