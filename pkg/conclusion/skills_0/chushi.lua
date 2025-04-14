local chushi = fk.CreateSkill {
  name = "chushi"
}

Fk:loadTranslationTable{
  ['chushi'] = '出师',
  ['#chushi'] = '出师：你可以和主公议事，红色你与其摸牌，黑色你本轮属性伤害增加',
  ['@chushiBuff-round'] = '出师+',
  ['#chushi_buff'] = '出师',
  [':chushi'] = '出牌阶段限一次，你可以和主公议事，若结果为：红色，你与其各摸一张牌，然后重复此摸牌流程，直到你与其手牌之和不小于7\\\n  （若此主公为你，则改为你重复摸一张牌直到你的手牌数不小于7）；黑色，当你于本轮内造成属性伤害时，此伤害+1。',
}

chushi:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  prompt = "#chushi",
  target_num = function(self)
    return #table.filter(Fk:currentRoom().alive_players, function(p) return p.role == "lord" end) > 1 and 1 or 0 
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(chushi.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p.role == "lord" end) and
      (
      not player:isKongcheng() or
      table.find(Fk:currentRoom().alive_players, function(p) return p.role == "lord" and not p:isKongcheng() end)
    )
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #table.filter(Fk:currentRoom().alive_players, function(p) return p.role == "lord" end) < 2 then
      return false
    end

    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target.role == "lord" and not (player:isKongcheng() and target:isKongcheng())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targetId = #effect.tos > 0 and effect.tos[1] or table.find(room.alive_players, function(p) return p.role == "lord" end).id
    local target = room:getPlayerById(targetId)

    room:delay(1000)
    local targets = { player }
    if target ~= player then
      table.insert(targets, target)
    end

    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local discussion = U.Discussion(player, table.filter(targets, function(p) return not p:isKongcheng() end), chushi.name)
    if discussion.color == "red" then
      local drawTargets = { player.id }
      if player ~= target then
        table.insert(drawTargets, target.id)
        room:sortPlayersByAction(drawTargets)
      end

      drawTargets = table.map(drawTargets, Util.Id2PlayerMapper)

      for _, p in ipairs(drawTargets) do
        p:drawCards(1, chushi.name)
      end

      local loopLock = 1
      repeat
        for _, p in ipairs(drawTargets) do
          p:drawCards(1, chushi.name)
        end

        loopLock = loopLock + 1
      until player:getHandcardNum() + (player ~= target and target:getHandcardNum() or 0) >= 7 or loopLock == 20
    elseif discussion.color == "black" then
      room:addPlayerMark(player, "@chushiBuff-round")
    end
  end,
})

chushi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@chushiBuff-round") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(chushi)
    if not cost_data then
      cost_data = {}
      event:setCostData(chushi, cost_data)
    end

    data.damage = data.damage + player:getMark("@chushiBuff-round")
  end,
})

return chushi
