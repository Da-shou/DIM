-- # DASHOU'S ITEM MANAGER

-- ## Configuration file

-- This file contains all of the program configuration variables
-- that are shared between the files.

-- Created : 17/08/2025
-- Updated : 24/08/2025

local constants = {}

constants.dim_version = "Alpha 0.1.5"

-- Base path of the program
constants.BASE_PATH = "/dim"

if fs.exists("/disk") then
	constants.BASE_PATH = "/disk/dim"
end

-- Chosen language for the app to run on.
constants.CHOSEN_LANG = "lang/en-gb"

constants.AVAILABLE_STORAGE_TYPES = {
    "minecraft:barrel",
    "minecraft:chest"
}

-- The location and name of the JSON file which will contain
-- the informations about each and every item.
constants.DATABASE_FILE_PATH = constants.BASE_PATH.."/storage/db.json"
constants.INVENTORIES_FILE_PATH = constants.BASE_PATH.."/storage/inventories.json"
constants.STATS_FILE_PATH = constants.BASE_PATH.."/storage/stat.json"
constants.STORAGES_CONFIG_FILE_PATH = "/dim/config/storages.json"
constants.ASCII_LOGO_FILE_PATH = constants.BASE_PATH.."/ascii/dim_logo.txt"

-- The location and name of the JSON file containing the names
-- of all the items in the game. Allows for indexed searching in
-- the database.
constants.REGISTRY_MINECRAFT_ITEMS_PATH = constants.BASE_PATH.."/reg/minecraft.json"
constants.REGISTRY_COMPUTERCRAFT_ITEMS_PATH = constants.BASE_PATH.."/reg/computercraft.json"

constants.REG_PATHS = {
    constants.REGISTRY_MINECRAFT_ITEMS_PATH,
    constants.REGISTRY_COMPUTERCRAFT_ITEMS_PATH
}

-- Will show the logs marked as "DEBUG"
constants.SHOW_DEBUG = false

-- The type of inventory to scan for
constants.STORAGE_TYPE = "minecraft:barrel"

-- The number of slots of a storage system
constants.STORAGE_TYPE_SLOTS = 27

-- The network name of the insertion inventory
constants.INPUT_STORAGE_NAME = "minecraft:barrel_155"
-- The network name of the extraction inventory
constants.OUTPUT_STORAGE_NAME = "minecraft:barrel_154"

constants.MIN_EXTRACTION_REQUEST_COUNT = 1
constants.MAX_EXTRACTION_REQUEST_COUNT = 1728 -- 64 x 27

constants.MAX_DISPLAY_DISPLAYNAME_LENGTH = 38
constants.MAX_DISPLAY_NAME_LENGTH = 26
-- The modulo value to set the frequency of loading updates.
-- A higher value means less loading updates ; less screen clutter.
constants.LOADING_MODULO = 1

-- Logging types to sort the different messages to the user.
constants.LOGTYPE_DEBUG = "DEBUG"
constants.LOGTYPE_ERROR = "ERROR"
constants.LOGTYPE_WARNING = "WARNING"
constants.LOGTYPE_SUCCESS = "SUCCESS"
constants.LOGTYPE_INFO = "INFO"
constants.LOGTYPE_END = "ENDING"
constants.LOGTYPE_BEGIN = "BEGIN"
constants.LOGTYPE_TIMER = "TIMER"

return constants
