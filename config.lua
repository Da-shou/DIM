-- # DASHOU'S ITEM MANAGER

-- ## Configuration file

-- This file contains all of the program configuration variables
-- that are shared between the files.

-- Created : 17/08/2025
-- Updated : 17/08/2025

local config = {}

-- The type of inventory to scan for
config.STORAGE_TYPE = "minecraft:barrel"

-- The network name of the input inventory
config.INPUT_STORAGE_NAME = "minecraft:barrel_204"

-- The modulo value to set the frequency of loading updates.
-- A higher value means less loading updates ; less screen clutter.
config.LOADING_MODULO = 7

-- The location and name of the JSON file which will contain
-- the informations about each and every item.
config.DATABASE_FILE_PATH = "/dim/storage/db.json"

return config
