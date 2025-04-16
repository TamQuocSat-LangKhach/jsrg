local niluan_active = fk.CreateSkill {
  name = "js__niluan_active",
}

Fk:loadTranslationTable{
  ["js__niluan_active"] = "逆乱",
  ["js__niluan_damage"] = "弃一张牌，对一名未对你造成过伤害的角色造成伤害",
  ["js__niluan_draw"] = "令一名对你造成过伤害的角色摸两张牌",
}

niluan_active:addEffect("active", {
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"js__niluan_damage", "js__niluan_draw"} },
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "js__niluan_damage" then
      return #selected == 0 and not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      if self.interaction.data == "js__niluan_damage" then
        return #selected_cards == 1 and not table.contains(player:getTableMark("js__niluan"), to_select.id)
      else
        return #selected_cards == 0 and table.contains(player:getTableMark("js__niluan"), to_select.id)
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data == "js__niluan_damage" then
      return #selected_cards == 1 and #selected == 1
    else
      return #selected_cards == 0 and #selected == 1
    end
  end,
})

return niluan_active
