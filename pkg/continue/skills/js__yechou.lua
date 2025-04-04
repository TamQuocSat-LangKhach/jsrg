local js__yechou = fk.CreateSkill {
  name = "js__yechou"
}

Fk:loadTranslationTable{
  ['js__yechou'] = '业仇',
  ['#js__yechou-choose'] = '业仇：你可以令一名角色本局游戏受到致命伤害时加倍！',
  ['@@js__yechou'] = '业仇',
  [':js__yechou'] = '当你死亡时，你可以选择一名其他角色，本局游戏当其受到致命伤害时，此伤害翻倍。',
}

js__yechou:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(js__yechou.name, false, true)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#js__yechou-choose",
      skill_name = js__yechou.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill).tos[1])
    room:addPlayerMark(to, "@@js__yechou", 1)
  end,
})

js__yechou:addEffect(fk.DamageInflicted, {
  name = "#js__yechou_trigger",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@@js__yechou") > 0 and data.damage >= player.hp
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(js__yechou.name)
    room:notifySkillInvoked(player, js__yechou.name, "negative")
    data.damage = data.damage * (2 ^ player:getMark("@@js__yechou"))
  end,
})

return js__yechou
