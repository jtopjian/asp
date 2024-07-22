-- Snake Pattern information

MusicUtil = require "musicutil"

local Patterns = {}

-- Patterns are taken from
-- https://github.com/keenanmcdonald/descartes
Patterns.snake_patterns = {
  {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
  {1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13},
  {4,8,12,16,3,7,11,15,2,6,10,14,1,5,9,13},
  {1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4},
  {1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10},
  {13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6},
  {1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16},
  {1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4},
  {3,15,16,2,8,9,10,6,5,11,12,7,1,13,14,4},
  {1,8,11,15,5,2,9,12,13,6,3,10,16,14,7,4},
  {7,8,15,16,5,6,13,14,3,4,11,12,1,2,9,10},
  {7,15,8,16,5,13,6,14,3,11,4,12,1,9,2,10},
  {5,6,7,8,13,14,15,16,9,10,11,12,1,2,3,4},
  {2,10,9,1,4,12,11,3,6,14,13,5,8,16,15,7},
  {13,14,15,16,11,3,4,12,9,1,2,10,5,6,7,8},
  {9,13,12,16,3,7,2,6,11,15,10,14,1,5,4,8},
}
Patterns.pattern_idx = 0

Patterns.scale_names = {}
Patterns.scale_mode = ""
Patterns.root_note = ""
Patterns.notes = {}

Patterns.sequence = {}

function Patterns.build_notes()
  Patterns.notes = {}
  root_note = params:get("root_note")
  scale_mode = Patterns.scale_mode
  Patterns.notes = MusicUtil.generate_scale_of_length(root_note, scale_mode, 16)
  local num_to_add = 16 - #Patterns.notes
  for i = 1, num_to_add do
    table.insert(Patterns.notes, Patterns.notes[16 - num_to_add])
  end
end

function Patterns.add_params()
  -- build scales
  for i = 1, #MusicUtil.SCALES do
    table.insert(Patterns.scale_names, string.lower(MusicUtil.SCALES[i].name))
  end

  params:add_group("Scale", 2)
  params:add {
    type = "option",
    id = "scale_mode",
    name = "Scale Mode",
    options = Patterns.scale_names,
    default = 2,
    action = function(x)
      Patterns.scale_mode = x
      Patterns.build_notes()
      Patterns.build_sequence()
    end
  }

  params:add {
		type = "number",
		id = "root_note",
    name = "Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function(x)
      Patterns.root_note = x
      Patterns.build_notes()
      Patterns.build_sequence()
    end
  }

  params:add_group("Patterns", 1)
  params:add {
    type = "number",
    name = "Pattern",
    id = "pattern",
    min = 1,
    max = 16,
    default = 1,
    action = function(x)
      Patterns.pattern_idx = x
    end
  }
end

function Patterns.build_sequence()
  Patterns.build_notes()
  notes = Patterns.notes
  pattern = Patterns.pattern

  Patterns.sequence = {}
  for i = 1, 16 do
    table.insert(Patterns.sequence, notes[math.floor(math.random(#notes))])
  end
end

return Patterns
