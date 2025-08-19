-- # DASHOU'S ITEM MANAGER

-- ## insert program

-- When this program is called, the content of the input
-- storage are scanned then directly sent to the storage
-- network.

-- Created : 18/08/2025
-- Updated : 18/08/2025

-- Getting libraries
local utils = require("lib/utils")
local config = require("lib/config")

-- Getting all log types
local DEBUG = config.LOGTYPE_DEBUG
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR
local BEGIN = config.LOGTYPE_BEGIN
local INFO = config.LOGTYPE_INFO
local END = config.LOGTYPE_END

-- Getting JSON files
local IN = config.INPUT_STORAGE_NAME
local DB = config.DATABASE_FILE_PATH

utils.reset_terminal()

local _, y_max = term.getSize()

-- Program startup
utils.log("Beginning insertion...", BEGIN)
utils.log("Scanning contents of desired input storage...", DEBUG)

-- Getting the input inventory ready
local input = peripheral.wrap(IN)
local input_stacks = input.list()

local inv_names = utils.get_json_file_as_object(config.INVENTORIES_FILE_PATH)
local db = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)

-- Checks if input inventory is empty.
function is_input_empty()
    local empty = true
    input_stacks = input.list()
    for _ in pairs(input_stacks) do
        empty = false
        
        if not empty then
            break
        end
    end
    return empty
end

-- Returns the amount of stacks present in the input inventory
function get_input_stack_count()
    local count = 0
    input_stacks = input.list()
    for _ in pairs(input_stacks) do
        count  = count + 1
    end
    return count
end

-- Finds the earliest available partially-filled-or-empty slot in
-- "inv" for the requested item_name. 
-- 
-- inv (peripheral)        : Inventory (wrapped) in which to find the slot
-- item_name (string)      : Name of item for which to find a slot.
-- max_stack_size (number) : Max stack size of the item.
-- quantity (number)       : Quantity to be inserted. Used for logging purposes.
-- nbt (string)            : Optional NBT value to differentiate items like tipped arrows.
function find_available_slot(inv, item_name, max_stack_size, quantity, nbt)
    -- Getting the item list of the output inventory
    local items = inv.list()
    
    -- Getting the number of slots of the output inventory
    local size = inv.size()
    local inv_name = peripheral.getName(inv)    
    
    -- Iterating on the items in the output inventory and
    -- try to find a partial stack containing the same item.
    -- This is done first to try to complete a stack rather than using
    -- an empty slot first.
    for slot, stack in pairs(items) do
        -- If found, put all possible items in this stack.
        if stack.name == item_name and stack.count < max_stack_size then
            -- If item has an NBT and is stackable (such as tipped arrows)
            -- Check if NBT is same as stack found. If not, go to next slot.
            if nbt ~= nil and stack.nbt ~= nbt then
                utils.log(("Found stack of similar item but different NBT values. Going to next slot."), DEBUG)
                goto continue
            end
            
            -- Getting the space left in the stack
            local space_left = max_stack_size - stack.count
            utils.log(("Found a partially filled slot (%d) in %s for %d x %s"):format(slot, inv_name, quantity, item_name), DEBUG)
            -- Information for pushItems so it pushes the correct amount of 
            -- items into the stack.
            return slot, space_left
        end
        -- To be able to continue in this loop. 
        -- Please add a continue statement Lua
        ::continue::
    end
    
    -- Logs if no partial storages were found.
    utils.log(("Didn't find a partially filled slot in %s. Looking for empty slots..."):format(peripheral.getName(inv)), DEBUG)
    
    -- Checks for empty slots now since no partial slots
    -- were found in inventory.
    for slot = 1, size do
        if items[slot] == nil then
            utils.log(("Found an empty slot (%d) in %s for %d x %s"):format(slot, inv_name, quantity, item_name), DEBUG)
            return slot
        end
    end
    
    -- If no empty slots nor partial slots were found in the
    -- inventory, then look in the next inventory.
    utils.log(("Didn't find an empty slot in %s. Skipping to next inventory."):format(inv_name), DEBUG)
    
    -- If there wasn't any space found for the item, leave it in input
    -- and see if next items can be placed in storage.
    return nil
end

-- Scanning for items in the input inventory.
if is_input_empty() then
    utils.log("No items in the input storage.", ERROR)
    return
end

function add_stack_to_db(section, slot, inv_name, details)
    if not db then return end

    if not db[section] then
        db[section] = {}
    end

    table.insert(db[section],{
            slot = slot,
            source = inv_name,
            ["details"] = details
    })
end

local incomplete_storing = true
local input_inventory_stack_count = get_input_stack_count()

local progress = 0
local input_stack_index = 0
-- Iterating over the items in the input storage. This is done first
-- so that each item can see the full storage and find the optimal
-- storing spot.
for input_slot, input_stack in pairs(input_stacks) do
    utils.log(("Now finding space for %d x %s"):format(input_stack.count, input_stack.name), DEBUG)
    -- Searching for an empty slot in the network, then pushing
    -- items slot by slot, for each empty slot found.
    ::search::
    -- Checking if the slot is empty
    if input_stacks[input_slot] ~= nil then
        -- Iterating over all of the storage inventories
        for _, output_name in ipairs(inv_names) do
            utils.log(("Checking %s..."):format(output_name), DEBUG)
            
            -- Getting the output inventory commands
            local output = peripheral.wrap(output_name)
            -- Getting the details of the stack so that we
            -- can obtain the maxCount variable.
            local stack_details = input.getItemDetail(input_slot) 

            local item_nbt = nil;
            if stack_details.nbt then
                item_nbt = stack_details.nbt
            end

            -- Finding a slot to put the stack in.
            local output_slot, remaining = find_available_slot(
                output,
                stack_details.name,
                stack_details.maxCount,
                stack_details.count,
                item_nbt
            )
            
            -- Inserted count will be used to update the JSON database.            
            local inserted_count = 0   
            local partial_insert = false

            -- Get the number of items inserted
            if remaining then 
                inserted_count = input.pushItems(
                    output_name, 
                    input_slot, 
                    remaining, 
                    output_slot
                )
                partial_insert = true
            else
                inserted_count = input.pushItems(
                    output_name,
                    input_slot,
                    stack_details.maxCount,
                    output_slot
                )
            end

            -- If any items were inserted and a slot was chosen,
            -- log the information. If the insertion inserted all of
            -- the items and did not take a fraction of the stack,
            -- break and go to the next item of input inventory.
            if inserted_count and output_slot then
                if not db then return end

                utils.log(("Inserted %d x %s in %s in slot %d"):format(inserted_count, input_stack.name, output_name, output_slot), DEBUG)                
                
                local section = db[stack_details.name]
                -- If we know a partial stack was modified
                if partial_insert and section then
                    utils.log("Updating existing stack in JSON database", DEBUG)
                    -- Find the object that represents 
                    -- the stack to update its count
                    for _, triple in ipairs(section) do
                        local db_details = triple["details"]
                        local db_slot = triple["slot"]
                        local db_source = triple["source"]

                        if output_slot == db_slot and output_name == db_source then
                            utils.log("Found correct stack in JSON file", DEBUG)
                            local db_count = db_details["count"]
                            db_details["count"] = db_count + inserted_count
                        end
                    end
                else
                    -- If we know an empty slot was used that means
                    -- a new stack has to be created in the JSON file under
                    -- the item section and that the section has to
                    -- potentially be created too
                    -- This does both.
                    
                    utils.log(("Adding new stack of %d x %s to the JSON database"):format(stack_details.count, stack_details.name), DEBUG)
                    add_stack_to_db(
                        stack_details.name, 
                        output_slot, 
                        output_name, 
                        stack_details
                    )
                end
            end

            if inserted_count == stack_details.count then
                break
            elseif inserted_count > 0 then
                -- If only a fraction of the input stack was
                -- because of completion of another stack,
                -- start search for the same slot again.
                utils.log("Fraction of stack was put in storage. Starting search again to find space for rest of the stack.", DEBUG)
                goto search
            end
        end
    end

    local x,y = term.getCursorPos()
    -- Check if inventory is empty after storing an item from input.
    -- If true, all items have been stored.
    if is_input_empty() then
        incomplete_storing = false
        term.clearLine()
        utils.log(("%.1f%% done."):format(100.0), INFO)
        term.setCursorPos(x,y)
    else
        progress = (input_stack_index/input_inventory_stack_count)*100
        term.clearLine()
        utils.log(("%.1f%% done."):format(progress), INFO)
        term.setCursorPos(x,y)
    end

    input_stack_index = input_stack_index + 1
end
    

-- If items are still left in the input storage
if incomplete_storing then
    utils.log("Not enough space was found to insert all items. Please connect additionnal storage or extract items. A list of the remaining items will be printed below.", WARN)
    
    -- Listing the input items left in the input inventory
    for slot, item in pairs(input_stacks) do
        utils.log(("%d x %s @ slot %d"):format(item.count, item.name,slot), INFO)
    end
else
    -- Otherwise, everything went well
    utils.log("Space was found for all items.", INFO)
end

-- Serializing our new db to JSON
local UPDATED_JSON_DB = textutils.serializeJSON(db)
local db_size = string.len(UPDATED_JSON_DB)

if not utils.check_db_size(db_size) then
    utils.log("Not enough free space on disk left to save new database. Exiting...", ERROR)
    return
end

-- Overwring the old db if enough space is found
utils.log("Overwriting old JSON database...", DEBUG)

if not utils.write_json_string_in_file(config.DATABASE_FILE_PATH, UPDATED_JSON_DB) then
    return
end

utils.log("Successfully updated JSON database", DEBUG)

-- End the program
utils.log("Insertion ended successfully.", END)