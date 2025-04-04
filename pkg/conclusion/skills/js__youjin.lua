local js__youjin = fk.CreateSkill {
  name = "js__youjin"
}

Fk:loadTranslationTable{
  ['js__youjin'] = '诱进',
  ['#js__youjin-choose'] = '诱进：可以拼点，双方不能使用或打出点数小于各自拼点牌的手牌，赢的角色视为对对方使用【杀】',
  ['@js__youjin-turn'] = '诱进',
  [':js__youjin'] = '出牌阶段开始时，你可以与一名角色拼点，双方本回合不能使用或打出点数小于各自拼点牌的手牌，赢的角色视为对没赢的角色使用一张【杀】。',
}

-- 触发技效果
js__youjin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(js__youjin) and player == target and player.phase == Player.Play and not player:isKongcheng()
      and table.find(player.room.alive_players, function (p) return player:canPindian(p) end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return player:canPindian(p) end)
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#js__youjin-choose",
      skill_name = js__youjin.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local pindian = player:pindian({to}, js__youjin.name)
    local winner = pindian.results[to.id].winner
    local fromNum = pindian.fromCard.number
    if fromNum > 0 and not player.dead then
      fromNum = math.max(fromNum, player:getMark("@js__youjin-turn"))
      room:setPlayerMark(player, "@js__youjin-turn", fromNum)
    end
    local toNum = pindian.results[to.id].toCard.number
    if toNum > 0 and not to.dead then
      fromNum = math.max(toNum, to:getMark("@js__youjin-turn"))
      room:setPlayerMark(to, "@js__youjin-turn", toNum)
    end
    if winner and not winner.dead then
      local loser = (winner == player) and to or player
      if not loser.dead then
        room:useVirtualCard("slash", nil, winner, loser, js__youjin.name, true)
      end
    end
  end,
})

-- 禁用技效果
js__youjin:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@js__youjin-turn")
    if mark ~= 0 and card and card.number > 0 and card.number < mark then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return #cards > 0 and table.every(cards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("@js__youjin-turn")
    if mark ~= 0 and card and card.number > 0 and card.number < mark then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return #cards > 0 and table.every(cards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
})

return js__youjin
