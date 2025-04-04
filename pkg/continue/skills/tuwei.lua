local tuwei = fk.CreateSkill {
  name = "tuwei"
}

Fk:loadTranslationTable{
  ['tuwei'] = '突围',
  ['#tuwei-choose'] = '突围：你可以获得攻击范围内任意名角色各一张牌',
  [':tuwei'] = '魏势力技，出牌阶段开始时，你可以获得攻击范围内任意名角色各一张牌；回合结束时，这些角色中本回合未受到过伤害的角色各获得你的一张牌。',
}

tuwei:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(tuwei.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p) return player:inMyAttackRange(p) and not p:isNude() end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return player:inMyAttackRange(p) and not p:isNude()
    end), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#tuwei-choose:::"..#targets,
      skill_name = tuwei.name
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:sortPlayersByAction(event:getCostData(self).tos)
    local mark = player:getTableMark("tuwei-turn")
    for _, id in ipairs(event:getCostData(self).tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        table.insertIfNeed(mark, id)
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "he",
          skill_name = tuwei.name
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, tuwei.name, nil, false, player.id)
      end
    end
    room:setPlayerMark(player, "tuwei-turn", mark)
  end,
})

tuwei:addEffect(fk.TurnEnd, {
  name = "#tuwei_trigger",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("tuwei-turn") ~= 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local mark = player:getMark("tuwei-turn")
    room:sortPlayersByAction(mark)
    for _, id in ipairs(mark) do
      if player.dead or player:isNude() then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        local events = player.room.logic:getActualDamageEvents(1, function(e)
          local damage = e.data[1]
          return p == damage.to
        end, Player.HistoryTurn)
        if #events == 0 then
          room:doIndicate(id, {player.id})
          local card = room:askToChooseCard(p, {
            target = player,
            flag = "he",
            skill_name = tuwei.name
          })
          room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonPrey, tuwei.name, nil, false, id)
        end
      end
    end
  end,
})

return tuwei
