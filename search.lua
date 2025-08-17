local config = require("config")
local utils = require("utils")

local INFO = utils.LOGTYPE_INFO

-- Getting the search query
local search_query = arg[1]

-- Opening the minecraft item ID list and storing it in a lua
-- object called itemreg
local ir_file = fs.open(config.REGISTRY_MINECRAFT_ITEMS_PATH, "r")
local ir_content = ir_file.readAll()
local itemreg = textutils.unserializeJSON(ir_content) 

local candidates = {}

for i,id in ipairs(itemreg) do    
    if string.find(id, search_query, 1, true) then
        
        table.insert(candidates, id)
    end
end

-- Opening and unserializing the database for search and storing
-- it in a lua object called database.
local db_file = fs.open(config.DATABASE_FILE_PATH, "r")
local db_content = db_file.readAll()
local database = textutils.unserializeJSON(db_content)

for i,c in ipairs(candidates) do
    local item_type = database[c]
    if item_type then
        for i,item in ipairs(item_type) do
            utils.log(("%s - %d x %s at slot %d"):format(
                    item.source, 
                    item.details.count, 
                    item.details.displayName, 
                    item.slot
            ),INFO)        
        end
    end
end
