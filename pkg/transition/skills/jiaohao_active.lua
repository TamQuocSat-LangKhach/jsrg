local jiaohao = fk.CreateSkill {
  name = "jiaohao"
}

Fk:loadTranslationTable{
  ['jiaohao&'] = '骄豪',
  ['#jiaohao&'] = '骄豪：你可以将手牌中的一张装备牌置入孙尚香的装备区',
  ['jiaohao'] = '骄豪',
  [':jiaohao&'] = '出牌阶段限一次，你可以将手牌中的一张装备牌置于孙尚香的装备区内。',
}

jiaohao:addEffect('active', {
  name = "jiaohao&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#jiaohao&",
  can_use = function(self, player)
    return player:usedSkillTimes(jiaohao.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and #selected_cards == 1 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local card = Fk:getCardById(selected_cards[1])
      return to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(jiaohao.name) and
        target:hasEmptyEquipSlot(card.sub_type)
    end
  end,
  on_use = function(self, room, effect)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      to = effect.tos[1],
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonPut,
      skillName = jiaohao.name,
    })
  end,
})

return jiaohao
