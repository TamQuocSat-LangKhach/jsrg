local js__zhaohan = fk.CreateSkill {
  name = "js__zhaohan"
}

Fk:loadTranslationTable{
  ['js__zhaohan'] = '昭汉',
  [':js__zhaohan'] = '锁定技，准备阶段，若牌堆未洗过牌，你回复1点体力，否则你失去1点体力。',
}

js__zhaohan:addEffect(fk.EventPhaseStart, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start and
      ((player:getMark(js__zhaohan.name) == 0 and player:isWounded()) or player:getMark(js__zhaohan.name) > 0)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player:getMark(js__zhaohan.name) == 0 then
      player:broadcastSkillInvoke("zhaohan", 1)
      room:notifySkillInvoked(player, js__zhaohan.name, "support")
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = js__zhaohan.name,
      })
    else
      player:broadcastSkillInvoke("zhaohan", 2)
      room:notifySkillInvoked(player, js__zhaohan.name, "negative")
      room:loseHp(player, 1, js__zhaohan.name)
    end
  end,

  can_refresh = function(self, event, target, player)
    return player:hasSkill(skill.name, true)
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, js__zhaohan.name, 1)
  end,
})

return js__zhaohan
