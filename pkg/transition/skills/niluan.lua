local niluan = fk.CreateSkill {
  name = "js__niluan",
}

Fk:loadTranslationTable{
  ["js__niluan"] = "逆乱",
  [":js__niluan"] = "准备阶段，你可以选择一项：1.弃置一张牌，对一名未对你造成过伤害的角色造成1点伤害；2.令一名对你造成过伤害的角色摸两张牌。",

  ["#js__niluan-invoke"] = "逆乱：弃一张牌，对一名未对你造成过伤害的角色造成1点伤害；或令一名对你造成过伤害的角色摸两张牌",
}

niluan:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niluan.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "js__niluan_active",
      prompt = "#js__niluan-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    local to = dat.tos[1]
    player:broadcastSkillInvoke(niluan.name)
    if dat.choice == "js__niluan_damage" then
      room:notifySkillInvoked(player, niluan.name, "offensive")
      room:throwCard(dat.cards, niluan.name, player, player)
      if to.dead then return end
      room:damage({
        from = player,
        to = to,
        damage = 1,
        skillName = niluan.name,
      })
    else
      room:notifySkillInvoked(player, niluan.name, "support")
      to:drawCards(2, niluan.name)
    end
  end,

})

niluan:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(niluan.name, true) and data.from
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, niluan.name, data.from.id)
  end,
})

niluan:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local mark = {}
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.to == player and damage.from then
        table.insertIfNeed(mark, damage.from.id)
      end
    end, Player.HistoryGame)
    if #mark > 0 then
      room:setPlayerMark(player, niluan.name, mark)
    end
  end
end)

return niluan
