-- # DASHOU'S ITEM MANAGER

-- ## inventory program

-- When this program is called, it scans any storage from specified type in the config
-- file, then makes a JSON database with information about the
-- items present in it.

-- Created : 17/08/2025
-- Updated : 18/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local ERROR = config.LOGTYPE_ERROR
local DEBUG = config.LOGTYPE_DEBUG
local BEGIN = config.LOGTYPE_BEGIN
local END = config.LOGTYPE_END

local LM = config.LOADING_MODULO

local INPUT = config.INPUT_STORAGE_NAME
local OUTPUT = config.OUTPUT_STORAGE_NAME

-- Getting the peripherals
local names = peripheral.getNames()

utils.reset_terminal()

-- Parses through every peripherals in the network and if
-- their types is the storage type specifies, adds them
-- to a list. Exception for the input inventory specified
-- in the config file.
function get_inventories()
    local results = {}
    for i,name in ipairs(names) do
        local type = peripheral.getType(name)
        if type == config.STORAGE_TYPE and name ~= INPUT and name ~= OUTPUT then
            table.insert(results, name)
        end     
    end
    return results, table.getn(results) 
end

utils.log("Starting inventory program...", BEGIN)
utils.log("Searching for inventories on the network...", INFO)

-- Getting the inventories and the count
local inv_names, inv_count = get_inventories()

-- Creating the lua object that will hold all of our
-- item data which will then be serialized to JSON.
local database = {}

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
    for _ in pairs(inventory.list()) do
        slot_count = slot_count + 1
    end

    -- Parse the current inventory
    local current_slot_index = 0
    local emptyInv = true
    for slot, _ in pairs(inventory.list()) do
        emptyInv = false
        local details = inventory.getItemDetail(slot)
        
        -- Adding the items to the storage object.
        if details and details.name then
            utils.add_stack_to_db(database,details.name,slot,name,details)
        end

        -- Progress calculations
        inventory_progress = ((current_slot_index)/slot_count-1)/table.getn(inv_names)
        total_progress = ((inventory_progress) + (i / inventories_count))*100

        -- Logging progress
        if math.mod(loading_index,LM) == 0 then
            utils.log(("%.1f%% done."):format(total_progress), INFO)
            term.clearLine()
            term.setCursorPos(x,y)
        end

        current_slot_index = current_slot_index + 1
        loading_index = loading_index + 1
    end

    -- Update the loading if the inventory was empty
    if emptyInv then
        inventory_progress = 1/inventories_count
        total_progress = ((inventory_progress) + (i / inventories_count))*100
        utils.log(("%.1f%% done."):format(total_progress), INFO)
        term.clearLine()
        term.setCursorPos(x,y)
    end
end

term.clearLine()
term.setCursorPos(x,y)
utils.log(("100.0% done."), INFO)
utils.log("Indexing complete !", INFO)

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
utils.write_json_string_in_file(config.INVENTORIES_FILE_PATH, JSON_NAMES)

-- End program
utils.log("Inventory program successfully ended.", END)
