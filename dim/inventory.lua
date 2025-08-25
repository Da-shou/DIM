-- # DASHOU'S ITEM MANAGER

-- ## inventory program

-- When this program is called, it scans any storage from specified type in the config
-- file, then makes a JSON database with information about the
-- items present in it.

-- Created : 17/08/2025
-- Updated : 24/08/2025

local constants = require("lib/constants")
local utils = require("lib/utils")

local INFO = constants.LOGTYPE_INFO
local ERROR = constants.LOGTYPE_ERROR
local DEBUG = constants.LOGTYPE_DEBUG
local BEGIN = constants.LOGTYPE_BEGIN
local END = constants.LOGTYPE_END
local TIMER = constants.LOGTYPE_TIMER

local LM = constants.LOADING_MODULO

local start = utils.start_stopwatch()

utils.log("Starting inventory program...", BEGIN)
utils.log("Searching for inventories on the network...", INFO)

-- Getting the peripherals
local names = peripheral.getNames()

utils.reset_terminal()

local storage_config = utils.get_json_file_as_object(constants.STORAGES_CONFIG_FILE_PATH)
if not storage_config then 
    utils.log("Could not find storage config file", ERROR)
    return
end

local INPUT = storage_config.input
local OUTPUT = storage_config.output

-- Parses through every peripherals in the network and if
-- their types is the storage type specifies, adds them
-- to a list. Exception for the input inventory specified
-- in the config file.
function get_inventories()
    local results = {}
    for _,name in ipairs(names) do
        local type = peripheral.getType(name)
        if type == storage_config.type and name ~= INPUT and name ~= OUTPUT then
            table.insert(results, name)
        end     
    end
    return results, table.getn(results) 
end

-- Getting the inventories and the count
local inv_names, inv_count = get_inventories()

-- Creating the lua object that will hold all of our
-- item data which will then be serialized to JSON.
local database = {}

local stats = {
    total_slots = 0,
    used_slots = 0
}

utils.log(("Now indexing storage with %d inventories...")
    :format(inv_count), INFO)

local total_progress = 0
local inventory_progress = 0
local loading_index = 0

local x,y = term.getCursorPos()

-- Parsing every inventory and adding the item infos to the
-- lua storage object.
for i,name in ipairs(inv_names) do    
    local inventory = peripheral.wrap(name)
    local inventories_count = table.getn(inv_names)

    -- Counting the items in the current inventory for loading
    -- display.
    local slot_count = 0
    for _=1,inventory.size() do
        slot_count = slot_count + 1
    end

    stats.total_slots = stats.total_slots + slot_count

    local list = inventory.list()
    
    -- If storage is completely empty
    if table.getn(list) == 0 then 
        for j=1, slot_count do
            term.clearLine()
            utils.log(("Found empty space in slot %d @ %s"):format(j,name), INFO)
            utils.add_stack_to_db(database,"empty_slot",j,name,{count = 0, maxCount = 0})

            -- Progress calculations
            inventory_progress = (j/slot_count-1)/inventories_count
            total_progress = ((inventory_progress) + (i / inventories_count))*100

            -- Logging progress
            if math.mod(loading_index,LM) == 0 then
                term.clearLine()
                utils.log(("%.1f%% done."):format(total_progress), INFO)
                term.setCursorPos(x,y)
            end
        end
        goto continue
    end

    -- Parse the current inventory
    for j=1,slot_count do
        if list[j] then
            local details = inventory.getItemDetail(j)
            term.clearLine()
            utils.log(("<%s> in slot %d @ %s"):format(details.name,j,name), INFO)
            -- Adding the items to the storage object.
            if details and details.name then
                utils.add_stack_to_db(database,details.name,j,name,details)
            end
            stats.used_slots = stats.used_slots + 1
        else
            term.clearLine()
            utils.log(("Found empty space in slot %d @ %s"):format(j,name), INFO)
            utils.add_stack_to_db(database,"empty_slot",j,name,{count = 0, maxCount = 0})
        end

        -- Progress calculations
        inventory_progress = (j/slot_count-1)/inventories_count
        total_progress = ((inventory_progress) + (i / inventories_count))*100

        -- Logging progress
        if math.mod(loading_index,LM) == 0 then
            term.clearLine()
            utils.log(("%.1f%% done."):format(total_progress), INFO)
            term.setCursorPos(x,y)
        end

        loading_index = loading_index + 1
    end

    ::continue::
end

term.clearLine()
term.setCursorPos(x,y)
utils.log(("100.0% done."), INFO)
utils.log("Indexing complete !", INFO)
utils.log(("%d inventories indexed."):format(inv_count), INFO)
utils.log(("%d empty slots left."):format(stats.total_slots-stats.used_slots), INFO)
utils.log(("%.1f%% of empty slots used."):format((stats.used_slots/stats.total_slots)*100), INFO)

local db_did_save = utils.save_database_to_JSON(database)

-- Checking if saving went smoothly
if not db_did_save then
    utils.log("Something bad happened during database writing. See above for more info.", ERROR)
    return
end

-- Writing the iventories name file.
local JSON_NAMES = textutils.serializeJSON(inv_names)

-- Writing the inventory names to a JSON file for future use by other
-- programs.
utils.write_json_string_in_file(constants.INVENTORIES_FILE_PATH, JSON_NAMES)

-- Writing the stats object to a new file.
local JSON_STATS = textutils.serializeJSON(stats)
utils.write_json_string_in_file(constants.STATS_FILE_PATH, JSON_STATS)

local stop = utils.stop_stopwatch(start)

-- End program
utils.log(("<inventory> executed in %s"):format(stop), TIMER)
utils.log("Inventory program successfully ended.", END)