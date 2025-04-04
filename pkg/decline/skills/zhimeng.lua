local zhimeng = fk.CreateSkill {
  name = "js__zhimeng"
}

Fk:loadTranslationTable{
  ['js__zhimeng'] = '执盟',
  ['#js__zhimeng-display'] = '执盟：请展示一张手牌，若与其他角色展示的牌花色均不同，则你获得亮出牌中此花色的牌',
  [':js__zhimeng'] = '准备阶段开始时，你可以亮出牌堆顶存活角色数的牌，令所有角色同时展示一张手牌，展示不重复花色手牌的角色获得亮出牌中此花色的所有牌。',
}

zhimeng:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhimeng.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(#room.alive_players)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = zhimeng.name,
      proposer = player.id,
    })
    room:delay(2000)

    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    if #targets > 0 then
      local result = room:askToJointCard(targets, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = zhimeng.name,
        cancelable = false,
        prompt = "#js__zhimeng-display",
      })

      local suitsDisplayed = {}
      for _, p in ipairs(targets) do
        local cardDisplayed = Fk:getCardById(result[p.id][1])
        suitsDisplayed[cardDisplayed:getSuitString()] = suitsDisplayed[cardDisplayed:getSuitString()] or {}
        table.insert(suitsDisplayed[cardDisplayed:getSuitString()], p.id)
        p:showCards(cardDisplayed)
      end
      room:delay(2000)

      local targetsToObtain = {}
      local playersDisplayed = {}
      for suit, pIds in pairs(suitsDisplayed) do
        if #pIds == 1 then
          table.insert(targetsToObtain, pIds[1])
          playersDisplayed[pIds[1]] = suit
        end
      end

      room:sortPlayersByAction(targetsToObtain)
      for _, pId in ipairs(targetsToObtain) do
        local cardsInProcessing = table.filter(cards, (function(id) return room:getCardArea(id) == Card.Processing end))
        local cardsToGain = table.filter(cardsInProcessing, function(id) return Fk:getCardById(id):getSuitString() == playersDisplayed[pId] end)
        if #cardsToGain > 0 then
          room:obtainCard(room:getPlayerById(pId), cardsToGain, true, fk.ReasonPrey, pId, zhimeng.name)
        end
      end
    end

    local toThrow = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #toThrow then
      room:moveCards{
        ids = toThrow,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = zhimeng.name,
      }
    end
  end,
})

return zhimeng
