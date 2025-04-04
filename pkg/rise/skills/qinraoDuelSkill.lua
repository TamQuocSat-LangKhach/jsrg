local qinraoDuelSkill = fk.CreateSkill {
  name = "qinrao__duel_skill"
}

Fk:loadTranslationTable{
  ['#qinrao-duel'] = '侵扰：你必须打出一张【杀】！点“取消”则随机打出一张【杀】，若没有则展示手牌',
}

qinraoDuelSkill:addEffect('active', {
  prompt = "#duel_skill",
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player.id
  end,
  target_filter = function(self, player, to_select, selected, _, card)
    if #selected < skill:getMaxTargetNum(player, card) then
      return skill:modTargetFilter(to_select, selected, player, card)
    end
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local from = room:getPlayerById(effect.from)
    local responsers = { to, from }
    local currentTurn = 1
    local currentResponser = to

    while currentResponser:isAlive() do
      local loopTimes = 1
      if effect.fixedResponseTimes then
        local canFix = currentResponser == to
        if effect.fixedAddTimesResponsors then
          canFix = table.contains(effect.fixedAddTimesResponsors, currentResponser.id)
        end

        if canFix then
          if type(effect.fixedResponseTimes) == 'table' then
            loopTimes = effect.fixedResponseTimes["slash"] or 1
          elseif type(effect.fixedResponseTimes) == 'number' then
            loopTimes = effect.fixedResponseTimes
          end
        end
      end

      local cardResponded
      for i = 1, loopTimes do
        if currentResponser == to then
          cardResponded = room:askToResponse(currentResponser, {
            pattern = "slash",
            prompt = "#qinrao-duel",
            cancelable = true,
            extra_data = nil,
            event_data = effect,
          })
        else
          cardResponded = room:askToResponse(currentResponser, {
            pattern = "slash",
            prompt = nil,
            cancelable = true,
            extra_data = nil,
            event_data = effect,
          })
        end

        if cardResponded then
          room:responseCard({
            from = currentResponser.id,
            card = cardResponded,
            responseToEvent = effect,
          })
        else
          if currentResponser == to then
            local cards = table.filter(to:getCardIds("h"), function (id)
              local card = Fk:getCardById(id)
              return card.trueName == "slash" and not to:prohibitResponse(card)
            end)

            if #cards > 0 then
              cardResponded = Fk:getCardById(table.random(cards))
              room:responseCard({
                from = to.id,
                card = cardResponded,
                responseToEvent = effect,
              })
            else
              if not to:isKongcheng() then
                to:showCards(to:getCardIds("h"))
              end
              break
            end
          else
            break
          end
        end
      end

      if not cardResponded then break end

      currentTurn = currentTurn % 2 + 1
      currentResponser = responsers[currentTurn]
    end

    if currentResponser:isAlive() then
      room:damage({
        from = responsers[currentTurn % 2 + 1],
        to = currentResponser,
        card = effect.card,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = "duel_skill",
      })
    end
  end
})

return qinraoDuelSkill
