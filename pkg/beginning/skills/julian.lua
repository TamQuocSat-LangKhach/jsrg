local julian = fk.CreateSkill {
  name = "julian$"
}

Fk:loadTranslationTable{
  ['#julian-draw'] = '聚敛：你可以摸一张牌',
  ['#julian-invoke'] = '聚敛：你可以获得所有其他群势力角色各一张手牌',
}

julian:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(julian.name) then
      for _, move in ipairs(data) do
        if move.to and move.to ~= player.id then
          local to = player.room:getPlayerById(move.to)
          if to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and move.skillName ~= julian.name and to.phase ~= Player.Draw and
            to:getMark("julian-turn") < 2 and not to.dead then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to and move.to ~= player.id then
        local to = player.room:getPlayerById(move.to)
        if to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and move.skillName ~= julian.name and to.phase ~= Player.Draw and
          to:getMark("julian-turn") < 2 and not to.dead then
          self:doCost(event, target, player, {to = to})
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(data.to, {
      skill_name = julian.name,
      prompt = "#julian-draw"
    }) then
      event:setCostData(self, nil)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(data.to, "julian-turn", 1)
    data.to:drawCards(1, julian.name)
  end,
})

julian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(julian.name) then
      return table.find(player.room.alive_players, function(p)
        return p ~= player and p.kingdom == "qun" and not p:isKongcheng() end)
    end
  end,
  on_trigger = function(self, event, target, player, data)
    self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = julian.name,
      prompt = "#julian-invoke"
    }) then
      event:setCostData(self, { tos = table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= player and p.kingdom == "qun"
      end), Util.IdMapper) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(event:getCostData(self).tos, Util.Id2PlayerMapper)
    for _, p in ipairs(tos) do
      if not p:isKongcheng() then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = julian.name
        })
        room:obtainCard(player, id, false, fk.ReasonPrey, player.id, julian.name)
        if player.dead then break end
      end
    end
  end,
})

return julian
