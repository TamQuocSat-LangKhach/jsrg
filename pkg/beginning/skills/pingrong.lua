local pingrong = fk.CreateSkill {
  name = "pingrong"
}

Fk:loadTranslationTable{
  ['pingrong'] = '平戎',
  ['@@caocao_lie'] = '猎',
  ['#pingrong-choose'] = '平戎：你可以移去一名角色的“猎”标记，然后你执行一个额外回合',
  ['@@pingrong_extra'] = '平戎',
  ['#pingrong_delay'] = '平戎',
  [':pingrong'] = '每轮限一次，一名角色的结束阶段，你可以选择一名有“猎”的角色移去其“猎”，然后获得一个额外的回合，此回合的结束阶段，若你于此回合内未造成过伤害，你失去1点体力。',
  ['$pingrong1'] = '万里平戎，岂曰功名，孤心昭昭鉴日月。',
  ['$pingrong2'] = '四极倾颓，民心思定，试以只手补天裂。',
}

pingrong:addEffect(fk.EventPhaseStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and target.phase == Player.Finish and
      player:usedSkillTimes(skill.name, Player.HistoryRound) == 0 and table.find(player.room.alive_players, function (p)
        return p:getMark("@@caocao_lie") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@caocao_lie") > 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#pingrong-choose",
      skill_name = skill.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill).tos[1])
    room:setPlayerMark(to, "@@caocao_lie", 0)
    room:addPlayerMark(player, "@@pingrong_extra", 1)
    if player == target then
      room:setPlayerMark(player, "pingrong_self-turn", 1)
    end
    player:gainAnExtraTurn()
  end,
  can_refresh = function(self, event, target, player, data)
    --FIXME:巨大隐患
    if player ~= target or player:getMark("@@pingrong_extra") == 0 then return false end
    if event == fk.TurnedOver then
      local e = player.room.logic:getCurrentEvent()
      return e.parent == nil or e:findParent(GameEvent.Turn, true) == nil
    elseif event == fk.AfterTurnEnd then
      return player:getMark("pingrong_self-turn") == 0
    elseif event == fk.Damage then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@pingrong_extra", 0)
  end,
})

local pingrong_delay = fk.CreateSkill{
  name = "#pingrong_delay"
}

pingrong_delay:addEffect(fk.EventPhaseStart, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and
      player:getMark("@@pingrong_extra") ~= 0 and player:getMark("pingrong_self-turn") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, skill.name)
  end,
})

return pingrong
