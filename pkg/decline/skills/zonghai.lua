local zonghai = fk.CreateSkill {
  name = "zonghai"
}

Fk:loadTranslationTable{
  ['zonghai'] = '纵害',
  ['#zonghai-invoke'] = '纵害：是否对 %dest 发动本技能？',
  ['#zonghai-choose'] = '纵害：请选择至多两名角色，未被选择的角色在本次濒死中不能使用牌，濒死结算后所选角色受到伤害',
  ['@@zonghai'] = '纵害',
  ['#zonghai_damage'] = '纵害',
  ['#zonghai_prohibit'] = '纵害',
  [':zonghai'] = '每轮限一次，当其他角色进入濒死状态时，你可以令其选择至多两名角色，未被选择的角色于此次濒死结算中不能使用牌。此濒死结算结束后，你对其选择的角色各造成1点伤害。',
}

zonghai:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player)
    return
      target ~= player and
      player:hasSkill(zonghai.name) and
      player:usedSkillTimes(zonghai.name, Player.HistoryRound) == 0 and
      target:isAlive() and
      target.hp < 1
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = zonghai.name,
      prompt = "#zonghai-invoke::" .. target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local victim = room:getPlayerById(target.id)
    room:doIndicate(player.id, { victim.id })
    local tos = room:askToChoosePlayers(victim, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 2,
      prompt = "#zonghai-choose",
      skill_name = zonghai.name,
      cancelable = false
    })

    for _, to in ipairs(tos) do
      room:addTableMarkIfNeed(room:getPlayerById(to), "@@zonghai", player.id)
    end

    local curDyingEvent = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
    if curDyingEvent then
      curDyingEvent:addCleaner(function()
        for _, p in ipairs(tos) do
          local to = room:getPlayerById(p)
          local zonghaiSource = to:getTableMark("@@zonghai")
          table.removeOne(zonghaiSource, player.id)
          room:setPlayerMark(to, "@@zonghai", #zonghaiSource > 0 and zonghaiSource or 0)
        end
      end)
    end

    local extra_data = (target.extra_data or {})
    extra_data.zonghaiUsed = extra_data.zonghaiUsed or {}
    extra_data.zonghaiUsed[player.id] = extra_data.zonghaiUsed[player.id] or {}
    table.insertTableIfNeed(extra_data.zonghaiUsed[player.id], tos)
  end,
})

zonghai:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player)
    return
      ((target.extra_data or {}).zonghaiUsed or {})[player.id] and
      player:isAlive() and
      table.find(
        ((target.extra_data or {}).zonghaiUsed or {})[player.id],
        function(p) return room:getPlayerById(p):isAlive() end
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(
      target.extra_data.zonghaiUsed[player.id],
      function(p) return room:getPlayerById(p):isAlive() end
    )

    if #targets == 0 then
      return false
    end

    room:sortPlayersByAction(targets)
    for _, pId in ipairs(targets) do
      local p = room:getPlayerById(pId)
      if p:isAlive() and player:isAlive() then
        room:doIndicate(player.id, { p.id })
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = zonghai.name,
        }
      end
    end
  end,
})

zonghai:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return
      player:getMark("@@zonghai") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p:getMark("@@zonghai") ~= 0 end)
  end,
})

return zonghai
