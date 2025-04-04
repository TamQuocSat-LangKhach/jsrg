local juxia = fk.CreateSkill {
  name = "juxia"
}

Fk:loadTranslationTable{
  ['juxia'] = '居下',
  ['#juxia-invoke'] = '居下：你可以令%arg对 %src 无效并令其摸两张牌',
  [':juxia'] = '每名角色的回合限一次，当其他角色使用牌指定你为目标后，若其技能数大于你，则其可以令此牌对你无效，然后令你摸两张牌。',
}

juxia:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juxia.name) and data.from and data.from ~= player.id and
      #table.filter(player.room:getPlayerById(data.from).player_skills, function(skill)
        return skill:isPlayerSkill(player.room:getPlayerById(data.from))
      end) > #table.filter(player.player_skills, function(skill)
        return skill:isPlayerSkill(player)
      end) and
      player:usedSkillTimes(juxia.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(room:getPlayerById(data.from), {
      skill_name = juxia.name,
      prompt = "#juxia-invoke:" .. player.id .. "::" .. data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    if data.card.sub_type == Card.SubtypeDelayedTrick then  --延时锦囊就取消掉？-_-||
      AimGroup:cancelTarget(data, player.id)
    else
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
    player:drawCards(2, juxia.name)
  end,
})

return juxia
