local zhendan = fk.CreateSkill {
  name = "zhendan"
}

Fk:loadTranslationTable{
  ['zhendan'] = '镇胆',
  ['#zhendan_vies'] = '镇胆:你可以将一张非基本牌当做一张基本牌使用或打出',
  ['#zhendan_trigger'] = '镇胆',
  [':zhendan'] = '你可以将一张非基本手牌当做任意基本牌使用或打出；当你受到伤害后或每轮结束时，你摸X张牌，然后此技能本轮失效（X为本轮所有角色执行过的回合数且至多为5）。',
}

-- ViewAsSkill
zhendan:addEffect('viewas', {
  pattern = ".|.|.|.|.|basic",
  prompt = "#zhendan_vies",
  interaction = function(self, player)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(player, "zhendan", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    return card.type ~= Card.TypeBasic and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, player, cards)
    if not skill.interaction.data then return end
    if #cards ~= 1 then
      return nil
    end
    local card = Fk:cloneCard(skill.interaction.data)
    card:addSubcards(cards)
    card.skillName = zhendan.name
    return card
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = Util.TrueFunc,
})

-- TriggerSkill
zhendan:addEffect(fk.Damaged, {
  global = false,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(zhendan.name) and not (event == fk.Damaged and target ~= player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("zhendan")
    room:notifySkillInvoked(player, "zhendan", "masochism")
    local num = #room.logic:getEventsOfScope(GameEvent.Turn, 99, function (e)
      return true
    end, Player.HistoryRound)
    player:drawCards(math.min(num, 5), zhendan.name)
    room:invalidateSkill(player, "zhendan", "-round")
  end,
})

-- RoundEnd event handling
zhendan:addEffect(fk.RoundEnd, {
  global = false,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(zhendan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("zhendan")
    room:notifySkillInvoked(player, "zhendan", "masochism")
    local num = #room.logic:getEventsOfScope(GameEvent.Turn, 99, function (e)
      return true
    end, Player.HistoryRound)
    player:drawCards(math.min(num, 5), zhendan.name)
    room:invalidateSkill(player, "zhendan", "-round")
  end,
})

return zhendan
