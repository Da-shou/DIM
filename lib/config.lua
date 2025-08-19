-- # DASHOU'S ITEM MANAGER

-- ## Configuration file

-- This file contains all of the program configuration variables
-- that are shared between the files.

-- Created : 17/08/2025
-- Updated : 17/08/2025

local config = {}

-- Base path of the program
config.BASE_PATH = "/dim"

-- The location and name of the JSON file which will contain
-- the informations about each and every item.
config.DATABASE_FILE_PATH = config.BASE_PATH.."/storage/db.json"
config.INVENTORIES_FILE_PATH = config.BASE_PATH.."/storage/inventories.json"
-- The location and name of the JSON file containing the names
-- of all the items in the game. Allows for indexed searching in
-- the database.
config.REGISTRY_MINECRAFT_ITEMS_PATH = config.BASE_PATH.."/reg/minecraft.json"
config.REGISTRY_COMPUTERCRAFT_ITEMS_PATH = config.BASE_PATH.."/reg/computercraft.json"

config.REG_PATHS = {
    config.REGISTRY_MINECRAFT_ITEMS_PATH,
    config.REGISTRY_COMPUTERCRAFT_ITEMS_PATH
}

-- The type of inventory to scan for
config.STORAGE_TYPE = "minecraft:barrel"

-- The number of slots of a storage system
config.STORAGE_TYPE_SLOTS = 27

-- The network name of the input inventory
config.INPUT_STORAGE_NAME = "minecraft:barrel_204"

-- The modulo value to set the frequency of loading updates.
-- A higher value means less loading updates ; less screen clutter.
config.LOADING_MODULO = 1

config.MAX_DISPLAY_NAME_STRING_LENGTH = 25

-- Logging types to sort the different messages to the user.
config.LOGTYPE_DEBUG = "DEBUG"
config.LOGTYPE_ERROR = "ERROR"
config.LOGTYPE_WARNING = "WARNING"
config.LOGTYPE_SUCCESS = "SUCCESS"
config.LOGTYPE_INFO = "INFO"
config.LOGTYPE_END = "ENDING"
config.LOGTYPE_BEGIN = "BEGIN"

-- Change the different types of log messages to show during execution. 
-- I recommand to keep as default.
config.displayed_logtypes = {
    config.LOGTYPE_BEGIN,
    config.LOGTYPE_END,
    config.LOGTYPE_SUCCESS,
    config.LOGTYPE_INFO,
    config.LOGTYPE_ERROR,
    config.LOGTYPE_WARNING,
    --config.LOGTYPE_DEBUG,
}

return config
