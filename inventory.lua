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

-- Getting the peripherals
local names = peripheral.getNames()

term.clear()
term.setCursorPos(1,1)

-- Parses through every peripherals in the network and if
-- their types is the storage type specifies, adds them
-- to a list. Exception for the input inventory specified
-- in the config file.
function get_inventories()
    local results = {}
    for i,name in ipairs(names) do
        local type = peripheral.getType(name)
        if type == config.STORAGE_TYPE and name ~= INPUT then
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
local storage = {}

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
    local inventories_count = #inv_names

    -- Counting the items in the current inventory for loading
    -- display.
    local slot_count = 0
    for _ in pairs(inventory.list()) do
        slot_count = slot_count + 1
    end

    local current_slot_index = 0
    local emptyInv = true
    for slot, _ in pairs(inventory.list()) do
        emptyInv = false
        local details = inventory.getItemDetail(slot)            
        if details and details.name then
            if not storage[details.name] then
                storage[details.name] = {}
            end
            table.insert(storage[details.name], {
                slot = slot,
                source = name,
                ["details"] = details
            })
        end

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
utils.log(("100% done."), INFO)
utils.log("Indexing complete !", INFO)

-- Serializing our lua object to JSON
local JSON_DATABASE = textutils.serializeJSON(storage)
local JSON_NAMES = textutils.serializeJSON(inv_names)

-- The size of the database is the length of the string (duh)
local storage_size = string.len(JSON_DATABASE)
local names_size = string.len(JSON_NAMES)
local db_size = storage_size + names_size

local unit_char = ""
local unit_div = 1

-- Picking an adequate size for the size printing.
if db_size >= 1000000 then
    unit_char = "M"
    unit_div = 1048576
elseif db_size >= 1000 then
    unit_char = "k"
    unit_div = 1024
end

utils.log(("New database size is %.3f%sB."):format(db_size/unit_div, unit_char), INFO)

-- Returning if there isn't enough space on the disk.
if db_size >= fs.getFreeSpace("/dim") then
    utils.log("Not enough free space on disk left to save new database. Exiting...", ERROR)
    return
end

-- Writing the database in the db.json file.
local file = fs.open(config.DATABASE_FILE_PATH, "w")
file.write(JSON_DATABASE)
file.close()

-- Writing the inventory names to a file for future use by other
-- programs.
local file = fs.open(config.INVENTORIES_FILE_PATH, "w")
file.write(JSON_NAMES)
file.close()

utils.log("Inventory program successfully ended.", END)