-- # DASHOU'S ITEM MANAGER

-- ## extract program

-- When this program is called, it extracts a certain number
-- of items in the network.
-- Usage : extract <item_id[string]> <count[number]>

-- Created : 19/08/2025
-- Updated : 24/08/2025

local config = require("lib/config")
local utils = require("lib/utils")
local completion = require "cc.completion"

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR
local DEBUG = config.LOGTYPE_DEBUG
local TIMER = config.LOGTYPE_TIMER

utils.reset_terminal()

-- Program startup
utils.log("Beginning extraction program.", BEGIN)

local choices = utils.prepare_registries()
local function input_completer (text) return completion.choice(text, choices) end

local INPUT_ID = arg[1]
local INPUT_COUNT = nil
local INPUT_NBT = nil

if table.getn(arg) == 3 then
    INPUT_COUNT = nil
    INPUT_NBT = arg[3]
elseif table.getn(arg) == 2 then
    INPUT_COUNT = arg[2]
end

local function end_program()
    utils.log("Ending extraction program.",END)
    return true
end

-- Getting the extraction inventory ready
local OUT = config.OUTPUT_STORAGE_NAME
local output = peripheral.wrap(OUT)

if not INPUT_ID then
    utils.log("Please enter the ID of the item wanted.\n", INFO)
    write("> ")
    INPUT_ID = read(nil, nil, input_completer, "minecraft:")
    print()
end

for i,choice in ipairs(choices) do
    if INPUT_ID == choice then 
        utils.log("Correctly got ID from the registry in input.", DEBUG)
        break 
    end
    if i == table.getn(choices) then 
        utils.log("Input was not an ID from the registry. (Use the autocomplete feature!)", WARN)
        if end_program() then return end
    end
end

-- Getting the JSON database as a Lua object
local db = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)
if not db then
    utils.log("Database file was not found.", ERROR)
    return 
end

local stats = utils.get_json_file_as_object(config.STATS_FILE_PATH)
if not stats then
    utils.log("Stats file was not found.", ERROR)
    return 
end

local chosen_nbt = nil
if INPUT_NBT ~= "nil" then chosen_nbt = INPUT_NBT end
local storage_total = nil

if not chosen_nbt then
    -- Checking if the item section has nbt hashes
    if db[INPUT_ID] and table.getn(db[INPUT_ID]["nbt"]) > 0 then
        utils.log("Item requested has NBT hashes.", DEBUG)

        -- Getting all NBT hashes
        local nbt_hashes = db[INPUT_ID]["nbt"]

        -- Prepare table to show to user
        local nbt_display_data = {}
        local name_w = 0

        for _,hash in ipairs(nbt_hashes) do
            local nbt_search_results = utils.search_database_for_item(db, INPUT_ID, false, hash)
            local variant_display_name = nbt_search_results.displayName
            local variant_total = nbt_search_results.total

            local w = string.len(variant_display_name)
            if name_w < string.len(variant_display_name) then name_w = w end

            table.insert(nbt_display_data, {variant_display_name, "x", variant_total, hash})
        end

        -- Checking if there are items without NBT as well.
        local default_search_results = utils.search_database_for_item(db, INPUT_ID, false)

        if default_search_results then
            local default_display_name = default_search_results.displayName
            local default_total = default_search_results.total
            if default_total > 0 then
                table.insert(nbt_display_data, {default_display_name, "x", default_total, "DEFAULT"})
            end
        end

        chosen_nbt = utils.paged_tabulate_fixed_choice(
            nbt_display_data,
            {"<Name>", "<x>", "<Qty>", "<Nbt>"},
            {name_w, 3, 5, 32},
            {false,false,false,false}
        )[4]

        if not chosen_nbt then
            utils.log("Cancelling extraction.", INFO)
            if end_program() then return end
            return
        end

        storage_total = chosen_nbt[3]
    end
end

if chosen_nbt == "DEFAULT" then chosen_nbt = nil end

if not storage_total then
    local request = utils.search_database_for_item(db, INPUT_ID, false, chosen_nbt)

    -- Checking if item is in storage and enough items are in storage
    if not request then
        utils.log("Item could not be found in storage.", WARN)
        if end_program() then return end
    end

    storage_total = request.total
end

local REQUEST_COUNT = nil

utils.log(("%d items ready for extraction."):format(storage_total), DEBUG)

if storage_total > 1 then
    if INPUT_COUNT == nil or chosen_nbt then
        utils.log(("Please enter the amount wanted (%d in storage)\n"):format(storage_total), INFO)
        write("> ")
        INPUT_COUNT = read()
        print()
    end

    if INPUT_COUNT:match("^%d+$") then
        utils.log("Correctly got digit(s) in input.", DEBUG)
        REQUEST_COUNT = tonumber(INPUT_COUNT)
        if REQUEST_COUNT < config.MIN_EXTRACTION_REQUEST_COUNT or REQUEST_COUNT > config.MAX_EXTRACTION_REQUEST_COUNT then
            utils.log(([[Number entered is too low/high ! 
                Please enter a number between %d and %d]]):format(
                config.MIN_EXTRACTION_REQUEST_COUNT, 
                config.MAX_EXTRACTION_REQUEST_COUNT), WARN
            )
            if end_program() then return end
        else
            utils.log("Number entered is correctly in extraction range.", DEBUG)
        end
    end
else
    utils.log(("Only 1 %s found in storage. Extracting..."):format(INPUT_ID), DEBUG)
    REQUEST_COUNT = 1
end

if REQUEST_COUNT > storage_total then
    utils.log("Not enough items in storage to perform extraction.", END)
    if end_program() then return end
end

utils.log("Enough items are present in the storage to extract.", DEBUG)

utils.log("Now scanning for requested content...", DEBUG)
local start = utils.start_stopwatch()

-- Getting all stacks of needed items.
local item_stacks = utils.search_database_for_item(db, INPUT_ID, true, chosen_nbt)
local item_name = nil
local item_max_stacksize = 1

-- If the details were successfully obtained
if item_stacks[1] then
    item_name = item_stacks[1].name
    item_max_stacksize = item_stacks[1].maxCount
else
    utils.log("Details about the stacks could not be extracted.", ERROR)
    if end_program() then return end
end

-- Ask user to choose which item variant they want extracted.

utils.log(("Found max stack size for %s : %d"):format(item_name, item_max_stacksize), DEBUG)

-- Getting the number of stacks + rest to extract.
local nb_stack_toextract = math.floor(REQUEST_COUNT/item_max_stacksize)
local nb_rest_toextract = REQUEST_COUNT % item_max_stacksize

utils.log(("Found number of stacks to extract : %d"):format(nb_stack_toextract), DEBUG)
utils.log(("Found rest to extract : %d"):format(nb_rest_toextract), DEBUG)

-- We need one empty slot per stack extracted and another one for the rest if needed.
local min_slots_needed = nb_stack_toextract + utils.fif(nb_rest_toextract > 0, 1, 0)
local output_nb_usable_slots = 0
local output_content = output.list()

-- Checking if the slots are empty
for i=1,output.size() do
    if output_content[i] == nil then 
        output_nb_usable_slots = output_nb_usable_slots + 1
    end
end

-- If there aren't enough empty slots in the output.
if output_nb_usable_slots < min_slots_needed then
    utils.log(([[The output storage does not have enough free slots 
        to process this extraction. Please free %d slots and try again.
        DIM extraction always needs at least one empty 
        slot in output to function safely.]]):format(
        min_slots_needed-output_nb_usable_slots
    ), WARN)
    if end_program() then return end
end

local function search_and_extract_stack(item_stacks, count)
    if not count then count = item_max_stacksize end
    utils.log(("Searching for %d x %s."):format(count, item_name), DEBUG)

    local nb_needed = count
    local stacks_to_extract = {}

    -- Reiterate over the stacks to find stacks to combine to make
    -- an entire stack.
    for j,partial_stack in ipairs(item_stacks) do
        local partial_stack_source = partial_stack.source
        local partial_stack_slot = partial_stack.slot
        local partial_stack_count = partial_stack.count
        local partial_stack_nbt = partial_stack.nbt
        
        if nb_needed == 0 then break end
        
        utils.log(("Still need %d items."):format(nb_needed), DEBUG)
        if partial_stack_count <= nb_needed then
            -- If we found a stack whose entire count is under our
            -- needs, add it to the list and decrease the needed count.

            utils.log(([[Found stack with n.e/j.e (%d) to satisfy need (%d).]])
                :format(partial_stack_count, nb_needed), DEBUG)

            nb_needed = nb_needed - partial_stack_count
            table.insert(stacks_to_extract, {partial_stack, partial_stack_count})
            
            -- Removing the stack from the lua database object
            utils.remove_stack_from_db(
                db,
                item_name,
                partial_stack_slot, 
                partial_stack_source,
                partial_stack_nbt
            )

            stats.used_slots = stats.used_slots - 1

            table.remove(item_stacks, j)
        else
            -- We found a stack whose entire count is above our
            -- needs, so just substract our needed amount from the
            -- stack and update it in the database.

            utils.log(([[Found stack with too many items (%d) to satisfy need (%d).]])
                :format(partial_stack_count, nb_needed), DEBUG)
                
            local new_stack_count = partial_stack_count - nb_needed
            table.insert(stacks_to_extract, {partial_stack, nb_needed})

            -- Updating the stack in the lua database object
            utils.update_stack_count_in_db(
                db,
                item_name,
                partial_stack_slot,
                partial_stack_source,
                new_stack_count
            )
            
            -- So that the rest finding loop doesn't iterate over false data.
            partial_stack.count = new_stack_count
            nb_needed = 0
        end
    end

    local subtotal = 0

    -- Extract all partial stacks of items from storage
    -- to make up the stack.
    for j,data in ipairs(stacks_to_extract) do
        local stack_to_extract, count_to_extract = table.unpack(data)

        subtotal = subtotal + count_to_extract

        utils.log(([[Extracting partial stack %d (%d)]])
                :format(j, count_to_extract), DEBUG)

        utils.log(([[Progression : (%d/%d)]])
        :format(subtotal, count), DEBUG)

        -- Put stack in output inventory
        utils.log(("Pushing %d items to %s..."):format(count_to_extract, stack_to_extract.source), DEBUG)
        local inventory = peripheral.wrap(stack_to_extract.source)

        inventory.pushItems(OUT,stack_to_extract.slot,count_to_extract)
    end
end

--  1. Put stacks in output inventory
-- Sort results in descending order, so we have full stacks first.
utils.sort_results_from_db_search(item_stacks, "count", false)

-- Iterating on number of full stacks needed
if nb_stack_toextract > 0 then
    for _=1,nb_stack_toextract do
        search_and_extract_stack(item_stacks)
    end
end

--  2. Put rest in output inventory
-- Sorting the stacks left in ascending order to take smallest partial
-- stacks first to complete rest.
utils.sort_results_from_db_search(item_stacks, "count")

utils.log(("Now searching for rest (%d) of %s...")
    :format(nb_rest_toextract, item_name), DEBUG)

if nb_rest_toextract > 0 then
    search_and_extract_stack(item_stacks, nb_rest_toextract)
end

-- Writing database lua object to JSON
utils.log("Extraction to output storage successful.", DEBUG)
utils.log("Now writing changes to database...", DEBUG)
local db_did_write = utils.save_database_to_JSON(db)

if not db_did_write then
    utils.log(("There was an error during the writing of changes to database."), ERROR)
end

-- Writing the stats object to a new file.
local JSON_STATS = textutils.serializeJSON(stats)
utils.write_json_string_in_file(config.STATS_FILE_PATH, JSON_STATS)

local stop = utils.stop_stopwatch(start)

utils.log(("%d empty slots left."):format(stats.total_slots-stats.used_slots), INFO)
utils.log(("%.1f%% of empty slots used."):format((stats.used_slots/stats.total_slots)*100), INFO)

-- End program
print()
utils.log(("<extract> executed in %s"):format(stop), TIMER)
-- End program
utils.log("Extraction program successfully performed extraction.", INFO)

end_program()
