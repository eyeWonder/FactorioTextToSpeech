local textToSpeech = require "textToSpeech"

if not textToSpeechGui then textToSpeechGui = {} end

-----------------------------------------------------------------------------
-- Gets a list of the names of tts compatible voices.
--
-- @return        A table containing the localized names of compatible voices
-----------------------------------------------------------------------------
local function getCompatibleVoiceList()

  local voices = {}

  -- go through all instruments, if the name starts with "voice" then it's compatible,
  -- return the *localised* names in a list
  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if string.sub(v["name"],1,string.len("voice")) == "voice" then 
      table.insert( voices, {"programmable-speaker-instrument." .. v["name"]})
    end
  end

  return voices
end

-----------------------------------------------------------------------------
-- Creates the main gui (expanded gui) for a player.
--
-- @param player        The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function create_main_gui(player)

  local root
  
  if player.gui.top.text_to_speech_gui_root then
    root = player.gui.top.text_to_speech_gui_root
    else
      root = player.gui.top.add{
        type="frame",
        name="text_to_speech_gui_root",
        direction="vertical",
        style="outer_frame_style"
      }
  end


  root.add{
    type="sprite-button",
    name="toggle_gui_button",
    sprite="text-to-speech-logo-sprite",
    style="icon_button_style"
  }

  local main_frame = root.add{
    type="frame",
    name="main_frame",
    direction="vertical"
  }

  main_frame.add{
    type="label",
    name="title_label",
    caption="Text To Speech",
    style="frame_caption_label_style"
  }

  local action_buttons = main_frame.add{
    type="flow",
    name="action_buttons",
    direction="horizontal",
    style="description_flow_style"
  }
  
  action_buttons.add{
    type="textfield",
    name="input_field",
    text="",
    tooltip="Type input sentence here. You can create a custom word by writing a sequence of phonemes ".. 
    "(39 phonemes defined by CMU Pronouncing Dictionary, based on ARPAbet) each separated by a whitespace ".. 
    "and encapsulated with square brackets, e.g.\n\"[F AE K T AO R IY OW] is pretty neat\" \n would pronounce the ".. 
    "sentence:\n\"Factorio is pretty neat.\"" 
  }

  action_buttons.add{
    type="sprite-button",
    name="submit_button",
    sprite="text-to-speech-submit-sprite",
    tooltip="Click here with an empty blueprint to convert text to a speaker blueprint",
    style="slot_button_style"
  }
  
  local settings_container = main_frame.add{
    type="table",
    name="settings_container",
    colspan=2
  }

  settings_container.add{
    type="label",
    name="voice_label",
    caption="Voice"
  }

  settings_container.add{
    type="drop-down",
    name="voice_dropdown",
    items= getCompatibleVoiceList(),
    selected_index = 1
  }

    settings_container.add{
    type="label",
    name="global_playback_label",
    caption="Global Playback"
  }

  settings_container.add{
    type="checkbox",
    name="global_playback_checkbox",
    state=true
  }

  settings_container.add{
    type="label",
    name="block_width_label",
    caption="Blueprint Width"
  }

  settings_container.add{
    type="textfield",
    name="block_width_field",
    text="16",
    style="number_textfield_style"
  }

  settings_container.add{
    type="label",
    name="time_between_words_label",
    caption="Pause Length (ticks)"
  }

  settings_container.add{
    type="textfield",
    name="time_between_words_field",
    text="15",
    style="number_textfield_style"
  }

end

-----------------------------------------------------------------------------
-- Creates the hidden gui (collapsed gui, only tts icon) for a player.
--
-- @param player        The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function create_hidden_gui(player)
  
  local root

  if player.gui.top.text_to_speech_gui_root then
    root = player.gui.top.text_to_speech_gui_root
    else
      root = player.gui.top.add{
        type="frame",
        name="text_to_speech_gui_root",
        direction="vertical",
        style="outer_frame_style"
      }
  end

  root.add{
    type="sprite-button",
    name="toggle_gui_button",
    sprite="text-to-speech-logo-sprite",
    style="icon_button_style"
  }

end

-----------------------------------------------------------------------------
-- Toggles drawing either the hidden gui or the main gui.
--
-- @param player        The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function toggle_gui(player)
  
  -- if root has exactly one child (the hide button), create main gui
  if (#player.gui.top.text_to_speech_gui_root.children == 1) then
    --show gui
      player.gui.top.text_to_speech_gui_root.clear()
      create_main_gui(player)
    else
      -- hide gui
      player.gui.top.text_to_speech_gui_root.clear()
      create_hidden_gui(player)
  end
end

-----------------------------------------------------------------------------
-- Show an error gui (appends a frame to the bottom of the main gui) which
-- describes any errors that have occured for the player.
--
-- @param title       The title to use for the frame
-- @param message			The error message to show
-- @param player      The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function show_error_gui(title, message, player)
  
  local root = player.gui.top.text_to_speech_gui_root

  if not root.main_frame.error_frame then
    root.main_frame.add{
      type="frame",
      name="error_frame",
      direction="vertical"
    }
  end

  local errNum = #root.main_frame.error_frame.children/2

  root.main_frame.error_frame.add{
    type="label",
    name="error_label" .. errNum,
    caption=title,
    style="bold_red_label_style"
  }

  root.main_frame.error_frame.add{
    type="text-box",
    name="error_textbox" .. errNum,
    text=message,
    style="notice_textbox_style"
  }
  -- doesn't work inside instantiation?
  -- get last child from error frame
  root.main_frame.error_frame.children[#root.main_frame.error_frame.children].read_only = true
  root.main_frame.error_frame.children[#root.main_frame.error_frame.children].selectable = false
end

-----------------------------------------------------------------------------
-- Show a success gui (appends a frame to the bottom of the main gui) which
-- affirms to the player that the tts conversion was successful.
--
-- @param title       The title to use for the frame
-- @param message			The success message to show
-- @param player      The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function show_success_gui(title, message, player)
  
  local root = player.gui.top.text_to_speech_gui_root

  if not root.main_frame.success_frame then
    root.main_frame.add{
      type="frame",
      name="success_frame",
      direction="vertical"
    }
  end

  root.main_frame.success_frame.add{
    type="label",
    name="success_label",
    caption=title,
    style="bold_green_label_style"
  }

  root.main_frame.success_frame.add{
    type="text-box",
    name="success_textbox",
    text=message,
    style="notice_textbox_style"
  }
  -- doesn't work inside instantiation?
  -- get last child from success frame, and do the thing
  root.main_frame.success_frame.children[#root.main_frame.success_frame.children].read_only = true
  root.main_frame.success_frame.children[#root.main_frame.success_frame.children].selectable = false
end

-----------------------------------------------------------------------------
-- Get the instrument ID of a voice/instrument based on dropdown selection index.
--
-- @param selectedIndex       The index of the dropdown selection
--
-- @return										The corresponding instrument ID
-----------------------------------------------------------------------------
local function getDropDownVoiceInstrumentId(selectedIndex)

  -- same as getCompatibleVoiceList()
  -- but counts each compatible voice until it reaches the selected one.

  local counter = 1
  -- go through all instruments, if the name starts with "voice" (e.g. "voice1") then it's compatible,
  -- return the *localised* names as a table
  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if string.sub(v["name"],1,string.len("voice")) == "voice" then 
      if counter == selectedIndex then
        return k - 1
      end
      counter = counter + 1
    end
  end

end

-----------------------------------------------------------------------------
-- Formats a list of strings into one readable string and display it in an
-- error gui (show_error_gui).
--
-- @param title                     The title to use for the frame
-- @param unrecognisedThings        A table containing strings of unrecognised 
--                                  things, e.g. words, phonemes
-- @param player                    The player who you wish to draw the gui for.
--																	table of entities.
-----------------------------------------------------------------------------
local function show_unrecognised_things_error(title, unrecognisedThings, player)
  
  -- put unrecognised things table into a more readable string
  local outputStr = ""
  local counter = 0
  for _,word in ipairs(unrecognisedThings) do
    outputStr = outputStr .. word .. ", "
    counter = counter + 1
    if counter > 40 then
      outputStr = outputStr .. "\n"
      counter = 0
    end
  end

  -- remove last ", " in string
  outputStr = outputStr:sub(1, -3)

  show_error_gui(title, outputStr, player)

end

-----------------------------------------------------------------------------
-- Creates a Factorio blueprint, takes input from the in-game gui and uses
-- those parameters to do the text-to-speech conversion. 
-- The function will attempt to set the blueprint entities to the item in the
-- player's cursor_stack, which should be a blueprint.
--
-- @param player        The player who made the tts request
-----------------------------------------------------------------------------
local function generate_blueprint(player)

  local root = player.gui.top.text_to_speech_gui_root

  local inputText = root.main_frame.action_buttons.input_field.text
  local globalPlayback = root.main_frame.settings_container.global_playback_checkbox.state
  local blockWidth = tonumber(root.main_frame.settings_container.block_width_field.text)
  local pauseTime = tonumber(root.main_frame.settings_container.time_between_words_field.text)
  local instrumentID = getDropDownVoiceInstrumentId( root.main_frame.settings_container.voice_dropdown.selected_index )
  
  -- only take text after the period (e.g. programmable-speaker-instrument.voice1 -> voice1 )
  local instrumentName = string.match(root.main_frame.settings_container.voice_dropdown.get_item(root.main_frame.settings_container.voice_dropdown.selected_index)[1], "[^.]+$")

  -- if the old error frame is up, remove it in preparation for new errors
  if root.main_frame.error_frame then
    root.main_frame.error_frame.destroy()
  end
  -- same for the success frame
  if root.main_frame.success_frame then
    root.main_frame.success_frame.destroy()
  end

  -- attempt to convert text to speech
  local status, err, entities = pcall(textToSpeech.convertText,
      inputText,
      globalPlayback,
      blockWidth,
      pauseTime,
      instrumentID,
      instrumentName
    )

  if (status) and (player.cursor_stack.valid_for_read) and (player.cursor_stack.name == "blueprint") then
    player.cursor_stack.set_blueprint_entities(entities)
    show_success_gui("Success!", "The sentence has been added to your blueprint.", player)
  else
    -- if the player clicks the submit button with an empty cursor show error
    if not player.cursor_stack.valid_for_read then
      show_error_gui("Error - Cannot Detect Blueprint", "You clicked with an empty cursor\n"..
        "Click the button with an empty blueprint on the cursor instead.", player)
      
      -- if the player clicks with something that isn't a blueprint show error
      -- done in nested if because attempt to read cursor_stack of empty cursor fails and does not return nil,
      elseif not (player.cursor_stack.name == "blueprint") then
        show_error_gui("Error - Cannot Detect Blueprint", "You clicked with something that wasn't a blueprint.\n"..
          "Click the button with an empty blueprint on the cursor instead.", player)
    end
    
    local unrecognisedPhonemes = err[1]
    local unrecognisedWords = err[2]
    local parameterErrors = err[3]

    -- if has unrecognised phonemes show error
    if #unrecognisedPhonemes>0 then
      show_unrecognised_things_error("Error - Unrecognised Phonemes",unrecognisedPhonemes, player)
    end
    -- if has unrecognised words show error
    if #unrecognisedWords>0 then
      show_unrecognised_things_error("Error - Unrecognised Words",unrecognisedWords, player)
    end

    -- if has any parameter errors show them
    if #parameterErrors>0 then
      for _,info in pairs(parameterErrors) do
        local title = info[1]
        local message = info[2]
        show_error_gui(title, message, player)
      end
    end
    
  end
    
end

-----------------------------------------------------------------------------
-- Initializes the mod: initializes the textToSpeech module and draws the
-- gui for all players.
-----------------------------------------------------------------------------
function textToSpeechGui.mod_init()
  
  -- load word definitions and sound timings
  textToSpeech.init()

  for _, player in pairs(game.players) do
    create_hidden_gui(player)
  end

end

-----------------------------------------------------------------------------
-- On load the mod is initialized: initializes the textToSpeech module
-----------------------------------------------------------------------------
function textToSpeechGui.mod_on_load()
  textToSpeech.init()
end

-----------------------------------------------------------------------------
-- On new player joining, draw the gui for them.
-----------------------------------------------------------------------------
function textToSpeechGui.new_player(event)
  
  local player = game.players[event.player_index]
  
  create_hidden_gui(player)
    
end

-----------------------------------------------------------------------------
-- Should the mod be updated this function will be called to redraw the gui,
-- and reload stuff. (much here is unnecessary, but better safe than sorry?)
-----------------------------------------------------------------------------
function textToSpeechGui.mod_update(data)
  if data.mod_changes then
        if data.mod_changes["Text-To-Speech"] then
          --reload and redraw
          for _, player in pairs(game.players) do
            player.gui.top.text_to_speech_gui_root.destroy()
          end
          textToSpeechGui.mod_init()
        end
  end
end

-----------------------------------------------------------------------------
-- When a gui clickable is clicked by a player, take the corresponding action.
-----------------------------------------------------------------------------
function textToSpeechGui.on_gui_click(event)

  if event.element.name == "submit_button" then
    generate_blueprint(game.players[event.player_index])
    elseif event.element.name == "toggle_gui_button" then
      toggle_gui(game.players[event.player_index])
  end
  
end