local premeditate_prohibit = fk.CreateSkill {
  name = "premeditate_prohibit"
}

Fk:loadTranslationTable{ }

premeditate_prohibit:addEffect('prohibit', {
  global = true,
  prohibit_use = function(self, player, card)
    return card and player:getMark("premeditate_" .. card.trueName .. "-phase") > 0
  end,
})

return premeditate_prohibit
