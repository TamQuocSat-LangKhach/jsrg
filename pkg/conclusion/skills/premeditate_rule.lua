local premeditate_rule = fk.CreateSkill {
  name = "premeditate_rule"
}

Fk:loadTranslationTable{
  ["premeditate"] = "蓄谋",
  ["#premediterate-use"] = "你可以使用此蓄谋牌%arg，或点“取消”将所有蓄谋牌置入弃牌堆",
  ["premeditate_href"] = "将一张手牌扣置于判定区，判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌：1.使用此牌，\
  然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。",
}

premeditate_rule:addEffect(fk.EventPhaseStart, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("j")
    for i = #cards, 1, -1 do
      if table.contains(player:getCardIds("j"), cards[i]) then
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
            skip = true,
          })
          if use then
            room:addTableMark(player, "premeditate-phase", use.card.trueName)
            use.extra_data = use.extra_data or {}
            use.extra_data.premeditate = true
            player:removeVirtualEquip(use.card.id)
            room:useCard(use)
          else
            break
          end
        end
      end
    end
    cards = player:getCardIds("j")
    local xumou = table.filter(cards, function(id)
      local card = player:getVirualEquip(id)
      return card and card.name == "premeditate"
    end)
    room:moveCardTo(xumou, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, premeditate_rule.name, nil, true, player)
  end,
})

premeditate_rule:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("premeditate-phase"), card.trueName)
  end,
})

premeditate_rule:addEffect("visibility", {
  card_visible = function (self, player, card)
    local owner = Fk:currentRoom():getCardOwner(card)
    if owner and owner:getVirualEquip(card.id) and owner:getVirualEquip(card.id).name == "premeditate" then
      return false
    end
  end,
})

return premeditate_rule
