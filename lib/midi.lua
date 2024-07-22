-- MIDI Functions

local midi_out = {}

midi_out.midi_out_device = nil
midi_out.midi_out_channel = nil
midi_out.velocity = 100
midi_out.RUNNING = true

-- MIDI Parameters
function midi_out.add_params()
  local devices = {}
  for id, device in pairs(midi.vports) do
    devices[id] = device.name
  end

  params:add_group("MIDI", 4)

  -- Add MIDI device param
  params:add {
    type = "option",
    id = "midi_device",
    name = "Device",
    options = devices,
    default = 1,
    action = function(x)
      midi_out.midi_out_device = midi.connect(x)
    end
  }

  -- Add MIDI channel param
  params:add {
    type = "number",
    id = "midi_channel",
    name = "Channel",
    min = 1,
    max = 16,
    default = 1,
    action = function(x)
      midi_out.all_notes_off()
      midi_out.midi_out_channel = x
    end
  }

  -- Add velocity param
  params:add {
    type = "number",
    id = "velocity",
    name = "Velocity",
    min = 0,
    max = 127,
    default = 100,
    action = function(x)
      midi_out.velocity = x
    end
  }

  params:add_group("Asp: Step", 2)
  params:add {
    type = "number",
    id = "step_div",
    name = "Step Division",
    min = 1,
    max = 16,
    default = 4,
  }

  params:add {
    type = "option",
    id = "note_length",
    name = "Note Length",
    options = {"25%", "50%", "75%", "100%"},
    default = 4,
  }
end

-- MIDI Functions
function midi_out.start()
  midi_out.RUNNING = true
  midi_out.all_notes_off()
end

function midi_out.stop()
  midi_out.RUNNING = false
  midi_out.all_notes_off()
end

function midi_out.note_on(note)
  midi_out.midi_out_device:note_on(note, midi_out.velocity, midi_out.midi_out_channel)
end

function midi_out.note_off(note)
  midi_out.midi_out_device:note_off(note, nil, midi_out.midi_out_channel)
end

function midi_out.schedule_note_off(note)
  local clock_tempo = params:get("clock_tempo")
  local step_div = params:get("step_div")
  local note_length = params:get("note_length")
  sleeptime = (60 / clock_tempo / step_div) * note_length * 0.25
  clock.sleep(sleeptime)
  midi_out.note_off(note, midi_out.midi_out_channel)
end

function midi_out.all_notes_off()
  if midi_out.midi_out_device ~= nil then
    midi_out.midi_out_device:cc(123, 0, midi_out.midi_out_channel)
  end
end

return midi_out
