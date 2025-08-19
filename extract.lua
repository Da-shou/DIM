-- # DASHOU'S ITEM MANAGER

-- ## extract program

-- When this program is called, it extracts a certain number
-- of items in the network.
-- Usage : extract <item_id[string]> <count[number]>

-- Created : 19/08/2025
-- Updated : 19/08/2025

local config = require("lib/config")
local utils = require("lib/utils")

local INFO = config.LOGTYPE_INFO
local BEGIN = config.LOGTYPE_BEGIN
local END = config.LOGTYPE_END
local WARN = config.LOGTYPE_WARNING
local ERROR = config.LOGTYPE_ERROR
local DEBUG = config.LOGTYPE_DEBUG

utils.reset_terminal()

-- Program startup
utils.log("Beginning extraction...", BEGIN)
utils.log("Scanning for requested content...", DEBUG)

local REQUEST_ID = arg[1]
local REQUEST_COUNT = arg[2]

-- Checking if first argument is 

-- Getting the extraction inventory ready
local OUT = config.OUTPUT_STORAGE_NAME
local input = peripheral.wrap(OUT)

local inv_names = utils.get_json_file_as_object(config.INVENTORIES_FILE_PATH)
local db = utils.get_json_file_as_object(config.DATABASE_FILE_PATH)

