local premeditate_rule = fk.CreateSkill {
  name = "#premeditate_rule"
}

Fk:loadTranslationTable{
  ['#premediterate-use'] = '你可以使用此蓄谋牌%arg，或点“取消”将所有蓄谋牌置入弃牌堆',
}

premeditate_rule:addEffect(fk.EventPhaseStart, {
  global = true,
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Judge)
    for i = #cards, 1, -1 do
      if table.contains(player:getCardIds(Player.Judge), cards[i]) then
        if player.dead then return end
        local xumou = player:getVirualEquip(cards[i])
        if xumou and xumou.name == "premeditate" then
          local use = room:askToUseRealCard(player, {
            pattern = {cards[i]},
            skill_name = "premeditate",
            prompt = "#premediterate-use:::"..Fk:getCardById(cards[i], true):toLogString(),
            expand_pile = {cards[i]},
            extra_data = {
              expand_pile = {cards[i]},
              extra_use = true,
            },
            cancelable = true,
            skip = true
          })
          if use then
            room:setPlayerMark(player, "premeditate_"..use.card.trueName.."-" .."phase", 1)
            use.extra_data = use.extra_data or {}
            use.extra_data.premeditate = true
            room:useCard(use)
          else
            break
          end
        end
      end
    end
    cards = player:getCardIds(Player.Judge)
    local xumou = table.filter(cards, function(id)
      local card = player:getVirualEquip(id)
      return card and card.name == "premeditate"
    end)
    room:moveCardTo(xumou, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, premeditate_rule.name, nil, true, player.id)
  end,
})

return premeditate_rule
