local js__biaozhao = fk.CreateSkill {
  name = "js__biaozhao"
}

Fk:loadTranslationTable{
  ['js__biaozhao'] = '表召',
  ['#js__biaozhao-choose'] = '表召：你可选择两名角色，第一个对第二个使用牌无距离次数限制，第二个使用牌对你造成伤害+1',
  ['@@js__biaozhao1'] = '表召',
  ['@@js__biaozhao2'] = '表召目标',
  [':js__biaozhao'] = '准备阶段，你可以选择两名其他角色，直到你下回合开始时或你死亡后，你选择的第一名角色对第二名角色使用牌无距离次数限制，第二名角色对你使用牌造成伤害+1。',
}

js__biaozhao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(js__biaozhao.name) and player.phase == Player.Start and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 2,
      max_num = 2,
      prompt = "#js__biaozhao-choose",
      skill_name = js__biaozhao.name,
      cancelable = true
    })
    if #tos == 2 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local target1, target2 = room:getPlayerById(event:getCostData(self).tos[1]), room:getPlayerById(event:getCostData(self).tos[2])
    room:addTableMark(target1, "@@js__biaozhao1", player.id)
    room:addTableMark(target2, "@@js__biaozhao2", player.id)
  end,

  can_refresh = function(self, event, target, player)
    return target == player and table.find(player.room.alive_players, function(p)
      return table.contains(p:getTableMark("@@js__biaozhao1"), player.id) or table.contains(p:getTableMark("@@js__biaozhao2"), player.id)
    end)
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@js__biaozhao1") ~= 0 then
        room:removeTableMark(p, "@@js__biaozhao1", player.id)
      end
      if p:getMark("@@js__biaozhao2") ~= 0 then
        room:removeTableMark(p, "@@js__biaozhao2", player.id)
      end
    end
  end,
})

js__biaozhao:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@js__biaozhao1") ~= 0 and scope == Player.HistoryPhase and to and to:getMark("@@js__biaozhao2") ~= 0 and
      table.find(to:getMark("@@js__biaozhao2"), function(id) return table.contains(player:getMark("@@js__biaozhao1"), id) end)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("@@js__biaozhao1") ~= 0 and to and to:getMark("@@js__biaozhao2") ~= 0 and
      table.find(to:getMark("@@js__biaozhao2"), function(id) return table.contains(player:getMark("@@js__biaozhao1"), id) end)
  end,
})

js__biaozhao:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@js__biaozhao2") ~= 0 and data.card and
      table.contains(player:getMark("@@js__biaozhao2"), data.to.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.to:broadcastSkillInvoke("js__biaozhao")
    room:notifySkillInvoked(data.to, "js__biaozhao", "negative")
    data.damage = data.damage + 1
  end,
})

return js__biaozhao
