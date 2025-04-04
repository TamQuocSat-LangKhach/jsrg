local qiluanChooser = fk.CreateSkill {
  name = "js__qiluan_chooser"
}

Fk:loadTranslationTable{
  ['js__qiluan_chooser'] = '起乱',
}

qiluanChooser:addEffect('active', {
  min_card_num = 1,
  min_target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < #selected_cards and player.id ~= to_select
  end,
})

return qiluanChooser
