local ninghan = fk.CreateSkill {
  name = "ninghan"
}

Fk:loadTranslationTable{
  ['ninghan'] = '凝寒',
  ['#ninghan_trigger'] = '凝寒',
  ['#ninghan-invoke'] = '凝寒：是否将%arg置为“沙城”？',
  ['shacheng'] = '沙城',
  [':ninghan'] = '锁定技，所有角色手牌中的♣【杀】均视为冰【杀】；当一名角色受到冰冻伤害后，你可以将造成此伤害的牌置于武将牌上。',
}

ninghan:addEffect('filter', {
  card_filter = function(self, player, to_select)
    return RoomInstance and table.find(RoomInstance.alive_players, function (p) return p:hasSkill(ninghan.name) end) and
      to_select.suit == Card.Club and to_select.trueName == "slash" and
      table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("ice__slash", Card.Club, to_select.number)
    card.skillName = ninghan.name
    return card
  end,
})

ninghan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ninghan.name) and not target.dead and data.damageType == fk.IceDamage and data.card and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = "ninghan",
      prompt = "#ninghan-invoke:::" .. data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("shacheng", data.card, true, "ninghan")
  end,
})

return ninghan
