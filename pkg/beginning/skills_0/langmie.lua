local langmie = fk.CreateSkill {
  name = "langmie",
}

Fk:loadTranslationTable{
  ["langmie"] = "狼灭",
  ["#langmie3"] = "狼灭：你可以弃置一张牌，然后摸两张牌或对 %dest 造成1点伤害",
  ["#langmie1"] = "狼灭：你可以弃置一张牌，摸两张牌",
  ["#langmie2"] = "狼灭：你可以弃置一张牌，对 %dest 造成1点伤害",
  ["langmie_damage"] = "对其造成1点伤害",
  [":langmie"] = "其他角色的结束阶段，你可以选择一项：<br>1.若其本回合使用过至少两张相同类型的牌，你可以弃置一张牌，摸两张牌；<br>2.若其本回合造成过至少2点伤害，你可以弃置一张牌，对其造成1点伤害。",
  ["$langmie1"] = "群狼四起，灭其一威众。",
  ["$langmie2"] = "贪狼强力，寡义而趋利。",
}

langmie:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(langmie.name) and target ~= player and target.phase == Player.Finish and not player:isNude() then
      local room = player.room
      event:setCostData(self, {})
      local count = {0, 0, 0}
      room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.from == target.id then
          if use.card.type == Card.TypeBasic then
            count[1] = count[1] + 1
          elseif use.card.type == Card.TypeTrick then
            count[2] = count[2] + 1
          elseif use.card.type == Card.TypeEquip then
            count[3] = count[3] + 1
          end
        end
      end, Player.HistoryTurn)
      if table.find(count, function(i) return i > 1 end) then
        table.insert(event:getCostData(self), 1)
      end
      local n = 0
      room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        if damage.from and target == damage.from then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n > 1 then
        table.insert(event:getCostData(self), 2)
      end
      if #event:getCostData(self) == 2 then
        return true
      elseif #event:getCostData(self) == 1 then
        if event:getCostData(self)[1] == 1 then
          return true
        elseif event:getCostData(self)[1] == 2 then
          return not target.dead
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if #event:getCostData(self) == 2 then
      prompt = "#langmie3::"..target.id
    elseif event:getCostData(self)[1] == 1 then
      prompt = "#langmie1"
    elseif event:getCostData(self)[1] == 2 then
      prompt = "#langmie2::"..target.id
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = langmie.name,
      cancelable = true,
      pattern = nil,
      prompt = prompt,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card, choice = prompt[9]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, langmie.name, player, player)
    if player.dead then return end
    if event:getCostData(self).choice == "1" then
      player:drawCards(2, langmie.name)
    elseif event:getCostData(self).choice == "2" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = langmie.name,
      }
    elseif event:getCostData(self).choice == "3" then
      if target.dead then
        player:drawCards(2, langmie.name)
      else
        local choice = room:askToChoice(player, {
          choices = {"draw2", "langmie_damage"},
          skill_name = langmie.name,
        })
        if choice == "draw2" then
          player:drawCards(2, langmie.name)
        else
          room:damage{
            from = player,
            to = target,
            damage = 1,
            skillName = langmie.name,
          }
        end
      end
    end
  end,
})

return langmie
