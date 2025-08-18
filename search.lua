-- # DASHOU'S ITEM MANAGER

-- ## search program

-- When this program is called, the database is browsed
-- to see if an item corresponding to the query is found.

-- Created : 17/08/2025
-- Updated : 18/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local END = config.LOGTYPE_END
local ERROR = config.LOGTYPE_ERROR

-- Getting the search query
local search_query = arg[1]

if arg[1] == nil or arg[1] == "" then
    utils.log("Search query is empty!", ERROR)
    return
end

utils.log(("Starting search program with search query %s"):format(search_query), BEGIN)

-- Opening the minecraft item ID list and storing it in a lua
-- object called itemreg
local ir_file = fs.open(config.REGISTRY_MINECRAFT_ITEMS_PATH, "r")
local ir_content = ir_file.readAll()
local itemreg = textutils.unserializeJSON(ir_content) 

local candidates = {}

for _,id in ipairs(itemreg) do    
    if string.find(id, search_query, 1, true) then
        table.insert(candidates, id)
    end
end

-- Opening and unserializing the database for search and storing
-- it in a lua object called database.
local db_file = fs.open(config.DATABASE_FILE_PATH, "r")
local db_content = db_file.readAll()
local database = textutils.unserializeJSON(db_content)

for _,c in ipairs(candidates) do
    local item_type = database[c]
    if item_type then
        local total = 0
        for i,item in ipairs(item_type) do
            total = total + item.details.count
            utils.log(("%s - %d x <%s> at slot %d"):format(
                    item.source, 
                    item.details.count, 
                    item.details.displayName, 
                    item.slot
            ),INFO)        
        end
        utils.log(("TOTAL COUNT : %d\n"):format(total), INFO)
    end
end

utils.log(("Search program ended"):format(search_query), END)
