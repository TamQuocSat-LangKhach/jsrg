local guanhuo = fk.CreateSkill {
  name = "guanhuo"
}

Fk:loadTranslationTable{
  ['guanhuo'] = '观火',
  ['#guanhuo'] = '观火：你可以视为使用一张【火攻】',
  ['@@guanhuo-phase'] = '观火',
  [':guanhuo'] = '出牌阶段，你可以视为使用一张【火攻】。当你以此法使用的未造成伤害的【火攻】结算后，若此次为你于此阶段内第一次发动本技能，则你令你此阶段内你使用【火攻】造成的伤害+1，否则你失去〖观火〗。',
}

guanhuo:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#guanhuo",
  can_use = function(self, player)
    return not player:prohibitUse(Fk:cloneCard("fire_attack"))
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:isKongcheng() and not player:isProhibited(target, Fk:cloneCard("fire_attack"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("fire_attack", nil, player, target, guanhuo.name)
  end,
})

guanhuo:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if target == player then
      return player:getMark("@@guanhuo-phase") > 0 and data.card.name == "fire_attack"
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

guanhuo:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    if target == player then
      return data.card and table.contains(data.card.skillNames, guanhuo.name)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.card.extra_data = data.card.extra_data or {}
    table.insert(data.card.extra_data, guanhuo.name)
  end,
})

guanhuo:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    if target == player then
      return data.card and not (data.card.extra_data and table.contains(data.card.extra_data, guanhuo.name))
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:usedSkillTimes(guanhuo.name, Player.HistoryPhase) == 1 then
      room:addPlayerMark(player, "@@guanhuo-phase", 1)
    else
      room:handleAddLoseSkills(player, "-" .. guanhuo.name, nil, true, false)
    end
  end,
})

return guanhuo
