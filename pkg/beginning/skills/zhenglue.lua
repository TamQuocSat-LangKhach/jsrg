local zhenglue = fk.CreateSkill {
  name = "zhenglue"
}

Fk:loadTranslationTable{
  ['zhenglue'] = '政略',
  ['@@caocao_lie'] = '猎',
  ['#zhenglue1-trigger'] = '政略：是否摸一张牌并令角色获得“猎”？',
  ['#zhenglue2-trigger'] = '政略：你可以摸一张牌并获得造成伤害的牌',
  ['#zhenglue-choose'] = '政略：选择至多%arg名角色，令其获得“猎”标记',
  [':zhenglue'] = '主公角色的回合结束时，你可以摸一张牌，然后令一名没有“猎”的角色获得“猎”，若主公角色于此回合内未造成过伤害，则改为令至多两名没有“猎”的角色获得“猎”。<br>你对有“猎”的角色使用牌无距离和次数限制。<br>每名角色的回合限一次，当你对有“猎”的角色造成伤害后，你可以摸一张牌并获得造成此伤害的牌。',
  ['$zhenglue1'] = '治政用贤不以德，则四方定。',
  ['$zhenglue2'] = '秉至公而服天下，孤大略成。',
}

-- TriggerSkill effects
zhenglue:addEffect({fk.TurnEnd, fk.Damage}, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(zhenglue.name) then
      if event == fk.TurnEnd then
        return target.role == "lord"
      elseif event == fk.Damage then
        return target and target == player and target:getMark("@@caocao_lie") > 0 and player:getMark("zhenglue-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player)
    if event == fk.TurnEnd then
      return player.room:askToSkillInvoke(player, {skill_name = zhenglue.name, prompt = "#zhenglue1-trigger"})
    elseif event == fk.Damage then
      return player.room:askToSkillInvoke(player, {skill_name = zhenglue.name, prompt = "#zhenglue2-trigger"})
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(1, zhenglue.name)
    if player.dead then return end
    if event == fk.TurnEnd then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return p:getMark("@@caocao_lie") == 0
      end), Util.IdMapper)
      if #targets == 0 then return end
      local x = 1
      if #targets > 1 and #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if target == damage.from then
          return true
        end
      end, Player.HistoryTurn) == 0 then
        x = 2
      end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = x,
        prompt = "#zhenglue-choose:::" .. tostring(x),
        skill_name = zhenglue.name,
        cancelable = false,
      })
      for _, to in ipairs(tos) do
        room:setPlayerMark(to, "@@caocao_lie", 1)
      end
    elseif event == fk.Damage then
      room:setPlayerMark(player, "zhenglue-turn", 1)
      if data.card and room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, zhenglue.name, nil, true, player.id)
      end
    end
  end,
})

-- TargetModSkill effect
zhenglue:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(zhenglue.name) and to and to:getMark("@@caocao_lie") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(zhenglue.name) and to and to:getMark("@@caocao_lie") > 0
  end,
})

return zhenglue
