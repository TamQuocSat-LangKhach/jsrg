local wuchang = fk.CreateSkill {
  name = "wuchang"
}

Fk:loadTranslationTable{
  ['wuchang'] = '无常',
  [':wuchang'] = '锁定技，当你得到其他角色的牌后，你变更势力至与其相同；当你使用【杀】或【决斗】对势力与你相同的角色造成伤害时，你令此伤害+1，然后你变更势力至群。',
}

wuchang:addEffect(fk.AfterCardsMove, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wuchang.name) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.from).kingdom ~= player.kingdom then
          if table.find(move.moveInfo, function(info) return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip end) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(wuchang.name)
    for _, move in ipairs(data) do
      if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand
        and table.find(move.moveInfo, function(info) return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip end) then
        local p = room:getPlayerById(move.from)
        if p.kingdom ~= player.kingdom then
          room:notifySkillInvoked(player, wuchang.name, "special")
          room:changeKingdom(player, p.kingdom, true)
        end
      end
    end
  end,
})

wuchang:addEffect(fk.DamageCaused, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wuchang.name) then
      return target == player and data.card and table.contains({"slash", "duel"}, data.card.trueName) and player.kingdom == data.to.kingdom
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(wuchang.name)
    room:notifySkillInvoked(player, wuchang.name, "offensive")
    data.damage = data.damage + 1
    room:changeKingdom(player, "qun", true)
  end,
})

return wuchang
