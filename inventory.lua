-- # DASHOU'S ITEM MANAGER

-- ## inventory

-- Program that scans any storage from specified type in the config
-- file, then makes a JSON database with information about the
-- items present in it.

-- Created : 17/08/2025
-- Updated : 17/08/2025

local config = require("config")
local utils = require("utils")

local INFO = utils.LOGTYPE_INFO
local ERROR = utils.LOGTYPE_ERROR
local LM = config.LOADING_MODULO
local INPUT = config.INPUT_STORAGE_NAME

-- Getting the peripherals
local names = peripheral.getNames()

-- Parses through every peripherals in the network and if
-- their types is the storage type specifies, adds them
-- to a list. Exception for the input inventory specified
-- in the config file.
function getInventories()
    local results = {}
    for i,name in ipairs(names) do
        local type = peripheral.getType(name)
        if type == config.STORAGE_TYPE and name ~= INPUT then
            table.insert(results, name)
        end     
    end
    return results, table.getn(results) 
end

utils.log("Searching for inventories on the network...", INFO)

-- Getting the inventories and the count
local inv_names, inv_count = getInventories()

-- Creating the lua object that will hold all of our
-- item data which will then be serialized to JSON.
local storage = {}

utils.log(("Now indexing storage with %d inventories...")
    :format(inv_count), INFO)

local progress = 0

-- Parsing every inventory and adding the item infos to the
-- lua storage object.
for i,name in ipairs(inv_names) do    
    local inventory = peripheral.wrap(name)
    for slot, item in pairs(inventory.list()) do
        table.insert(storage,{
                location = name,
                name = item.name,
                count = item.count,
                slot = slot
        })
    end
    
    -- Logging progress
    if math.mod(i,LM) == 0 then
        progress = math.floor(((i-1)/inv_count)*100)
        utils.log(("%d%% done."):format(progress), INFO)
    end
end

utils.log("Indexing complete !", INFO)

-- Serializing our lua object to JSON
local JSON_DATABASE = textutils.serializeJSON(storage)

-- The size of the database is the length of the string (duh)
local db_size = string.len(JSON_DATABASE)

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

local file = fs.open(config.DATABASE_FILE_PATH, "w")
file.write(JSON_DATABASE)
file.close()
