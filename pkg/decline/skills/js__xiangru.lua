local js__xiangru = fk.CreateSkill {
  name = "js__xiangru"
}

Fk:loadTranslationTable{
  ['js__xiangru'] = '相濡',
  ['#xiangru-give'] = '相濡：是否交给 %dest 两张牌，防止 %src 受到的伤害？',
  [':js__xiangru'] = '当一名已受伤的其他角色/你受到致命伤害时，你/其他已受伤的角色可以交给伤害来源两张牌防止此伤害。',
}

js__xiangru:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(js__xiangru.name) and data.from and data.from:isAlive() and data.damage >= (target.hp + target.shield)) then
      return false
    end

    local room = player.room
    if target == player then
      return table.find(room.alive_players, function(p) return p ~= player and #p:getCardIds("he") > 1 and p ~= data.from end)
    elseif target ~= player and target:isWounded() then
      return #player:getCardIds("he") > 1 and player ~= data.from
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if target ~= player then
      local cards = room:askToCards(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = js__xiangru.name,
        cancelable = true,
        prompt = "#xiangru-give:" .. target.id .. ":" .. data.from.id
      })
      if #cards > 1 then
        event:setCostData(self, cards)
        return true
      end
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p:getCardIds("he") > 1 and p:isWounded() and p ~= data.from and p:isAlive() then
          local cards = room:askToCards(p, {
            min_num = 2,
            max_num = 2,
            include_equip = true,
            skill_name = js__xiangru.name,
            cancelable = true,
            prompt = "#xiangru-give:" .. target.id .. ":" .. data.from.id
          })
          if #cards > 1 then
            event:setCostData(self, cards)
            return true     
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    room:obtainCard(data.from.id, cost_data, false, fk.ReasonGive, (room:getCardOwner(cost_data[1]) or {}).id)
    return true
  end,
})

return js__xiangru
