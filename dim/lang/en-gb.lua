-- # DASHOU'S ITEM MANAGER

-- ## English (Great Britain) data file

-- This file will contain most of the text written to the user in english,
-- to make the app accessible in multiple languages in the future.

local translations = {}

translations.setup_welcome_message_1 = "Welcome to the DIM setup program !"
translations.setup_welcome_message_2 = "What would you like to do ?"
translations.setup_welcome_tutorial = "Choose with <LEFT> and <RIGHT>. Confirm with <ENTER>."
translations.setup_welcome_choice_install = "INSTALL DIM"
translations.setup_welcome_choice_quit = "QUIT DIM SETUP"

translations.setup_disclaimer_title = "DISCLAIMER"
translations.setup_disclaimer_welcome = "Welcome to the DIM Setup."
translations.setup_disclaimer_thanks = "Thank you for choosing DIM as your operating system!"
translations.setup_disclaimer_text_0 = "This Setup program prepares DIM to run on your computer."
translations.setup_disclaimer_text_1 = "In the next few steps, you will be able to"
translations.setup_disclaimer_text_2 = "configure certains aspects of your DIM installation."
translations.setup_disclaimer_text_3 = "Important :"
translations.setup_disclaimer_text_4 = "Make sure that these peripherals"
translations.setup_disclaimer_text_5 = "are connected to the computer's network."
translations.setup_disclaimer_text_6 = "At least 3 inventories."
translations.setup_disclaimer_text_7 = "At least 1 printer."
translations.setup_disclaimer_text_8 = "At least 1 speaker."
translations.setup_disclaimer_choice_return = "RETURN"
translations.setup_disclaimer_choice_continue = "CONTINUE SETUP"

translations.setup_storagecheck_title = "STORAGE CHECK"
translations.setup_prompt_type_storage_1 = "Please enter below the ID of the"
translations.setup_prompt_type_storage_2 = "storage type you would like to use with DIM."
translations.setup_prompt_type_storage_3 = "Please enter below the network name of the input storage."
translations.setup_prompt_input_correct_name = "Valid input inventory !"
translations.setup_prompt_input_wrong_name = "Invalid input inventory. Please retry."
translations.setup_prompt_type_storage_4 = "Please enter below the network name of the output storage."
translations.setup_prompt_output_correct_name = "Valid output inventory !"
translations.setup_prompt_output_wrong_name = "Invalid output inventory. Please retry."
translations.setup_prompt_type_wrong_type = "Not an accepted storage type. Please retry."
translations.setup_prompt_type_correct_type = "Valid storage type !"
translations.setup_storagecheck_choice_continue = "CONTINUE SETUP"
translations.setup_storagecheck_choice_return = "RETURN"

translations.setup_periphcheck_title = "PERIPHERAL CHECK"
translations.setup_periphcheck_no_speakers = "No speakers have been found"
translations.setup_periphcheck_found_speakers = "Speaker found."
translations.setup_periphcheck_no_printers = "No printers have been found"
translations.setup_periphcheck_found_printers = "Printer found."
translations.setup_periphcheck_failed = "Some peripherals could not be found."
translations.setup_periphcheck_success = "Peripherals successfully detected."
translations.setup_periphcheck_choice_checkagain = "RERUN CHECK"
translations.setup_periphcheck_choice_continue = "CONTINUE SETUP"
translations.setup_periphcheck_choice_quit = "RETURN"

translations.setup_preinstallation_title = "PRE-INSTALLATION"
translations.setup_preinstallation_disclaimer_1 = "All settings have been set."
translations.setup_preinstallation_disclaimer_2 = "You may now proceed with the installation."
translations.setup_preinstallation_warning_1 = "WARNING"
translations.setup_preinstallation_warning_2 = "Do NOT remove any peripherals during installation."
translations.setup_preinstallation_warning_3 = "Removing peripherals during installation may cause"
translations.setup_preinstallation_warning_4 = "severe damage to the computer."
translations.setup_preinstallation_proceed = "Proceed with DIM installation ?"
translations.setup_preinstallation_prompt_install = "INSTALL DIM"
translations.setup_preinstallation_prompt_return = "RETURN"

translations.setup_installation_title = "INSTALLING"
translations.setup_installation_loading_label = "Installing DIM on local disk..."
translations.setup_installation_done = "All done !"
translations.setup_installation_error = "An error occured during installation."
translations.setup_installation_finished_1 = "DIM was successfully installed on your computer."
translations.setup_installation_finished_2 = "Pressing <ENTER> will reboot your computer."

return translations