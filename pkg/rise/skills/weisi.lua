local weisi = fk.CreateSkill {
  name = "weisi"
}

Fk:loadTranslationTable{
  ['weisi'] = '威肆',
  ['#weisi'] = '威肆：令一名角色将任意张手牌移出游戏直到回合结束，然后视为对其使用【决斗】！',
  ['#weisi-ask'] = '威肆：%src 将对你使用【决斗】！请将任意张手牌本回合移出游戏，【决斗】对你造成伤害后其获得你所有手牌！',
  ['$weisi'] = '威肆',
  ['#weisi_delay'] = '威肆',
  [':weisi'] = '出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，此牌对其造成伤害后，你获得其所有手牌。',
}

weisi:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#weisi",
  can_use = function(self, player)
    return player:usedSkillTimes(weisi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 999,
      skill_name = weisi.name,
      prompt = "#weisi-ask:"..player.id
    })
    if #cards > 0 then
      target:addToPile("$weisi", cards, false, weisi.name, target.id)
    end
    if player.dead or target.dead then return end
    room:useVirtualCard("duel", nil, player, target, weisi.name)
  end,
})

weisi:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.room.logic:damageByCardEffect(true) and
      data.card and table.contains(data.card.skillNames, "weisi") and
      not target:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(target:getCardIds("h"), Card.PlayerHand, player, fk.ReasonPrey, "weisi", nil, false, player.id)
  end,
})

weisi:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$weisi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(player:getPile("$weisi"), Card.PlayerHand, player, fk.ReasonJustMove, "weisi", nil, false, player.id)
  end,
})

return weisi
