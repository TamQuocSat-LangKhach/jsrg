local js__niluan = fk.CreateSkill {
  name = "js__niluan"
}

Fk:loadTranslationTable{
  ['js__niluan_active'] = '逆乱',
  ['js__niluan'] = '逆乱',
}

js__niluan:addEffect('active', {
  mute = true,
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      local mark = player:getMark(js__niluan.name)
      if #selected_cards == 0 then
        return mark ~= 0 and table.contains(mark, to_select)
      else
        return mark == 0 or not table.contains(mark, to_select)
      end
    end
  end,
})

return js__niluan
