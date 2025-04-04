local hujian = fk.CreateSkill {
  name = "hujian"
}

Fk:loadTranslationTable{
  ['hujian'] = '护剑',
  ['#hujian-invoke'] = '护剑：你可以获得弃牌堆中的【赤血青锋】',
  [':hujian'] = '游戏开始时，你从游戏外获得一张【赤血青锋】；一名角色回合结束时，此回合最后一名使用或打出过的牌的角色可以获得弃牌堆中的【赤血青锋】。',
}

hujian:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(hujian.name)
  end,
  on_cost = function(self, event, target, player)
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local card = room:printCard("blood_sword", Card.Spade, 6)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, hujian.name, nil, true, player.id)
  end,
})

hujian:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(hujian.name) then return false end
    local room = player.room
    return table.find(room.discard_pile, function(id) return Fk:getCardById(id).trueName == "blood_sword" end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local id = event:getCostData(hujian.name)
    if id ~= 0 and not room:getPlayerById(id).dead then
      return room:askToSkillInvoke(room:getPlayerById(id), { skill_name = hujian.name, prompt = "#hujian-invoke" })
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local id = event:getCostData(hujian.name)
    if id ~= 0 and not room:getPlayerById(id).dead then
      local p = room:getPlayerById(id)
      local card = room:getCardsFromPileByRule("blood_sword", 1, "discardPile")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonJustMove, hujian.name, nil, true, p.id)
      end
    end
  end,
})

return hujian
