local js__tushe = fk.CreateSkill {
  name = "js__tushe"
}

Fk:loadTranslationTable{
  ['js__tushe'] = '图射',
  ['#js__tushe-invoke'] = '图射：你可以展示所有手牌，若其中没有基本牌，则摸%arg张牌',
  [':js__tushe'] = '当你使用非装备牌指定目标后，你可以展示所有手牌（没有手牌则跳过），若其中没有基本牌，则你摸X张牌（X为此牌指定的目标数）。',
  ['$js__tushe1'] = '非英杰不图？吾既谋之且射毕！',
  ['$js__tushe2'] = '汉室衰微，朝纲祸乱，必图后福。',
}

js__tushe:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(js__tushe.name) and player.room:getCard(event.data.card_id).type ~= Card.TypeEquip and data.firstTarget
  end,
  on_cost = function(self, event, target, player)
    local numTargets = #AimGroup:getAllTargets(data.tos)
    return player.room:askToSkillInvoke(player, {
      skill_name = js__tushe.name,
      prompt = "#js__tushe-invoke:::"..numTargets
    })
  end,
  on_use = function(self, event, target, player)
    if not player:isKongcheng() then
      player:showCards(player.player_cards[Player.Hand])
    end
    if player.dead then return end
    local basicCardCount = #table.filter(player:getCardIds(Player.Hand), function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic 
    end)

    if basicCardCount == 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      player:drawCards(#AimGroup:getAllTargets(data.tos), js__tushe.name)
    end
  end,
})

return js__tushe
