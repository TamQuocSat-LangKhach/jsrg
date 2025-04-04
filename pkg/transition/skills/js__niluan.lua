local js__niluan = fk.CreateSkill {
  name = "js__niluan"
}

Fk:loadTranslationTable{
  ['js__niluan'] = '逆乱',
  ['js__niluan_active'] = '逆乱',
  ['#js__niluan-invoke'] = '逆乱：弃一张牌，对一名未对你造成过伤害的角色造成1点伤害；或令一名对你造成过伤害的角色摸两张牌',
  [':js__niluan'] = '准备阶段，你可以选择一项：1.弃置一张牌，对一名未对你造成过伤害的角色造成1点伤害；2.令一名对你造成过伤害的角色摸两张牌。',
}

js__niluan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(js__niluan) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "js__niluan_active",
      prompt = "#js__niluan-invoke",
      cancelable = true
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    player:broadcastSkillInvoke(js__niluan.name)
    if #event:getCostData(self).cards > 0 then
      room:notifySkillInvoked(player, js__niluan.name, "offensive")
      room:throwCard(event:getCostData(self).cards, js__niluan.name, player, player)
      if to.dead then return end
      room:damage({
        from = player,
        to = to,
        damage = 1,
        skillName = js__niluan.name
      })
    else
      room:notifySkillInvoked(player, js__niluan.name, "support")
      to:drawCards(2, js__niluan.name)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(js__niluan, true) and data.from and
      not table.contains(player:getTableMark(js__niluan.name), data.from.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, js__niluan.name, data.from.id)
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    local mark = {}
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      if damage.to == player and damage.from then
        table.insertIfNeed(mark, damage.from.id)
      end
    end, Player.HistoryGame)
    room:setPlayerMark(player, js__niluan.name, mark)
  end,
})

return js__niluan
