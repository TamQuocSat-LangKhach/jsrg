local js__lirang = fk.CreateSkill{
  name = "js__lirang"
}

Fk:loadTranslationTable{
  ['js__lirang'] = '礼让',
  ['#js__lirang-invoke'] = '礼让：你可以将两张牌交给 %dest ，此回合弃牌阶段结束时获得其弃置的牌',
  [':js__lirang'] = '每轮限一次，其他角色摸牌阶段开始时，你可以交给其两张牌，然后此回合的弃牌阶段结束时，你获得其于此阶段所有弃置的牌。',
}

js__lirang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(js__lirang) and target.phase == Player.Draw and #player:getCardIds("he") > 1 and
      player:usedSkillTimes(js__lirang.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player)
    local cards = player.room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = js__lirang.name,
      cancelable = true,
      prompt = "#js__lirang-invoke::" .. target.id
    })
    if #cards == 2 then
      event:setCostData(self, {tos = {target.id}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "js__lirang-round", target.id)
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, target, fk.ReasonGive, js__lirang.name, nil, true, player.id)
  end,
})

js__lirang:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return target.phase == Player.Discard and player:usedSkillTimes(js__lirang.name, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player)
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == target.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end, Player.HistoryPhase)
    cards = table.filter(cards, function(id) return table.contains(room.discard_pile, id) end)
    if #cards == 0 then return end
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, js__lirang.name, nil, true, player.id)
  end,
})

return js__lirang
