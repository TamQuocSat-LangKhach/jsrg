local jianlou = fk.CreateSkill{
  name = "jianlou"
}

Fk:loadTranslationTable{
  ['jianlou'] = '舰楼',
  ['#jianlou1-invoke'] = '舰楼：%arg进入弃牌堆，是否弃置一张牌获得之？',
  ['#jianlou2-invoke'] = '舰楼：装备牌进入弃牌堆，是否弃置一张牌获得之？',
  ['#jianlou-prey'] = '舰楼：选择你要获得的装备牌',
  [':jianlou'] = '每回合限一次，当一张装备牌进入弃牌堆后，你可以弃置一张牌并获得之，然后若你对应装备栏没有装备，你使用之。',
}

jianlou:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jianlou.name) and player:usedSkillTimes(jianlou.name, Player.HistoryTurn) == 0 and not player:isNude() then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).type == Card.TypeEquip and table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards = table.simpleClone(event:getCostData(self))
    local card = {}
    if #cards == 1 then
      card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jianlou.name,
        cancelable = true,
        prompt = "#jianlou1-invoke:::"..Fk:getCardById(cards[1]):toLogString(),
        skip = true
      })
    elseif #cards > 1 then
      card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jianlou.name,
        cancelable = true,
        prompt = "#jianlou2-invoke",
        skip = true
      })
    end
    if #card > 0 then
      event:setCostData(self, {cards = card, extra_data = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, jianlou.name, player, player)
    if player.dead then return end
    local id = 0
    if #event:getCostData(self).extra_data == 1 then
      if table.contains(room.discard_pile, event:getCostData(self).extra_data[1]) then
        id = event:getCostData(self).extra_data[1]
      else
        return
      end
    else
      local cards = table.filter(event:getCostData(self).extra_data, function (c)
        return table.contains(room.discard_pile, c)
      end)
      if #cards == 0 then return end
      id = player.room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        choices = {"OK"},
        skill_name = jianlou.name,
        prompt = "#jianlou-prey"
      })[2][1]
    end
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, jianlou.name, nil, true, player.id)
    if player.dead or not table.contains(player:getCardIds("h"), id) then return end
    local card = Fk:getCardById(id)
    if #player:getEquipments(card.sub_type) == 0 and not player:prohibitUse(card) then
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    end
  end,
})

return jianlou
