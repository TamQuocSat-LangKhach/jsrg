local zhushou = fk.CreateSkill {
  name = "zhushou"
}

Fk:loadTranslationTable{
  ['zhushou'] = '诛首',
  ['#zhushou-choose'] = '诛首：你可对其中一名角色造成1点伤害',
  [':zhushou'] = '你失去过牌的回合结束时，你可以选择弃牌堆中本回合进入的点数唯一最大的牌，然后你对本回合失去过此牌的一名角色造成1点伤害。',
}

zhushou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if not (
      player:hasSkill(skill.name) and
      #room.logic:getEventsOfScope(
        GameEvent.MoveCards,
        1,
        function(e)
          return table.find(
            e.data,
            function(info)
              return info.from == player.id and
                table.find(
                  info.moveInfo,
                  function(moveInfo) 
                    return table.contains({ Card.PlayerHand, Card.PlayerEquip }, moveInfo.fromArea) 
                  end
                )
            end
          )
        end,
        Player.HistoryTurn
      ) > 0
    ) then
      return false
    end

    local cardWithBiggestNumber
    local biggestNumber = 0
    room.logic:getEventsOfScope(
      GameEvent.MoveCards,
      1,
      function(e)
        for _, info in ipairs(e.data) do
          if info.toArea == Card.DiscardPile then
            for _, moveInfo in ipairs(info.moveInfo) do
              if room:getCardArea(moveInfo.cardId) == Card.DiscardPile then
                local card = Fk:getCardById(moveInfo.cardId)
                if card.number > biggestNumber then
                  cardWithBiggestNumber = card.id
                  biggestNumber = card.number
                elseif card.number == biggestNumber then
                  cardWithBiggestNumber = nil
                end
              end
            end
          end
        end
        return false
      end,
      Player.HistoryTurn
    )

    if cardWithBiggestNumber then
      local targets = {}
      room.logic:getEventsOfScope(
        GameEvent.MoveCards,
        1,
        function(e)
          for _, info in ipairs(e.data) do
            if info.from and table.find(
              info.moveInfo,
              function(moveInfo)
                return moveInfo.cardId == cardWithBiggestNumber and 
                  table.contains({ Card.PlayerHand, Card.PlayerEquip }, moveInfo.fromArea)
              end
            ) then
              table.insertIfNeed(targets, info.from)
            end
          end
          return false
        end,
        Player.HistoryTurn
      )

      if #targets > 0 then
        event:setCostData(skill, targets)
        return true
      end
    end

    return false
  end,
  on_cost = function(self, event, player)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = event:getCostData(skill),
      min_num = 1,
      max_num = 1,
      prompt = "#zhushou-choose",
      skill_name = skill.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(skill, tos[1])
      return true
    end

    return false
  end,
  on_use = function(self, event, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    if to:isAlive() then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = skill.name
      }
    end
  end,
})

return zhushou
