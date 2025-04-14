local js__cangchu = fk.CreateSkill {
  name = "js__cangchu"
}

Fk:loadTranslationTable{
  ['js__cangchu'] = '仓储',
  ['@js__cangchu'] = '仓储失效',
  ['#js__cangchu1-choose'] = '仓储：你可以令至多%arg名角色各摸一张牌',
  ['#js__cangchu2-choose'] = '仓储：你可以令至多%arg名角色各摸两张牌',
  [':js__cangchu'] = '每名角色的结束阶段，你可以令至多X名角色各摸一张牌；若X大于存活角色数，则改为各摸两张牌（X为你此回合得到过的牌数）。',
}

js__cangchu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and target.phase == Player.Finish and player:getMark("@js__cangchu") == 0 then
      local n = 0
      local max_num = #player.room.alive_players
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            n = n + #move.moveInfo
          end
        end
        return n > max_num
      end, Player.HistoryTurn)
      if n > 0 then
        event:setCostData(skill, n)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(skill)
    local targets = table.map(room.alive_players, Util.IdMapper)
    local prompt = "#js__cangchu1-choose:::"..x
    if x > #targets then
      x = #targets
      prompt = "#js__cangchu2-choose:::"..x
    end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = x,
      skill_name = skill.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      event:setCostData(skill, {tos = tos, num = tonumber(prompt:sub(13))})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = event:getCostData(skill).num
    for _, id in ipairs(event:getCostData(skill).tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:drawCards(num, js__cangchu.name)
      end
    end
  end,
})

return js__cangchu
