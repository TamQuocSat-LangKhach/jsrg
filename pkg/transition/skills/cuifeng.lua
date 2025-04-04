local cuifeng = fk.CreateSkill {
  name = "cuifeng"
}

Fk:loadTranslationTable{
  ['cuifeng'] = '摧锋',
  ['#cuifeng-invoke'] = '摧锋：视为使用一种伤害牌！若没造成伤害或造成伤害大于1则回合结束时重置！',
  ['#cuifeng_trigger'] = '摧锋',
  [':cuifeng'] = '限定技，出牌阶段，你可以视为使用一张唯一目标的伤害类牌（无距离限制），若此牌未造成伤害或造成的伤害数大于1，此回合结束时重置〖摧锋〗。',
}

-- ViewAsSkill
cuifeng:addEffect('viewas', {
  anim_type = "offensive",
  frequency = Skill.Limited,
  prompt = "#cuifeng-invoke",
  interaction = function(self)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.is_damage_card and card.skill.target_num == 1 and not card.is_derived and
        self.player:canUse(card) and not self.player:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = cuifeng.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(cuifeng.name, Player.HistoryGame) == 0
  end,
})

-- TargetModSkill
cuifeng:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, cuifeng.name)
  end,
})

-- TriggerSkill
cuifeng:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes(cuifeng.name, Player.HistoryTurn) > 0 and player:hasSkill(cuifeng.name, true) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id and table.contains(use.card.skillNames, cuifeng.name) then
          if use.damageDealt then
            for _, p in ipairs(player.room:getAllPlayers()) do
              if use.damageDealt[p.id] then
                n = n + use.damageDealt[p.id]
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return n ~= 1
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(cuifeng.name)
    player.room:notifySkillInvoked(player, cuifeng.name, "special")
    player:setSkillUseHistory(cuifeng.name, 0, Player.HistoryGame)
  end,
})

return cuifeng
