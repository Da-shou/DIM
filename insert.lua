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
local TIMER = config.LOGTYPE_TIMER

utils.reset_terminal()

local start = utils.start_stopwatch()
-- Program startup
utils.log("Beginning insertion...", BEGIN)
utils.log("Scanning contents of desired input storage...", DEBUG)

-- Getting the insertion inventory ready
local IN = config.INPUT_STORAGE_NAME
local input = peripheral.wrap(IN)
local input_stacks = input.list()

local inv_names = utils.get_json_file_as_object(config.INVENTORIES_FILE_PATH)
if not inv_names then
    utils.log([[No inventories were found in the inventories list. 
    Verify that your inventories are connected to the network and that the inventory program was run
    afterwards.]], ERROR)
    return
end

if not inv_names then
    utils.log("No database cache was found. Please run inventory program.", ERROR)
    return
end

-- Checks if input inventory is empty.
function is_input_empty()
    local empty = true
    input_stacks = input.list()
    for _,_ in pairs(input_stacks) do
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
function find_available_slot(database, item_name, max_stack_size, quantity, nbt)
    local skip_partial_search = false
    utils.log(("Starting slot search for %d x %s..."):format(quantity, item_name), DEBUG)

    -- If the max_stack_size is 1, no need to search for partial slots.
    if (max_stack_size == 1) then skip_partial_search = true end

    if not skip_partial_search then
        utils.log("Entering partial search...", DEBUG)
        -- Searching for partial stacks to complete.
        -- Search for partial stacks in database.
        local partial_stacks_search = utils.search_database_for_item(database,item_name,true,nbt,true)

        if partial_stacks_search then
            local stack_source  = nil
            local stack_slot = nil
            local stack_name = nil
            local stack_count = nil
            local stack_nbt = nil

            -- Iterating in the results
            for _,stack in ipairs(partial_stacks_search) do
                stack_source = stack.source
                stack_slot = stack.slot
                stack_name = stack.name
                stack_count = stack.count
                stack_nbt = stack.nbt

                if stack_name == item_name and stack_count < max_stack_size then
                    if nbt and stack_nbt ~= nbt then
                        utils.log(("Found stack of similar item but different NBT values. Going to next slot."), DEBUG)
                        goto continue
                    end
                                
                    -- Getting the space left in the stack
                    local space_left = max_stack_size - stack_count

                    utils.log(("Found a partially filled (%d items) slot (%d) in %s for %d x %s"):format(stack_count, stack_slot, stack_source, quantity, item_name), DEBUG)
                    -- Information for pushItems so it pushes the correct amount of 
                    -- items into the stack.
                    return {stack_slot, stack_source, space_left}
                end
                ::continue::
            end
        end
    end

    -- Logs if no partial storages were found.
    utils.log(("Didn't find a partially filled slot. Looking for empty slots..."), DEBUG)

    local empty_slots_search = utils.search_database_for_item(database, "empty_slot", true, nil, false)

    if table.getn(empty_slots_search) > 0 then
        utils.log("Found empty slot.", DEBUG)
        return {empty_slots_search[1].slot, empty_slots_search[1].source, nil}
    end

    -- If no empty slots nor partial slots were found in the
    -- inventory, then look in the next inventory
    utils.log(("Didn't find an empty slot."), DEBUG)
    
    -- If there wasn't any space found for the item, leave it in input
    -- and see if next items can be placed in storage.
    return nil
end

-- Scanning for items in the input inventory.
if is_input_empty() then
    utils.log("No items in the input storage.", ERROR)
    return
end

local incomplete_storing = true
local input_inventory_stack_count = get_input_stack_count()

local progress = 0
local input_stack_index = 0

local db = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)
if not db then
    utils.log("Database file could not be found.", ERROR) 
    return 
end

local stats = utils.get_json_file_as_object(config.STATS_FILE_PATH)
if not stats then 
    utils.log("Statistics file could not be found.", ERROR)
    return 
end

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

        local output_slot, output_name, nb_to_insert

        -- Getting the details of the stack so that we
        -- can obtain the maxCount variable.
        local stack_details = input.getItemDetail(input_slot) 

        local item_nbt = nil;

        if stack_details.nbt then
            item_nbt = stack_details.nbt
        end

        -- Finding a slot to put the stack in.
        local slot_search_results = find_available_slot(
            db,
            stack_details.name,
            stack_details.maxCount,
            stack_details.count,
            item_nbt
        )

        if slot_search_results then
            output_slot, output_name, nb_to_insert = table.unpack(slot_search_results)
                utils.log(("Found space for %d items in slot %d @ %s"):format(
                utils.fif(nb_to_insert, nb_to_insert, stack_details.maxCount), 
                output_slot,
                output_name), DEBUG)
        end

        -- Inserted count will be used to update the JSON database.            
        local inserted_count = 0   
        local partial_insert = false
            
        -- Get the number of items inserted
        if nb_to_insert then
            utils.log(("Pushing %d x <%s> in partial slot %d @ %s"):format(
                nb_to_insert, stack_details.displayName, output_slot, output_name
            ), DEBUG)
            partial_insert = true

            inserted_count = input.pushItems(
                output_name, 
                input_slot, 
                nb_to_insert, 
                output_slot
            )
        else
            utils.log(("Pushing %d x %s in empty slot %d @ %s"):format(
                stack_details.count, stack_details.displayName, output_slot, output_name
            ), DEBUG)

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
            utils.log(("Item push success!"), DEBUG)                
            local section = db[stack_details.name]
            
            -- If we know a partial stack was modified
            if partial_insert and section then
                utils.log("Updating partial stack in JSON database", DEBUG)
                -- Find the object that represents 
                -- the stack to update its count
                for _, triple in ipairs(section["stacks"]) do
                    textutils.tabulate(table.unpack(triple))
                    local db_details = triple["details"]
                    local db_slot = triple["slot"]
                    local db_source = triple["source"]

                    if output_slot == db_slot and output_name == db_source then
                        utils.log("Found correct stack in JSON file", DEBUG)
                        local db_count = db_details["count"]
                        utils.log(("%d => %d + %d"):format(db_count, db_count, inserted_count), DEBUG)
                        
                        if (db_count + inserted_count <= db_details["maxCount"]) then
                            db_details["count"] = db_count + inserted_count
                        else
                            utils.log("Tried to add too many items to a stack.", ERROR)
                        end
                    end
                end
            else
                -- If we know an empty slot was used that means
                -- a new stack has to be created in the JSON file under
                -- the item section and that the section has to
                -- potentially be created too
                -- This does both.
                
                utils.log(("Adding new stack of %d x %s to the JSON database"):format(stack_details.count, stack_details.name), DEBUG)
                utils.add_stack_to_db(
                    db,
                    stack_details.name, 
                    output_slot, 
                    output_name, 
                    stack_details
                )
                stats.used_slots = stats.used_slots + 1
            end
        end

        if inserted_count > 0 and inserted_count < stack_details.count then
            -- If only a fraction of the input stack was
            -- because of completion of another stack,
            -- start search for the same slot again.
            utils.log("Fraction of stack was put in storage. Starting search again to find space for rest of the stack.", DEBUG)
            goto search
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
local db_did_save = utils.save_database_to_JSON(db)

if not db_did_save then
    utils.log("Something bad happened during database writing. See above for more info.", ERROR)
    return
end

-- Writing the stats object to a new file.
local JSON_STATS = textutils.serializeJSON(stats)
utils.write_json_string_in_file(config.STATS_FILE_PATH, JSON_STATS)

local stop = utils.stop_stopwatch(start)

-- End program
utils.log(("<insert> executed in %s"):format(stop), TIMER)
-- End the program
utils.log("Insertion ended successfully.", END)