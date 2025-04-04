local js__pianchong = fk.CreateSkill {
  name = "js__pianchong"
}

Fk:loadTranslationTable{
  ['js__pianchong'] = '偏宠',
  [':js__pianchong'] = '一名角色的结束阶段，若你于此回合内失去过牌，你可以判定，你摸X张牌（X为弃牌堆里于此回合内移至此区域的与判定结果颜色相同的牌数）。',
  ['$js__pianchong1'] = '承君恩露于椒房，得君恩宠于万世。',
  ['$js__pianchong2'] = '后宫有佳丽三千，然陛下独宠我一人。',
}

js__pianchong:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(js__pianchong.name) and target.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if not turn_event then return false end
      local end_id = turn_event.id
      return #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
        return false
      end, end_id) > 0
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local judge = {
      who = player,
      reason = js__pianchong.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    local color = judge.card.color
    if color == Card.NoColor then return false end

    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if not turn_event then return false end
    local end_id = turn_event.id
    local cards = {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if room:getCardArea(info.cardId) == Card.DiscardPile and Fk:getCardById(info.cardId).color == color then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      return false
    end, end_id)

    local x = #cards
    if x > 0 then
      room:drawCards(player, x, js__pianchong.name)
    end
  end,
})

return js__pianchong
