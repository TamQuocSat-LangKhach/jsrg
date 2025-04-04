local jishan = fk.CreateSkill {
  name = "jishan"
}

Fk:loadTranslationTable{
  ['jishan'] = '积善',
  ['#jishan-invoke'] = '积善：你可以失去1点体力防止 %dest 受到的伤害，然后你与其各摸一张牌',
  ['#jishan-choose'] = '积善：你可以令一名角色回复1点体力',
  [':jishan'] = '每回合各限一次，1.当一名角色受到伤害时，你可以失去1点体力防止此伤害，然后你与其各摸一张牌；2.当你造成伤害后，你可以令一名体力值最小且你对其发动过〖积善〗的角色回复1点体力。',
  ['$jishan1'] = '勿以善小而不为。',
  ['$jishan2'] = '积善成德，而神明自得。',
}

jishan:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(jishan.name) and player:getMark("jishan_prevent-turn") == 0
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    if room:askToSkillInvoke(player, {skill_name = jishan.name, prompt = "#jishan-invoke::"..target.id}) then
      return {tos = {target.id}}
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "jishan_prevent-turn", 1)
    room:addTableMarkIfNeed(player, "jishan_record", target.id)
    room:loseHp(player, 1, jishan.name)
    if not player.dead then
      player:drawCards(1, jishan.name)
    end
    if not target.dead then
      target:drawCards(1, jishan.name)
    end
  end,
})

jishan:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("jishan_recover-turn") == 0 and
      table.find(player.room.alive_players, function(to)
        return table.contains(player:getTableMark("jishan_record"), to.id) and to:isWounded() and
          table.every(player.room.alive_players, function(p) return p.hp >= to.hp end)
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(to)
      return table.contains(player:getTableMark("jishan_record"), to.id) and to:isWounded() and
        table.every(room.alive_players, function(p) return p.hp >= to.hp end)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#jishan-choose",
      skill_name = jishan.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, {tos = to})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "jishan_recover-turn", 1)
    local cost_data = event:getCostData(skill)
    room:recover{
      who = room:getPlayerById(cost_data.tos[1]),
      num = 1,
      recoverBy = player,
      skillName = jishan.name
    }
  end,
})

return jishan
