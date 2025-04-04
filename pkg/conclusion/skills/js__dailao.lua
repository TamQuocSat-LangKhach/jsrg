local js__dailao = fk.CreateSkill {
  name = "js__dailao"
}

Fk:loadTranslationTable{
  ['js__dailao'] = '待劳',
  [':js__dailao'] = '出牌阶段，若你没有可以使用的手牌，你可以展示所有手牌并摸两张牌，然后结束回合。',
}

js__dailao:addEffect('active', {
  anim_type = "drawcard",
  can_use = function(self, player)
    return not player:isKongcheng() and table.every(player:getCardIds("h"), function (id)
      local card = Fk:getCardById(id)
      return player:prohibitUse(card) or not player:canUse(card)
        or not table.find(Fk:currentRoom().alive_players, function (p)
          return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, true)
        end)
    end)
  end,
  target_num = 0,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(player:getCardIds("h"))
    player:drawCards(2, js__dailao.name)
    room:endTurn()
  end,
})

return js__dailao
