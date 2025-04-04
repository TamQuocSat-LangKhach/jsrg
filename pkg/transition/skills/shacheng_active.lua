local shacheng = fk.CreateSkill {
  name = "shacheng"
}

Fk:loadTranslationTable{
  ['shacheng_active'] = '沙城',
  ['shacheng'] = '沙城',
}

shacheng:addEffect('active', {
  mute = true,
  card_num = 1,
  target_num = 1,
  expand_pile = "shacheng",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:getPileNameOfId(to_select) == "shacheng"
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getMark("shacheng-tmp"), to_select)
  end,
})

return shacheng
