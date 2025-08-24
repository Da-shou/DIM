-- # DASHOU'S ITEM MANAGER

-- ## search program

-- When this program is called, the database is browsed
-- to see if an item corresponding to the query is found.
-- Usage : search <query[string]> <display_details[true|false]

-- Created : 17/08/2025
-- Updated : 24/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local DEBUG = config.LOGTYPE_DEBUG
local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local TIMER = config.LOGTYPE_TIMER

utils.reset_terminal()

local start = utils.start_stopwatch()

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
        local section_stacks = section["stacks"]
        if table.getn(section_stacks) > 0 then
            local section_nbt = section["nbt"]
            -- If section has NBT values
            if section_nbt and table.getn(section_nbt) > 0 then
                utils.log(("Found NBT section"), DEBUG)
                for _,stack in ipairs(section_stacks) do
                    -- Inserting each stack that has no NBT
                    if not stack.details.nbt then
                        table.insert(display_list, (utils.search_database_for_item(database, c, display_details)))
                        break
                    end
                end

                -- Inserting all stacks for each NBTs
                for _,nbt in ipairs(section_nbt) do
                    table.insert(display_list, (utils.search_database_for_item(database, c, display_details, nbt)))
                end
            else
                utils.log(("No NBT section."), DEBUG)
                local default_results = utils.search_database_for_item(database, c, display_details)
                if default_results then
                    table.insert(display_list, default_results)
                end
            end
        end
    end
end

local stop = utils.stop_stopwatch(start)

local choice = nil


::print_results::

-- Choose what to display based on the state of the display_details boolean.
if table.getn(display_list) > 0 then
    local best = 0

    -- Finding optimal width size for name column.
    for _, row in ipairs(display_list) do
        local w = 0
        -- Finding the longest name or display name, depending on
        -- the state of display_details
        if display_details then
            for _,line in ipairs(row) do
                w = string.len(line.name)
            end
        else
            w = string.len(row.displayName)
        end

        -- Updating maximum
        if w > best then
            best = w
        end
    end

    local max = utils.fif(
        display_details,
        config.MAX_DISPLAY_NAME_LENGTH,
        config.MAX_DISPLAY_DISPLAYNAME_LENGTH
    )

    if best > max then
        best = max
    end

    if best > config.MAX_DISPLAY_NAME_LENGTH then best = config.MAX_DISPLAY_NAME_LENGTH end
    local string_rows = {}

    -- Beginning to print the results of the search
    if display_details then
        -- Extract lines from the groups returned by search_database_for_item
        for i,group in ipairs(display_list) do
            for _,line in ipairs(group) do
                -- Removing the first part of the id to only get the name and
                -- id of storage.
                line.source = line.source:match(":(.*)") or line.source

                table.insert(string_rows,{
                    i,
                    line.source,
                    line.at,
                    line.slot,
                    line.name,
                    line.x,
                    line.count,
                    line.nbt
                })
            end
        end

        -- Print detailed display
        utils.paged_tabulate_fixed(
            string_rows,
            {"<#>","<Storage>", "@", "<s>", "<ID>", "x", "<Qty>", "<Nbt>"}, 
            {3,11,1,3,best,1,5,32},
            {false,false,false,false,false,false,false,false}
        )
    else
        -- Sort results by quantity if search all
        if search_all then 
            utils.sort_results_from_db_search(display_list, "total", false)
        end

        for i,item in ipairs(display_list) do
            table.insert(string_rows,{
                i,
                item.displayName,
                item.x,
                item.total,
                item.name
            })
        end
    
        choice = utils.paged_tabulate_fixed_choice(
            string_rows, 
            {"<#>", "<Name>", "x", "<Qty>", "<ID>"}, 
            {4,best,1,6,30},    
            {false,false,false,false}
        )
    end
else
    utils.log(("No results have been found for your search query <%s>"):format(search_query), INFO)
end

if choice then
    local choice_id = choice[5]
    local choice_index = tonumber(choice[1])
    local choice_nbt = display_list[choice_index].nbt

    shell.run(("details %s %s"):format(choice_id, choice_nbt))

    local eventData = {os.pullEventRaw()}
    local event = eventData[1]
    
    if event == "char" and eventData[2] == "x" then
        goto print_results
    else end
end

-- End program
utils.log(("<search> executed in %s"):format(stop), TIMER)
utils.log(("Search program ended.\n"):format(search_query), END)