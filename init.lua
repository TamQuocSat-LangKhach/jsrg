local beginning = require "packages/jsrg/beginning"
local continue = require "packages/jsrg/continue"
local transition = require "packages/jsrg/transition"
local conclusion = require "packages/jsrg/conclusion"
local decline = require "packages/jsrg/decline"
local rise = require "packages/jsrg/rise"
local jsrg_cards = require "packages/jsrg/jsrg_cards"

Fk:loadTranslationTable{ ["jsrg"] = "江山如故" }

return {
  beginning,
  continue,
  transition,
  conclusion,
  decline,
  rise,

  jsrg_cards,
}
