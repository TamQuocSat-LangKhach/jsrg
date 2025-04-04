local js__danxinn = fk.CreateSkill {
  name = "js__danxinn"
}

Fk:loadTranslationTable{
  ['js__danxinn'] = '丹心',
  ['#js__danxinn_delay'] = '丹心',
  [':js__danxinn'] = '你可以将一张牌当做【推心置腹】使用，你须展示获得和给出的牌，以此法得到<font color=>♥</font>牌的角色回复1点体力，此牌结算后，本回合内你计算与此牌目标的距离+1。',
}

js__danxinn:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local c = Fk:cloneCard("sincere_treat")
      c.skillName = js__danxinn.name
      c:addSubcard(to_select)
      return player:canUse(c) and not player:prohibitUse(c)
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards, _, _)
    if #selected_cards ~= 1 then return false end
    local c = Fk:cloneCard("sincere_treat")
    c.skillName = js__danxinn.name
    c:addSubcards(selected_cards)
    return c.skill:targetFilter(to_select, selected, selected_cards, c, nil, player) and
      not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), c)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local c = Fk:cloneCard("sincere_treat")
    c.skillName = js__danxinn.name
    c:addSubcards(effect.cards)
    local use = {
      from = player.id,
      tos = table.map(effect.tos, function (id) return {id} end),
      card = c,
      extra_data = {js__danxinn_user = player.id},
    }
    room:useCard(use)
    if player.dead then return end
    for _, pid in ipairs(TargetGroup:getRealTargets(use.tos)) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:addPlayerMark(p, "js__danxinn_"..player.id.."-turn")
      end
    end
  end,
})

js__danxinn:addEffect('distance', {
  correct_func = function(self, from, to)
    return to:getMark("js__danxinn_" .. from.id .. "-turn")
  end,
})

js__danxinn:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if e then
      local use = e.data[1]
      if table.contains(use.card.skillNames, "js__danxinn") then
        local ids = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.PlayerHand and move.to == player.id then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player:getCardIds("h"), info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
        if #ids > 0 then
          event:setCostData(skill, ids)
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = event:getCostData(skill)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if e then
      local use = e.data[1]
      local me = room:getPlayerById(use.extra_data.js__danxinn_user)
      me:showCards(ids)
      if not player.dead and player:isWounded() and table.find(ids, function (id)
        return Fk:getCardById(id).suit == Card.Heart
      end) then
        room:recover { num = 1, skillName = js__danxinn.name, who = player, recoverBy = me}
      end
    end
  end,
})

return js__danxinn
