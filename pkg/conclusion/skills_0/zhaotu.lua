local zhaotu = fk.CreateSkill {
  name = "zhaotu"
}

Fk:loadTranslationTable{
  ['zhaotu'] = '招图',
  ['#zhaotu'] = '招图：你可以将一张红色非锦囊牌当做【乐不思蜀】使用',
  ['@@zhaotu-turn'] = '招图',
  ['@@zhaotu'] = '招图',
  [':zhaotu'] = '每轮限一次，你可以将一张红色非锦囊牌当做【乐不思蜀】使用，此回合结束后，目标执行一个手牌上限-2的回合。',
  ['$zhaotu1'] = '卿持此诏，惟盈惟谨，勿蹈山阳公覆辙。',
  ['$zhaotu2'] = '司马师觑百官如草芥，社稷早晚必归此人。',
}

zhaotu:addEffect('viewas', {
  anim_type = "control",
  pattern = "indulgence",
  prompt = "#zhaotu",
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    return card.color == Card.Red and card.type ~= Card.TypeTrick
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("indulgence")
    c.skillName = zhaotu.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(zhaotu.name, Player.HistoryRound) == 0
  end,
})

zhaotu:addEffect('maxcards', {
  name = "#zhaotu_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@zhaotu-turn") ~= 0 then
      return -2
    else
      return 0
    end
  end,
})

zhaotu:addEffect(fk.TargetSpecified, {
  name = "#zhaotu_trigger",
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaotu) and data.card.trueName == "indulgence" and #AimGroup:getAllTargets(data.tos) == 1 and table.contains(data.card.skillNames, zhaotu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
    room:setPlayerMark(to, "@@zhaotu", 1)
    to:gainAnExtraTurn(true, "zhaotu")
  end,
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@zhaotu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@zhaotu", 0)
    room:setPlayerMark(target, "@@zhaotu-turn", 1)
  end,
})

return zhaotu
