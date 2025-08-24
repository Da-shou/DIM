-- # DASHOU'S ITEM MANAGER

-- ## details program

-- When this program is called, it will display the maximum amount of information
-- about this item stack to the user. Can only be called from the search function
-- with simple results.
-- Usage : details <item_ID[string]> <nbt?[string]>

-- Created : 24/08/2025
-- Updated : 25/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR
local DEBUG = config.LOGTYPE_DEBUG
local TIMER = config.LOGTYPE_TIMER

local function end_program()
    utils.log("Ending details program.",END)
    print()
    return true
end

local start = utils.start_stopwatch()
-- Program startup
utils.log("Beginning details program.", BEGIN)

local ITEM_ID = arg[1]
local ITEM_NBT = arg[2]

---@diagnostic disable-next-line: cast-local-type
if ITEM_NBT == "nil" then ITEM_NBT = nil end

local db = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)
if not db then return end_program() end

local total = 0
local max_stack_size = 0
local display_name = nil
local max_durability = nil
local durability = nil
local tags = nil
local item_groups = nil
local enchantments = nil

for _,stack in ipairs(db[ITEM_ID]["stacks"]) do
    total = total + stack.details.count
    if stack.details.nbt == ITEM_NBT then
        if stack.details.displayName then display_name = stack.details.displayName end
        if stack.details.maxCount then max_stack_size = stack.details.maxCount end
        if stack.details.tags then tags = stack.details.tags end
        if stack.details.durability then durability = stack.details.durability end
        if stack.details.maxDamage then max_durability = stack.details.maxDamage end
        if stack.details.itemGroups then item_groups = stack.details.itemGroups end
        if stack.details.enchantments then enchantments = stack.details.enchantments end
    end
end

local stop = utils.stop_stopwatch(start)

textutils.pagedPrint(("\nID : %s"):format(ITEM_ID))
textutils.pagedPrint(("Name : %s"):format(display_name))
if ITEM_NBT then
    textutils.pagedPrint(("NBT : %s"):format(ITEM_NBT))
end

textutils.pagedPrint(("\nTotal : %d"):format(total))
textutils.pagedPrint(("Maximum stack size : %d"):format(max_stack_size))

if max_durability then
    textutils.pagedPrint(("\nMaximum durability : %d"):format(max_durability))
end

if durability then
    textutils.pagedPrint(("\nCurrent durability : %d/%d"):format(math.floor(durability*max_durability), max_durability))
end

if tags then
    local print_tags = {}
    local count = 0
    for tag, value in pairs(tags) do
        count = count + 1
        table.insert(print_tags, {tag, tostring(value)})
    end
    if count > 0 then
        textutils.pagedPrint(("\nFound %d tags :\n"):format(count))
        textutils.pagedTabulate(table.unpack(print_tags))   
    end
end

if item_groups and table.getn(item_groups) > 0 then
    textutils.pagedPrint(("\nFound %d item groups :"):format(table.getn(item_groups)))
    for _, group in ipairs(item_groups) do
        textutils.pagedPrint(("- %s"):format(group.displayName))
    end
end

if enchantments then
    textutils.pagedPrint(("\nFound enchantments :"))
    for _, e in ipairs(enchantments) do
        textutils.pagedPrint(("%s"):format(e.displayName))
    end
end

print()
utils.log("Press <ENTER> to extract item. Press <X> to return.", INFO)

while true do
    local _, key, _ = os.pullEvent("key")
    if keys.getName(key) == "enter" then
        if ITEM_NBT == nil then ITEM_NBT = "DEFAULT" end
        shell.run(("extract %s %s %s"):format(ITEM_ID, "nil", ITEM_NBT))
        os.queueEvent("quit", "quit")
        break
    elseif keys.getName(key) == "x" then
        break
    else end
end

print()
-- End program
utils.log(("<details> executed in %s"):format(stop), TIMER)
-- End program
utils.log("Details program successfully performed extraction.", INFO)
end_program()