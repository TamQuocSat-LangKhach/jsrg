local beginning = require "packages/jsrg/beginning"
local continue = require "packages/jsrg/continue"
local transition = require "packages/jsrg/transition"
local conclusion = require "packages/jsrg/conclusion"
local jsrg_cards = require "packages/jsrg/jsrg_cards"

Fk:loadTranslationTable{ ["jsrg"] = "江山如故" }

return {
  beginning,
  continue,
  jsrg_cards,
  transition,
  conclusion,
}
