-- # DASHOU'S ITEM MANAGER

-- ## Setup file

-- This file will install all needed files for DIM to run on this computer and
-- prompts the user for choices about the install such as names of input and output
-- storages.
--
-- Created : 17/08/2025
-- Updated : 25/08/2025

local constants = require("dim/lib/constants")
local utils = require("setup_utils")
local translations = require("dim/"..constants.CHOSEN_LANG)
local completion = require("cc.completion")

local INFO = constants.LOGTYPE_INFO
local ERROR = constants.LOGTYPE_ERROR

local INPUT_NAME = nil
local OUTPUT_NAME = nil
local STORAGE_TYPE = nil
local SPEAKER_NAME = nil
local PRINTER_NAME = nil

function Installation()
    -- total_steps = number of calls to update_progress()
    local total_steps = 10
    local nb_logs = 0
    local progress = 0
    local x,_ = term.getSize()
    local loading_bar_w = math.floor(x/2)

    local function updateProgress()
        utils.loading_bar(progress, loading_bar_w, colors.lightBlue, colors.white)
        progress = progress + (1/total_steps)
        os.sleep(0.1)
    end

    
    utils.reset_terminal()
    
    print()
    utils.print_align_left(translations.setup_installation_title)
    print()
    
    print()
    utils.print_align_left(translations.setup_installation_loading_label)
    print()
    
    
    local x_loading,y_loading = term.getCursorPos()
    
    local function logStep(step)
        term.setCursorPos(x_loading, y_loading+4+nb_logs)
        utils.print_align_left(step)
        nb_logs = nb_logs + 1
        term.setCursorPos(x_loading, y_loading)
    end

    updateProgress()
    logStep(translations.setup_installation_step_1)

    local config = {
        input=INPUT_NAME,
        output=OUTPUT_NAME,
        type=STORAGE_TYPE,
        printer=PRINTER_NAME,
        speaker=SPEAKER_NAME
    }

    -- copying the files from the install disk
    if not shell.run("cp /disk/dim/ /dim") then return 1 end

    updateProgress()
    logStep(translations.setup_installation_step_2)

    settings.load()
    updateProgress()

    settings.set("dim.config", config)
    updateProgress()

    settings.set("dim.scanned", false)
    updateProgress()

    settings.save()
    updateProgress()
    logStep(translations.setup_installation_step_3)

    local startup_file = utils.open_file("/startup.lua", "w")
    if not startup_file then return 1 end
    updateProgress()

    utils.write_file(startup_file, [[shell.run("/dim/home")]])
    updateProgress()

    utils.close_file(startup_file)
    updateProgress()
    logStep(translations.setup_installation_step_4)

    term.clearLine()
    utils.print_align_left(string.rep(" ", loading_bar_w), colors.white, colors.lightBlue)
    print()
    utils.print_align_left("100.0%")
    print()
    print()

    logStep(translations.setup_installation_done)

    utils.reset_terminal(colours.black, colours.white)

    utils.centered_window(
        translations.setup_installation_window_title,
        {translations.setup_installation_finished_1,"\n",translations.setup_installation_finished_2},
        colors.blue, colors.white, 2
    )

    while true do
        local _, key, _ = os.pullEvent("key")
        local pressed = keys.getName(key)
        if pressed == "enter" then return 0 end
    end
end

function PreInstallation()
    utils.reset_terminal()

    print()
    utils.print_align_left(translations.setup_preinstallation_title)
    print()

    print()
    utils.print_align_left(translations.setup_preinstallation_disclaimer_1)
    utils.print_align_left(translations.setup_preinstallation_disclaimer_2)
    
    print()
    print()
    utils.print_align_left(translations.setup_preinstallation_warning_1)

    print()
    utils.print_align_left(translations.setup_preinstallation_warning_2)
    utils.print_align_left(translations.setup_preinstallation_warning_3)
    utils.print_align_left(translations.setup_preinstallation_warning_4)

    print()
    print()

    utils.print_align_left(translations.setup_preinstallation_proceed)
    
    if utils.choice(
        translations.setup_preinstallation_prompt_return,
        translations.setup_preinstallation_prompt_install,
        2
    ) == 2 then return 0
    else return 1 end
end

function PeripheralCheck()

    local missing = false

    utils.log("Now scanning for required peripherals...", INFO)
    
    local speakers = { peripheral.find("speaker") }
    utils.log("Finished looking for speakers.", INFO)

    local printers = { peripheral.find("printer") }
    utils.log("Finished looking for printers.", INFO)

    utils.log("Peripheral scan complete", INFO)

    utils.reset_terminal()

    print()
    utils.print_align_left(translations.setup_periphcheck_title)
    print()

    print()
    if table.getn(speakers) == 0 then
        missing = true
        utils.print_align_left("- "..translations.setup_periphcheck_no_speakers)
    else 
        utils.print_align_left("- "..translations.setup_periphcheck_found_speakers) 
        for _, speaker in pairs(speakers) do
            SPEAKER_NAME = peripheral.getName(speaker)
        end
    end

    print()
    if table.getn(printers) == 0 then
        missing = true
        utils.print_align_left("- "..translations.setup_periphcheck_no_printers)
    else 
        utils.print_align_left("- "..translations.setup_periphcheck_found_printers) 
        for _, printer in pairs(printers) do
            PRINTER_NAME = peripheral.getName(printer)
        end
    end

    print()

    if missing then
        print()
        utils.print_centered(translations.setup_periphcheck_failed, colors.red, colors.gray)
        print()
        print()
        if utils.choice(
            translations.setup_periphcheck_choice_quit,
            translations.setup_periphcheck_choice_checkagain
        ) == 2 then return 2
        else return 1 end
    else
        print()
        utils.print_centered(translations.setup_periphcheck_success, colors.green, colors.gray)
        print()
        print()
        if utils.choice(
            translations.setup_periphcheck_choice_quit,
            translations.setup_periphcheck_choice_continue,
            2
        ) == 2 then return 0
        else return 1 end
    end
end

-- Get the type of storage the user wishes to use and
-- the name of storage they wishes to use as input and output.
function StorageCheck()
    utils.reset_terminal()

    print()
    utils.print_align_left(translations.setup_storagecheck_title)
    print()
    
    print()
    utils.print_align_left(translations.setup_prompt_type_storage_1)
    utils.print_align_left(translations.setup_prompt_type_storage_2)
    
    print()
    print()

    local function input_completer_type (text) return completion.choice(text, constants.AVAILABLE_STORAGE_TYPES) end

    local continue = false

    -- Getting input type
    while true do
        term.clearLine()
        local x, _ = term.getSize()
        write(string.rep(" ", math.floor(x/4)).."> ")
        STORAGE_TYPE = read(nil, nil, input_completer_type, "minecraft:")

        for _,s in ipairs(constants.AVAILABLE_STORAGE_TYPES) do
            local s_start, s_end = string.find(s, STORAGE_TYPE)
            if s_start == 1 and s_end == string.len(s)  then
                continue = true
            end
        end
        if continue then print() term.clearLine() break end

        print()
        term.clearLine()
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.black)
        utils.print_centered(translations.setup_prompt_type_wrong_type, colors.red, colors.grey)
        term.setBackgroundColor(colors.blue)
        term.setTextColor(colors.white)
        local _,y = term.getCursorPos()
        term.setCursorPos(1,y-3)
    end

    utils.print_centered(translations.setup_prompt_type_correct_type, colors.green, colors.gray)
    print()

    utils.print_align_left(translations.setup_prompt_type_storage_3)
    print()

    local p_names = peripheral.getNames()
    local function input_completer_input_output (text) return completion.choice(text, p_names) end
    
    -- Getting the input name
    continue = false
    while true do
        term.clearLine()
        local x, _ = term.getSize()
        write(string.rep(" ", math.floor(x/4)).."> ")
        INPUT_NAME = read(nil, nil, input_completer_input_output, "minecraft:")

        for _,s in ipairs(p_names) do
            local s_start, s_end = string.find(s, INPUT_NAME)
            if s_start == 1 and s_end == string.len(s)  then
                continue = true
            end
        end

        if continue then print() term.clearLine() break end

        print()
        term.clearLine()
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.gray)
        utils.print_centered(translations.setup_prompt_input_wrong_name)
        term.setBackgroundColor(colors.blue)
        term.setTextColor(colors.white)
        local _,y = term.getCursorPos()
        term.setCursorPos(1,y-3)
    end

    -- Removing the input inventory so the output can't be the input.
    for i=1,table.getn(p_names) do
        if p_names[i] == INPUT_NAME then
            table.remove(p_names, i)
        end
    end

    utils.print_centered(translations.setup_prompt_input_correct_name, colors.green, colors.gray)
    print()

    utils.print_align_left(translations.setup_prompt_type_storage_4)
    print()

    -- Getting the output name
    continue = false
    while true do
        term.clearLine()
        local x, _ = term.getSize()
        write(string.rep(" ", math.floor(x/4)).."> ")
        OUTPUT_NAME = read(nil, nil, input_completer_input_output, "minecraft:")

        for _,s in ipairs(p_names) do
            local s_start, s_end = string.find(s, OUTPUT_NAME)
            if s_start == 1 and s_end == string.len(s)  then
                continue = true
            end
        end

        if continue then print() term.clearLine() break end

        print()
        term.clearLine()
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.black)
        utils.print_centered(translations.setup_prompt_output_wrong_name, colors.red, colors.gray)
        term.setBackgroundColor(colors.blue)
        term.setTextColor(colors.white)
        local _,y = term.getCursorPos()
        term.setCursorPos(1,y-3)
    end

    utils.print_centered(translations.setup_prompt_output_correct_name, colors.green, colors.gray)
    print()

    print()
    if utils.choice(
        translations.setup_storagecheck_choice_return, 
        translations.setup_storagecheck_choice_continue,
        2
    ) == 2 then return 0
    else return 1 end
end

function Disclaimer()
    utils.reset_terminal()
    print()
    utils.print_align_left(translations.setup_disclaimer_title)
    print()
    print()
    utils.print_align_left(translations.setup_disclaimer_thanks)
    print()
    utils.print_align_left(translations.setup_disclaimer_text_0)
    print()

    utils.print_align_left(translations.setup_disclaimer_text_1)
    utils.print_align_left(translations.setup_disclaimer_text_2)
    print()
    print()
    utils.print_align_left(translations.setup_disclaimer_text_3)
    
    print()
    utils.print_align_left(translations.setup_disclaimer_text_4)
    utils.print_align_left(translations.setup_disclaimer_text_5)
    print()

    utils.print_align_left("- "..translations.setup_disclaimer_text_6)
    utils.print_align_left("- "..translations.setup_disclaimer_text_7)
    utils.print_align_left("- "..translations.setup_disclaimer_text_8)

    print()
    if utils.choice(
        translations.setup_disclaimer_choice_return, 
        translations.setup_disclaimer_choice_continue,
        2
    ) == 2 then return true
    else return false end
end

function Intro()
    term.setBackgroundColour(colours.blue)
    term.setTextColour(colours.white)

    local file_logo = utils.open_file(constants.ASCII_LOGO_FILE_PATH, "r")
    if not file_logo then return end

    local max_x, max_y = term.getSize()

    -- Setting the entire background blue
    for i=1,max_y do
        for j=1, max_x do
            print(" ")
        end
    end

    local x_start = math.floor(max_x/2)
    local y_start = 2

    while true do
        local line = file_logo.readLine()
        if not line then break end
        local len = string.len(line)
        term.setCursorPos(x_start-math.floor(len/2),y_start)
        y_start = y_start + 1
        if line then
            print(line)
        end
        os.sleep(0.1)
    end

    print()
    utils.print_centered("v. "..constants.dim_version)
    
    print()
    print()
    print()
    utils.print_centered(translations.setup_welcome_message_1)

    print()
    utils.print_centered(translations.setup_welcome_message_2)


    print()
    print()
    if utils.choice(
        translations.setup_welcome_choice_quit,
        translations.setup_welcome_choice_install,
        2
    ) == 2 then return true
    else 
        utils.reset_terminal(colours.black, colours.white)
        return false 
    end
end

-- Main program
local exit_code = 0

utils.reset_terminal(colours.blue, colours.white)

::intro::
if not Intro() then return end

::disclaimer::
if not Disclaimer() then goto intro end

::storage_check::
exit_code = StorageCheck()
if exit_code == 1 then goto disclaimer end

::peripheral_check::
exit_code = PeripheralCheck()
if exit_code == 2 then goto peripheral_check
elseif exit_code == 1 then goto storage_check end

exit_code = PreInstallation()
if exit_code == 1 then goto peripheral_check end

exit_code = Installation()
if exit_code == 1 then
    utils.log("An error occured during installation.", ERROR)
end

local drive = peripheral.find("drive")
drive.ejectDisk()
term.setTextColor(colours.white)
print()
print(translations.setup_installation_finished_3)
os.sleep(1)
os.reboot()
