local js__limu = fk.CreateSkill {
  name = "js__limu"
}

Fk:loadTranslationTable{
  ['js__limu'] = '立牧',
  ['#js__limu'] = '立牧：你可以将一张<font color=>♦</font>牌当【乐不思蜀】对你使用，然后你回复1点体力',
  [':js__limu'] = '出牌阶段，你可以将一张<font color=>♦</font>牌当【乐不思蜀】对你使用，然后你回复1点体力；若你的判定区里有牌，则你对攻击范围内的其他角色使用牌无次数和距离限制。',
  ['$js__limu1'] = '米贼作乱，吾必为益州自保。',
  ['$js__limu2'] = '废史立牧，可得一方安定。',
}

-- Active Skill Effect
js__limu:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  prompt = "#js__limu",
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.suit == Card.Diamond and
      not player:isProhibited(player, Fk:cloneCard("indulgence", card.suit, card.number))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:useVirtualCard("indulgence", effect.cards, player, player, js__limu.name, true)
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        skillName = js__limu.name,
      }
    end
  end,
})

-- TargetModSkill Effect
js__limu:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(js__limu) and scope == Player.HistoryPhase and
      card and #player:getCardIds("j") > 0 and player:inMyAttackRange(to)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(js__limu) and #player:getCardIds("j") > 0 and player:inMyAttackRange(to)
  end,
})

return js__limu
