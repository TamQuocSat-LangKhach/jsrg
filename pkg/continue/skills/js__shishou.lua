local js__shishou = fk.CreateSkill {
  name = "js__shishou"
}

Fk:loadTranslationTable{
  ['js__shishou'] = '失守',
  ['@js__shishou-turn'] = '失守',
  ['@js__cangchu'] = '仓储失效',
  [':js__shishou'] = '锁定技，当你使用【酒】时，你摸三张牌，然后你不能使用牌直到回合结束。当你受到火焰伤害后，〖仓储〗失效直到你下回合结束。',
}

js__shishou:addEffect(fk.CardUsing, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "analeptic"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, js__shishou.name)
    room:setPlayerMark(player, "@js__shishou-turn", 1)
  end,
})

js__shishou:addEffect(fk.Damaged, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@js__cangchu", 1)
  end,
})

js__shishou:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@js__cangchu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@js__cangchu", 0)
  end,
})

local js__shishou_prohibit = fk.CreateSkill {
  name = "#js__shishou_prohibit"
}

js__shishou_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return player:getMark("@js__shishou-turn") > 0
  end,
})

return js__shishou, js__shishou_prohibit
