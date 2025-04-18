local zhushou = fk.CreateSkill {
  name = "zhushou",
}

Fk:loadTranslationTable{
  ["zhushou"] = "诛首",
  [":zhushou"] = "你失去过牌的回合结束时，你可以选择弃牌堆中本回合进入的点数唯一最大的牌，你对本回合失去过此牌的一名角色造成1点伤害。",

  ["#zhushou-choose"] = "诛首：你可以对其中一名角色造成1点伤害",
}

zhushou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhushou.name) then
      local room = player.room
      local card
      local num = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(room.discard_pile) then
                if Fk:getCardById(info.cardId).number > num then
                  card = info.cardId
                  num = Fk:getCardById(info.cardId).number
                elseif Fk:getCardById(info.cardId).number == num then
                  card = nil
                end
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if card == nil then return end

      local targets = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from and table.find(move.moveInfo, function(info)
            return info.cardId == card and table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea)
          end) and not move.from.dead then
            table.insertIfNeed(targets, move.from)
          end
        end
      end,Player.HistoryTurn)
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = event:getCostData(self).tos,
      min_num = 1,
      max_num = 1,
      prompt = "#zhushou-choose",
      skill_name = zhushou.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = zhushou.name,
    }
  end,
})

return zhushou
