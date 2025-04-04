local yanggeActive = fk.CreateSkill {
  name = "yangge&"
}

Fk:loadTranslationTable{
  ['yangge&'] = '扬戈',
  ['#yangge'] = '扬戈：你可选择一名拥有〖扬戈〗角色，对其发动〖密诏〗',
  [':yangge&'] = '出牌阶段，若你体力值为最低，你可以对一名有〖扬戈〗的角色发动〖密诏〗（其每轮限一次）。',
}

yanggeActive:addEffect('active', {
  anim_type = "support",
  prompt = "#yangge",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return
      not player:isKongcheng() and
      not table.find(Fk:currentRoom().alive_players, function(p)
        return p.hp < player.hp
      end) and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p:hasSkill(yanggeActive.name) and p:usedSkillTimes(yanggeActive.name, Player.HistoryRound) == 0
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local to = Fk:currentRoom():getPlayerById(to_select)
    return
      #selected == 0 and
      to_select ~= player.id and
      to:hasSkill(yanggeActive.name) and
      to:usedSkillTimes(yanggeActive.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    target:addSkillUseHistory(yanggeActive.name, 1)
    room:obtainCard(target.id, player:getCardIds("h"), false, fk.ReasonGive, player.id, yanggeActive.name)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return target:canPindian(p) and p ~= target
    end)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      skill_name = yanggeActive.name,
      cancelable = false,
    })
    local to = room:getPlayerById(tos[1])
    local pindian = target:pindian({to}, yanggeActive.name)
    if pindian.results[to.id].winner then
      local winner, loser
      if pindian.results[to.id].winner == target then
        winner = target
        loser = to
      else
        winner = to
        loser = target
      end
      if loser.dead then return end
      room:useVirtualCard("slash", nil, winner, { loser }, yanggeActive.name, true)
    end
  end,
})

return yanggeActive
