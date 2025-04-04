local juelie = fk.CreateSkill {
  name = "juelie"
}

Fk:loadTranslationTable{
  ['juelie'] = '绝烈',
  ['#juelie-discard'] = '绝烈：你可以弃置任意张牌，然后弃置 %dest 至多等量的牌',
  [':juelie'] = '当你使用【杀】造成伤害时，若你是手牌数最小或体力值最小的角色，则此伤害+1；当你使用【杀】指定目标后，你可以弃置任意张牌，然后弃置其至多等量的牌。',
  ['$juelie1'] = '诸君放手，祸福，某一肩担之！',
  ['$juelie2'] = '先登破城，方不负孙氏勇烈！'
}

juelie:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(juelie.name) and data.card and data.card.trueName == "slash" then
      local room = player.room
      return not data.chain and (table.every(room.alive_players, function(p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) or table.every(room.alive_players, function(p)
          return p.hp >= player.hp
        end))
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    end
  end,
})

juelie:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    local to = player.room:getPlayerById(data.to)
    return not to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = juelie.name,
      cancelable = true,
      prompt = "#juelie-discard::" .. data.to,
      no_indicate = true
    })
    if #cards > 0 then
      event:setCostData(skill, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(skill).cards)
    room:throwCard(cards, juelie.name, player, player)
    local to = room:getPlayerById(data.to)
    if not (player.dead or to.dead or to:isNude()) then
      cards = room:askToChooseCards(player, {
        min_num = 1,
        max_num = math.min(#cards, #to:getCardIds("he")),
        include_equip = false,
        target = to,
        skill_name = juelie.name
      })
      room:throwCard(cards, juelie.name, to, player)
    end
  end,
})

return juelie
