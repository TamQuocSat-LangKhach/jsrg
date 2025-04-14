local xunjim = fk.CreateSkill {
  name = "xunjim"
}

Fk:loadTranslationTable{
  ['xunjim'] = '勋济',
  ['#xunjim-give'] = '勋济：你可以分配这些牌，每名角色至多一张',
  [':xunjim'] = '结束阶段，若你于本回合对回合内你使用牌指定过的其他角色均造成过伤害，你可以将弃牌堆中本回合造成伤害的牌分配给至多等量角色各一张。',
}

xunjim:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xunjim.name) and player.phase == Player.Finish then
      local room = player.room
      local targets = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id then
          for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
            if id ~= player.id then
              table.insertIfNeed(targets, id)
            end
          end
        end
      end, Player.HistoryTurn)
      if #targets == 0 then return end
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.from == player then
          table.removeOne(targets, damage.to.id)
        end
      end, Player.HistoryTurn)
      if #targets > 0 then return end
      local cards = {}
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.card then
          table.insertTableIfNeed(cards, Card:getIdList(damage.card))
        end
      end, Player.HistoryTurn)
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards > 0 then
        event:setCostData(skill, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToYiji(player, {
      targets = room.alive_players,
      skill_name = xunjim.name,
      min_num = 1,
      max_num = 10,
      prompt = "#xunjim-give",
      cards = event:getCostData(skill),
      expand_pile = event:getCostData(skill),
      single_max = 1
    })
  end,
})

return xunjim
