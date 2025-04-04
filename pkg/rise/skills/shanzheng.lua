local shanzheng = fk.CreateSkill {
  name = "shanzheng"
}

Fk:loadTranslationTable{
  ['shanzheng'] = '擅政',
  ['#shanzheng'] = '擅政：与任意名角色议事，红色：你可以对一名未参与议事的角色造成1点伤害；黑色：你获得所有意见牌',
  ['#shanzheng-damage'] = '擅政：你可以对一名未参与议事的角色造成1点伤害',
  [':shanzheng'] = '出牌阶段限一次，你可以与任意名角色议事，若结果为：红色，你可以对一名未参与议事的角色造成1点伤害；黑色，你获得所有意见牌。',
}

shanzheng:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#shanzheng",
  can_use = function(self, player)
    return player:usedSkillTimes(shanzheng.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(shanzheng, room, effect)
    local player = room:getPlayerById(effect.from)
    table.insert(effect.tos, player.id)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local discussion = U.Discussion(player, targets, shanzheng.name)
    if player.dead then return end
    if discussion.color == "red" then
      targets = table.filter(room.alive_players, function (p)
        return not table.contains(targets, p)
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#shanzheng-damage",
        skill_name = shanzheng.name,
        cancelable = true
      })
      if #to > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(to[1]),
          damage = 1,
          skillName = shanzheng.name,
        }
      end
    elseif discussion.color == "black" then
      local cards = {}
      for _, p in ipairs(targets) do
        if not p.dead and p ~= player then
          local ids = table.filter(discussion.results[p.id].toCards, function (id)
            return table.contains(p:getCardIds("h"), id)
          end)
          if #ids > 0 then
            table.insertTableIfNeed(cards, ids)
          end
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, shanzheng.name, nil, true, player.id)
      end
    end
  end,
})

return shanzheng
