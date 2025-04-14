local jinfa = fk.CreateSkill {
  name = "js__jinfa"
}

Fk:loadTranslationTable{
  ['js__jinfa'] = '矜伐',
  ['#js__jinfa'] = '矜伐：你可展示一张手牌并议事，结果和展示牌相同则摸牌，不同则获得【影】',
  ['#js__jinfa_trigger'] = '矜伐',
  ['#js__jinfa-ask'] = '矜伐：你可令其中至多两名角色将手牌摸至体力上限',
  ['#js__jinfa-change'] = '矜伐：你可以变更势力',
  [':js__jinfa'] = '出牌阶段限一次，你可以展示一张手牌，然后与体力上限不大于你的所有角色议事，当此议事结果确定后，若结果与你展示牌的颜色：相同，你令至多两名参与议事的角色将手牌摸至体力上限；不同，你获得两张【影】。最后若没有其他角色与你意见相同，则你可变更势力。',
}

jinfa:addEffect('active', {
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#js__jinfa",
  can_use = function(self, player)
    return player:usedSkillTimes(jinfa.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() and p.maxHp <= player.maxHp end)

    player:showCards(effect.cards)
    room:delay(1500)

    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    U.Discussion(player, targets, jinfa.name, { jinfaCard = effect.cards[1] })
  end,
})

jinfa:addEffect('trigger', {
  anim_type = "drawcard",
  events = {"fk.DiscussionResultConfirmed"},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == jinfa.name and data.extra_data.jinfaCard
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.color == Fk:getCardById(data.extra_data.jinfaCard):getColorString() then
      local toDraw = table.filter(data.tos, function(p) return p:isAlive() and p:getHandcardNum() < p.maxHp end)
      if #toDraw > 0 then
        local result = room:askToChoosePlayers(player, {
          targets = toDraw,
          min_num = 1,
          max_num = 2,
          prompt = "#js__jinfa-ask",
          skill_name = jinfa.name,
          cancelable = false,
        })
        room:sortPlayersByAction(result)
        for _, p in ipairs(result) do
          p:drawCards(p.maxHp - p:getHandcardNum(), jinfa.name)
        end
      end
    else
      room:moveCards({
        ids = getShade(room, 2),
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = jinfa.name,
        moveVisible = true,
      })
    end

    local hasSameOpinion = false
    for playerId, result in pairs(data.results) do
      if playerId ~= player.id and result.opinion == data.results[player.id].opinion then
        hasSameOpinion = true
        break
      end
    end

    if not hasSameOpinion then
      local kingdoms = {"wei", "shu", "wu", "qun", "jin", "Cancel"}
      local choices = table.simpleClone(kingdoms)
      table.removeOne(choices, player.kingdom)
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = jinfa.name,
        prompt = "#js__jinfa-change",
        detailed = false,
        all_choices = kingdoms,
        cancelable = false,
      })

      if choice ~= "Cancel" then
        room:changeKingdom(player, choice, true)
      end
    end
  end,
})

return jinfa
