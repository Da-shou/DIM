-- # DASHOU'S ITEM MANAGER

-- ## insert program

-- When this program is called, the content of the input
-- storage are scanned then directly sent to the storage
-- network.

-- Created : 18/08/2025
-- Updated : 18/08/2025

local utils = require("lib/utils")
local config = require("lib/config")

local DEBUG = config.LOGTYPE_DEBUG
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR
local BEGIN = config.LOGTYPE_BEGIN
local INFO = config.LOGTYPE_INFO
local END = config.LOGTYPE_END

local IN = config.INPUT_STORAGE_NAME
local DB = config.DATABASE_FILE_PATH

utils.log("Scanning contents of desired input storage...", BEGIN)

local input = peripheral.wrap(IN)
local input_items = input.list()
local empty = true

function is_input_empty()
    local empty = true
    input_items = input.list()
    for _ in pairs(input_items) do
        empty = false
        
        if not empty then
            break
        end
    end
    return empty
end

-- Finds the earliest available partially-filled-or-empty slot in
-- "inv" for the requested item_name. 
function find_available_slot(inv, item_name, max_stack_size, quantity)
    local items = inv.list()
    local size = inv.size()
    local inv_name = peripheral.getName(inv)    
    
    for slot, stack in pairs(items) do
        if stack.name == item_name and stack.count ~= max_stack_size then
            local space_left = max_stack_size - stack.count
            utils.log(("Found a partially filled slot (%d) in %s for %d x %s"):format(slot, inv_name, quantity, item_name), INFO)
            return slot, space_left
        end
    end
    
    utils.log(("Didn't find a partially filled slot in %s. Looking for empty slots..."):format(peripheral.getName(inv)), DEBUG)
    
    for slot = 1, size do
        if items[slot] == nil then
            utils.log(("Found an empty slot (%d) in %s for %d x %s"):format(slot, inv_name, quantity, item_name), INFO)
            return slot
        end
    end
    
    utils.log(("Didn't find an empty slot in %s. Skipping to next inventory."):format(inv_name), DEBUG)
    
    return nil
end

-- Scanning for items in the input inventory.

if is_input_empty() then
    utils.log("No items in the input storage.", ERROR)
    return
end

utils.log("Beginning insertion.", DEBUG)

-- Reading through the storage names cached.
local inv_file = fs.open(config.INVENTORIES_FILE_PATH, "r")
local inv_file_content = inv_file.readAll()
local inv_names = textutils.unserializeJSON(inv_file_content)
inv_file.close()

-- Getting the item database as a lua object.
local db_file = fs.open(config.DATABASE_FILE_PATH, "r")
local db_file_content = db_file.readAll()
local db = textutils.unserializeJSON(db_file_content) 
db_file.close()


for input_slot, input_item in pairs(input_items) do
    utils.log(("Now finding space for %d x %s"):format(input_item.count, input_item.name), DEBUG)
    -- Searching for an empty slot in the network, then pushing
    -- items slot by slot, for each empty slot found.
    ::search::
    if input_items[input_slot] ~= nil then
        for _, output_name in ipairs(inv_names) do
            if is_input_empty() then break end
            
            utils.log(("Checking %s..."):format(output_name), DEBUG)
            local output = peripheral.wrap(output_name)
            local details = input.getItemDetail(input_slot) 
            
            local output_slot, remaining = find_available_slot(
                output,
                input_item.name,
                details.maxCount,
                details.count
            )
                        
            local inserted_count = 0   
            
            -- Get the number of items inserted
            if remaining then 
                inserted_count = input.pushItems(
                    output_name, 
                    input_slot, 
                    remaining, 
                    output_slot
                )
            else
                inserted_count = input.pushItems(
                    output_name,
                    input_slot,
                    details.maxCount,
                    output_slot
                )
            end
            
            if inserted_count and output_slot then
                utils.log(("Inserted %d x %s in %s in slot %d"):format(inserted_count, input_item.name, output_name, output_slot), DEBUG)                
                if inserted_count == input_item.count then
                    break
                else
                    goto search
                end
            end
        end
    end

    if is_input_empty() then
        break
    end
end
    

-- If items are still left in the input storage
if not is_input_empty() then
    utils.log("Not enough space was found to insert all items. Please connect additionnal storage or extract items. A list of the remaining items will be printed below.", WARN)
    
    for slot, item in pairs(input_items) do
        utils.log(("%d x %s @ slot %d"):format(item.count, item.name,slot), INFO)
    end
else
    utils.log("Space was found for all items.", INFO)
end

utils.log("Insertion ended successfully.", END)