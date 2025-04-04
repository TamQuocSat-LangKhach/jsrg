local qiluan = fk.CreateSkill {
  name = "js__qiluan"
}

Fk:loadTranslationTable{
  ['js__qiluan'] = '起乱',
  ['#js__qiluan'] = '起乱：你可选择【杀】的目标，然后弃任意牌令等量其他角色选择是否替你出【杀】',
  ['js__qiluan_chooser'] = '起乱',
  ['#js__qiluan-use_slash'] = '起乱：选择任意张牌和等量其他角色，令其选择是否替你出【杀】',
  ['#js__qiluan-slash'] = '起乱：你可打出一张【杀】视为 %src 使用此牌',
  ['#js__qiluan_jink'] = '起乱',
  ['#js__qiluan-use_jink'] = '起乱：选择任意张牌和等量其他角色，令其选择是否替你出【闪】',
  ['#js__qiluan-jink'] = '起乱：你可打出一张【闪】视为 %src 使用此牌',
  [':js__qiluan'] = '每回合限两次，当你需要使用【杀】或【闪】时，你可以弃置至少一张牌并令至多等量名其他角色选择是否替你使用之。当有角色响应时，你摸等同于弃置的牌数。',
}

qiluan:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#js__qiluan",
  times = function(self, player)
    return 2 - player:usedSkillTimes(qiluan.name)
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = qiluan.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    if use.tos then
      room:doIndicate(player.id, TargetGroup:getRealTargets(use.tos))
    end

    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "js__qiluan_chooser",
      prompt = "#js__qiluan-use_slash",
      cancelable = false
    })
    local targets = success and dat.targets or room:getOtherPlayers(player)[1]
    local cards =
    success and
    dat.cards or
    table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)

    room:throwCard(cards, qiluan.name, player, player)

    for _, pId in ipairs(targets) do
      local cardResponded = room:askToResponse(room:getPlayerById(pId), {
        pattern = "slash",
        prompt = "#js__qiluan-slash:" .. player.id,
        cancelable = true
      })
      if cardResponded then
        player:drawCards(#cards, qiluan.name)

        room:responseCard({
          from = pId,
          card = cardResponded,
          skipDrop = true,
        })

        use.card = cardResponded
        return
      end
    end

    return qiluan.name
  end,
  enabled_at_play = function(self, player)
    return
      player:usedSkillTimes(qiluan.name) < 2 and
      table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end) and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player end)
  end,
  enabled_at_response = function(self, player, response)
    return
      not response and
      player:usedSkillTimes(qiluan.name) < 2 and
      table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end) and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player end)
  end,
})

qiluan:addEffect(fk.AskForCardUse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(qiluan.name) and
      player:usedSkillTimes(qiluan.name) < 2 and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      (data.extraData == nil or data.extraData.jsQiluanAsk == nil)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "js__qiluan_chooser",
      prompt = "#js__qiluan-use_jink",
      cancelable = true
    })

    if success then
      event:setCostData(skill, dat)
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(skill).cards, qiluan.name, player, player)

    room:doIndicate(player.id, event:getCostData(skill).targets)
    for _, pId in ipairs(event:getCostData(skill).targets) do
      local p = room:getPlayerById(pId)
      if p:isAlive() then
        local cardResponded = room:askToResponse(p, {
          pattern = "jink",
          prompt = "#js__qiluan-jink:" .. player.id,
          cancelable = true,
          extra_data = { jsQiluanAsk = true }
        })
        if cardResponded then
          player:drawCards(#event:getCostData(skill).cards, qiluan.name)

          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })

          data.result = {
            from = player.id,
            card = Fk:cloneCard('jink'),
          }
          data.result.card:addSubcards(room:getSubcardsByRule(cardResponded, { Card.Processing }))
          data.result.card.skillName = qiluan.name

          if data.eventData then
            data.result.toCard = data.eventData.toCard
            data.result.responseToEvent = data.eventData.responseToEvent
          end
          return true
        end
      end
    end
  end,
})

return qiluan
