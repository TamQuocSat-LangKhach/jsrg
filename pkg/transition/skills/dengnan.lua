local dengnan = fk.CreateSkill {
  name = "dengnan"
}

Fk:loadTranslationTable{
  ['dengnan'] = '登难',
  ['#dengnan-invoke'] = '登难：视为使用一种非伤害普通锦囊牌！若目标本回合均受到伤害则回合结束时重置！',
  ['#dengnan_trigger'] = '登难',
  ['@@dengnan-turn'] = '登难',
  [':dengnan'] = '限定技，出牌阶段，你可以视为使用一张非伤害类普通锦囊牌，此回合结束时，若此牌的目标均于此回合受到过伤害，你重置〖登难〗。',
}

dengnan:addEffect('viewas', {
  anim_type = "control",
  frequency = Skill.Limited,
  prompt = "#dengnan-invoke",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_damage_card and not card.is_derived and
        player:canUse(card) and not player:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(skill.interaction.data)
    card.skillName = dengnan.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(dengnan.name, Player.HistoryGame) == 0
  end,
})

dengnan:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes("dengnan", Player.HistoryTurn) > 0 and player:hasSkill(dengnan.name, true) then
      local mark = player:getMark("dengnan-turn")
      if mark == 0 then mark = {} end
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
        local damage = e.data[5]
        if damage then
          table.removeOne(mark, damage.to.id)
        end
      end, Player.HistoryTurn)
      return #mark == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(dengnan.name)
    player.room:notifySkillInvoked(player, dengnan.name, "special")
    player:setSkillUseHistory(dengnan.name, 0, Player.HistoryGame)
  end,
})

dengnan:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, dengnan.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "dengnan-turn", TargetGroup:getRealTargets(data.tos))
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(id)
      room:setPlayerMark(p, "@@dengnan-turn", 1)
    end
  end,
})

return dengnan
