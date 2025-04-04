local fenjian = fk.CreateSkill {
  name = "fenjian"
}

Fk:loadTranslationTable{
  ['fenjian'] = '奋剑',
  ['#fenjian-invoke'] = '奋剑：你可以令你本回合受到的伤害+1，视为使用一张【决斗】或【桃】',
  ['@fenjian-turn'] = '奋剑',
  [':fenjian'] = '每回合各限一次，当你需要对其他角色使用【决斗】或【桃】时，你可以令你受到的伤害+1直到本回合结束，然后你视为使用之。',
}

fenjian:addEffect('viewas', {
  anim_type = "special",
  pattern = "duel,peach",
  prompt = "#fenjian-invoke",
  interaction = function(self)
    local names = {}
    local pattern = Fk.currentResponsePattern
    local duel = Fk:cloneCard("duel")
    if pattern == nil and duel.skill:canUse(self.player, duel) and self.player:getMark("fenjian_duel-turn") == 0 then
      table.insert(names, "duel")
    else
      if Exppattern:Parse(pattern):matchExp("peach") and self.player:getMark("fenjian_peach-turn") == 0 then
        table.insert(names, "peach")
      end
    end
    if #names == 0 then return end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = fenjian.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addPlayerMark(player, "@fenjian-turn", 1)
    room:setPlayerMark(player, "fenjian_"..use.card.trueName.."-turn", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("fenjian_duel-turn") == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("fenjian_peach-turn") == 0 and not player.dying  --FIXME！
  end,
})

fenjian:addEffect('prohibit', {
  name = "#fenjian_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:hasSkill(fenjian.name, true) then
      return table.contains(card.skillNames, fenjian.name) and from == to
    end
  end,
})

fenjian:addEffect(fk.DamageInflicted, {
  name = "#fenjian_trigger",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@fenjian-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(fenjian.name)
    player.room:notifySkillInvoked(player, fenjian.name, "negative")
    data.damage = data.damage + player:getMark("@fenjian-turn")
  end,
})

return fenjian
