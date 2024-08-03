-- asp
-- v0.0.1 @jtopjian
--
-- A Norns MIDI snake sequencer
--
-- Asp generates a set of 16 random notes and then triggers
-- them via MIDI through a sequence of patterns.
--
-- Settings can be changed through the standard Norns settings page.
--
-- E1: Cycle through patterns
-- E2: Change the scale. Causes the pattern to regenerate.
-- E3: Change the root note. Causes the pattern to regenerate.

MusicUtil = require "musicutil"
NornsUtil = require "lib.util"

Patterns = include("lib/patterns")
Midi = include("lib/midi")

-- Version
VERSION = "0.0.1"

local pattern_idx = 1
local pattern_pos = 0
local sequence_pos = 1
local snake_pattern = {}
local sequence = {}

-- autosave parameters every 30s
function autosave_clock()
  clock.sleep(60)
  while true do
    clock.sleep(60)
    params:write()
  end
end

-- midi event monitoring
function clock.transport.start()
  pattern_pos = 0
  Midi.start()
end

function clock.transport.stop()
  Midi.stop()
end

function clock.transport.reset()
  Midi.stop()
  Midi.start()
end

function midi_event(data)
  msg = midi.to_msg(data)
  if msg.type == "start" then
    clock.transport.start()
  elseif msg.type == "continue" then
    if Midi.RUNNING then
      clock.transport.stop()
    else
      clock.transport.start()
    end
  end
  if msg.type == "stop" then
    clock.transport.stop()
  end
end

-- event loop
function step()
  while true do
    pattern_idx = Patterns.pattern_idx
    snake_pattern = Patterns.snake_patterns[pattern_idx]
    sequence = Patterns.sequence
    step_div = params:get("step_div")

    clock.sync(1/step_div)
    if Midi.RUNNING then
      pattern_pos = NornsUtil.wrap(pattern_pos+1, 1, 16)
      sequence_pos = snake_pattern[pattern_pos]
      note_num = sequence[sequence_pos]
      Midi.note_on(note_num, 0, 0, 0)
      if params:get("note_length") < 4 then
        Midi.schedule_note_off(note_num)
      end
      redraw()
    end
  end
end

function redraw()
  screen.level(1)
  screen.clear()
  screen.line_width(1)
  screen.font_size(8)
  screen.aa(0)

  screen_x = 5
  screen_y = 10
  screen.move(screen_x, screen_y)

  for row=0,15,4 do
    for col=1, 4 do
      i = row+col

      screen.level(3)
      if i == sequence_pos then
        screen.level(15)
      end

      note_num = sequence[i]
      note = MusicUtil.note_num_to_name(note_num, true)
      screen.text(note)

      screen_x = screen_x + 19
      screen.move(screen_x, screen_y)
    end
    screen_x = 5
    screen_y = screen_y + 15
    screen.move(screen_x, screen_y)
  end

  -- Print pattern number
  screen.level(3)
  screen_x = 84
  screen_y = 10
  screen.move(screen_x, screen_y)
  screen.text("P: " .. pattern_idx)

  -- Print scale
  scale_mode = Patterns.scale_mode
  screen_x = 84
  screen_y = 25
  screen.move(screen_x, screen_y)
  screen.text("S: " .. MusicUtil.SCALES[scale_mode].name)

  -- Print root note
  root_note = Patterns.root_note
  screen_x = 84
  screen_y = 40
  screen.move(screen_x, screen_y)
  screen.text("R: " .. MusicUtil.note_num_to_name(root_note, true))

  screen.update()
end

-- Encoder
function enc(n, d)
  if n == 1 then
    Patterns.pattern_idx = util.clamp(Patterns.pattern_idx + d, 1, 16)
  end

  if n == 2 then
    Patterns.scale_mode = util.clamp(Patterns.scale_mode + d, 1, #MusicUtil.SCALES)
    Patterns.build_notes()
    Patterns.build_sequence()
  end

  if n == 3 then
    Patterns.root_note = util.clamp(Patterns.root_note + d, 0, 127)
    Patterns.build_notes()
    Patterns.build_sequence()
  end
end

-- Keys
function key(n, z)
  if z == 1 then
    if n == 3 then
      if Midi.RUNNING then
        midi.RUNNING = 0
        clock.transport.stop()
      else
        midi.RUNNING = 1
        clock.transport.start()
      end
    end
  end
end

-- Start here
function init()
  params:add_separator("ASP")
  Patterns.add_params()
  Midi.add_params()
  params:default()
  Midi.midi_out_device.event = midi_event
  Patterns.build_sequence()
  autosave_clock_id = clock.run(autosave_clock)
  clock.run(step)
end

-- Cleanup here
function cleanup()
  clock.cancel(autosave_clock_id)
  params:write()
end
