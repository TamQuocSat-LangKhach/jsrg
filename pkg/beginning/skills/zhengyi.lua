local zhengyi = fk.CreateSkill {
  name = "zhengyi"
}

Fk:loadTranslationTable{
  ['zhengyi'] = '争义',
  ['js__lirang'] = '礼让',
  ['#zhengyi-invoke'] = '争义：你可以将 %src 受到的伤害转移给你',
  [':zhengyi'] = '当你每回合首次受到伤害时，本轮你发动〖礼让〗的目标角色可以将此伤害转移给其。',
}

zhengyi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player:usedSkillTimes("js__lirang", Player.HistoryRound) > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.Damage, 2, function (e)
        return e.data[1].to == player
      end, Player.HistoryTurn) == 1 and
      not player.room:getPlayerById(player:getMark("js__lirang-round")).dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(room:getPlayerById(player:getMark("js__lirang-round")), {
      skill_name = skill.name,
      prompt = "#zhengyi-invoke:"..player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local new_data = table.simpleClone(data)
    new_data.to = room:getPlayerById(player:getMark("js__lirang-round"))
    room:damage(new_data)
    return true
  end,
})

return zhengyi
