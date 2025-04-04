local xundao = fk.CreateSkill {
  name = "xundao"
}

Fk:loadTranslationTable{
  ['xundao'] = '寻道',
  ['#xundao-choose'] = '寻道：你可以令至多两名角色各弃置一张牌，你选择其中一张修改你的判定',
  ['#xundao-discard'] = '寻道：你需弃置一张牌，%src 可以用之修改判定',
  ['#xundao-retrial'] = '寻道：选择用来修改判定的牌',
  [':xundao'] = '当你的判定牌生效前，你可以令至多两名角色各弃置一张牌，你选择其中一张代替判定牌。',
}

xundao:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(xundao.name) and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return not p:isNude() end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 2,
      prompt = "#xundao-choose",
      skill_name = xundao.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:sortPlayersByAction(event:getCostData(self).tos)
    local ids = {}
    for _, id in ipairs(event:getCostData(self).tos) do
      local p = room:getPlayerById(id)
      if not p.dead and not p:isNude() then
        local card = room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = xundao.name,
          cancelable = false,
          prompt = "#xundao-discard:"..player.id
        })
        table.insertIfNeed(ids, card[1])
      end
    end
    if player.dead then return end
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if #ids == 0 then return end
    local cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = ids,
      min_target_num = 1,
      max_target_num = 1,
      skill_name = xundao.name,
      prompt = "#xundao-retrial"
    })
    room:retrial(Fk:getCardById(cards[2][1]), player, event.data, xundao.name)
  end,
})

return xundao
