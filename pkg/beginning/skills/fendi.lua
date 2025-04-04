local fendi = fk.CreateSkill {
  name = "fendi"
}

Fk:loadTranslationTable{
  ['fendi'] = '分敌',
  ['@@fendi-inhand'] = '分敌',
  ['#fendi_delay'] = '分敌',
  [':fendi'] = '每回合限一次，当你使用【杀】指定唯一目标后，你可以展示其至少一张手牌，然后令其只能使用或打出此次展示的牌直到此【杀】结算完毕。若如此做，当此【杀】对其造成伤害后，你获得其手牌区或弃牌堆里的这些牌。',
}

fendi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1 and not player.room:getPlayerById(data.to):isKongcheng() and
      player:usedSkillTimes(fendi.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = room:askToChooseCards(player, {
      min_num = 1,
      max_num = 999,
      flag = "h",
      skill_name = fendi.name,
      target = to
    })
    to:showCards(cards)
    if to.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(to:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event == nil then return end
    room:setPlayerMark(player, "fendi_record", {use_event.id, to.id, cards})
    local mark = to:getTableMark("fendi_prohibit")
    for _, id in ipairs(cards) do
      table.insertIfNeed(mark, id)
      room:addCardMark(Fk:getCardById(id), "@@fendi-inhand", 1)
    end
    room:setPlayerMark(to, "fendi_prohibit", mark)
  end,
})

fendi:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    local mark = player:getMark("fendi_record")
    if type(mark) == "table" then
      return mark[1] == player.room.logic:getCurrentEvent().id
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("fendi_record")
    local to = room:getPlayerById(mark[2])
    local cards = mark[3]
    room:setPlayerMark(player, "fendi_record", 0)
    if to.dead then return end
    local mark2 = to:getMark("fendi_prohibit")
    for _, id in ipairs(cards) do
      if table.removeOne(mark2, id) then
        room:removeCardMark(Fk:getCardById(id), "@@fendi-inhand", 1)
      end
    end
    room:setPlayerMark(to, "fendi_prohibit", #mark2 > 0 and mark2 or 0)
  end,
})

fendi:addEffect(fk.Damage, {
  name = "#fendi_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if data.card == nil or player.dead then return false end
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event == nil then return false end
    local mark = player:getMark("fendi_record")
    if type(mark) == "table" and mark[1] == use_event.id and mark[2] == data.to.id then
      return table.find(mark[3], function (id)
        return table.contains(room.discard_pile, id) or table.contains(data.to:getCardIds("h"), id)
      end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getMark("fendi_record")[3], function (id)
      return table.contains(room.discard_pile, id) or table.contains(data.to:getCardIds("h"), id)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, fendi.name, nil, true, player.id)
    end
  end,
})

fendi:addEffect('prohibit', {
  name = "#fendi_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("fendi_prohibit")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return #cardList > 0 and table.find(cardList, function (id)
      return not table.contains(mark, id)
    end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("fendi_prohibit")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return #cardList > 0 and table.find(cardList, function (id)
      return not table.contains(mark, id)
    end)
  end,
})

return fendi
