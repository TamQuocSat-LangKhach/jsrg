local funi = fk.CreateSkill {
  name = "funi"
}

Fk:loadTranslationTable{
  ['funi'] = '伏匿',
  ['@@funi-turn'] = '伏匿',
  ['#funi-give'] = '伏匿：令任意名角色获得【影】',
  [':funi'] = '锁定技，你的攻击范围始终为0；每轮开始时，你令任意名角色获得共计X张【影】（X为存活角色数的一半，向上取整）；当一张【影】进入弃牌堆时，你本回合使用牌无距离限制且不能被响应。',
}

funi:addEffect(fk.RoundStart, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(funi.name)
    room:notifySkillInvoked(player, funi.name, "control")
    local n = (#room.alive_players + 1) // 2
    local ids = getShade(room, n)
    room:askToYiji(player, {
      cards = ids,
      targets = room.alive_players,
      skill_name = funi.name,
      min_num = #ids,
      max_num = #ids,
      prompt = "#funi-give",
      expand_pile = ids
    })
  end,
})

funi:addEffect(fk.AfterCardsMove, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and player:getMark("@@funi-turn") == 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.Void then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId, true).trueName == "shade" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@funi-turn", 1)
  end,
})

funi:addEffect(fk.CardUsing, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@funi-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(funi.name)
    room:notifySkillInvoked(player, funi.name, "offensive")
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
})

funi:addEffect('atkrange', {
  correct_func = function (skill, from, to)
    if from:hasSkill(funi.name) then
      return -1000
    end
    return 0
  end,
})

funi:addEffect('targetmod', {
  bypass_distances = function(self, player, skillName, card, to)
    return player:getMark("@@funi-turn") > 0
  end,
})

return funi
