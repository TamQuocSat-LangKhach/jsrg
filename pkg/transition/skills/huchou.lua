local huchou = fk.CreateSkill {
  name = "huchou"
}

Fk:loadTranslationTable{
  ['huchou'] = '互雠',
  ['@huchou'] = '互雠',
  [':huchou'] = '锁定技，上一名对你使用伤害类牌的其他角色受到你造成的伤害时，此伤害+1。',
}

huchou:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return data.from and data.from == player and player:getMark(huchou.name) == target.id
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

huchou:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(huchou.name, true) and
      data.card.is_damage_card and data.from ~= player.id and player:getMark(huchou.name) ~= data.from
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, huchou.name, data.from)
    room:setPlayerMark(player, "@huchou", room:getPlayerById(data.from).general)
  end,
})

huchou:addEffect(fk.AcquireSkill, {
  on_acquire = function (self, player, is_start)
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.tos and table.contains(TargetGroup:getRealTargets(use.tos), player.id) and
        use.card.is_damage_card and use.from ~= player.id then
        room:setPlayerMark(player, huchou.name, use.from)
        room:setPlayerMark(player, "@huchou", room:getPlayerById(use.from).general)
        return true
      end
    end, Player.HistoryGame)
  end,
})

return huchou
