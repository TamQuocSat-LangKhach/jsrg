local qiantun = fk.CreateSkill {
  name = "qiantun"
}

Fk:loadTranslationTable{
  ['qiantun'] = '谦吞',
  ['#qiantun'] = '谦吞：令一名角色展示任意张手牌并与其拼点，若赢，你获得展示牌；若没赢，你获得其未展示的手牌',
  ['#qiantun-ask'] = '谦吞：请展示任意张手牌，你将只能用这些牌与 %src 拼点，根据拼点结果其获得你的展示牌或未展示牌！',
  ['#qiantun-pindian'] = '谦吞：你只能用这些牌与 %src 拼点！若其赢，其获得你的展示牌；若其没赢，其获得你未展示的手牌',
  [':qiantun'] = '出牌阶段限一次，你可以令一名其他角色展示至少一张手牌，并与其拼点，其本次拼点牌只能从展示牌中选择。若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。然后你展示手牌。',
}

qiantun:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#qiantun",
  can_use = function(self, player)
    return player:usedSkillTimes(qiantun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 999,
      skill_name = qiantun.name,
      prompt = "#qiantun-ask:" .. player.id
    })
    target:showCards(cards)
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if player.dead or target.dead or #cards == 0 or not player:canPindian(target) then return end
    local pindian = {
      from = player,
      tos = {target},
      reason = qiantun.name,
      fromCard = nil,
      results = {},
      extra_data = {
        qiantun = {
          to = target.id,
          cards = cards,
        },
      },
    }
    room:pindian(pindian)
    if player.dead or target.dead then return end
    if pindian.results[target.id].winner == player then
      cards = table.filter(target:getCardIds("h"), function (id)
        return table.contains(cards, id)
      end)
    else
      cards = table.filter(target:getCardIds("h"), function (id)
        return not table.contains(cards, id)
      end)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, qiantun.name, nil, false, player.id)
    end
    if not player.dead and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
  end,
})

qiantun:addEffect(fk.StartPindian, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player == data.from and data.reason == qiantun.name and data.extra_data and data.extra_data.qiantun then
      for _, to in ipairs(data.tos) do
        if not (data.results[to.id] and data.results[to.id].toCard) and
          data.extra_data.qiantun.to == to.id and
          table.find(data.extra_data.qiantun.cards, function (id)
            return table.contains(to:getCardIds("h"), id)
          end) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      if not (to.dead or to:isKongcheng() or (data.results[to.id] and data.results[to.id].toCard)) and
        data.extra_data.qiantun.to == to.id then
        local cards = table.filter(data.extra_data.qiantun.cards, function (id)
          return table.contains(to:getCardIds("h"), id)
        end)
        if #cards > 0 then
          local card = room:askToCards(to, {
            min_num = 1,
            max_num = 1,
            skill_name = qiantun.name,
            prompt = "#qiantun-pindian:" .. data.from.id,
            expand_pile = cards
          })
          data.results[to.id] = data.results[to.id] or {}
          data.results[to.id].toCard = Fk:getCardById(card[1])
        end
      end
    end
  end,
})

return qiantun
