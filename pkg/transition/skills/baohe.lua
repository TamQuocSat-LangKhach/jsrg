local baohe = fk.CreateSkill {
  name = "baohe"
}

Fk:loadTranslationTable{
  ['baohe'] = '暴喝',
  ['#baohe-discard'] = '暴喝：你可以弃置两张牌，视为对所有攻击范围内包含 %dest 的角色使用【杀】',
  [':baohe'] = '一名角色出牌阶段结束时，你可以弃置两张牌，然后视为你对攻击范围内包含其的所有角色使用一张无距离限制的【杀】，当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。',
}

baohe:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(baohe.name) and target.phase == Player.Play and #player:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player)
    local cards = player.room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = baohe.name,
      cancelable = true,
      pattern = ".",
      prompt = "#baohe-discard::" .. target.id,
    })
    if #cards > 1 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:throwCard(event:getCostData(self), baohe.name, player, player)
    local targets = {}
    for _, p in ipairs(player.room:getOtherPlayers(target)) do
      if Fk:currentRoom():getPlayerById(p.id):inMyAttackRange(target) and p ~= player then
        table.insert(targets, p)
      end
    end
    room:useVirtualCard("slash", nil, player, targets, baohe.name, true)
  end,
})

baohe:addEffect(fk.DamageCaused, {
  can_refresh = function(self, event, target, player)
    return player:hasSkill(baohe.name) and player:getMark("baohe_adddamage-phase") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local num = player:getMark("baohe_adddamage-phase")
    data.damage = data.damage + num
  end,
})

baohe:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(baohe.name) and data.card.name == "jink" and data.toCard and data.toCard.trueName == "slash" and table.contains(data.toCard.skillNames, "baohe") and data.responseToEvent.from == player.id
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "baohe_adddamage-phase", 1)
  end,
})

return baohe
