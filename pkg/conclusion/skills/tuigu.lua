local tuigu = fk.CreateSkill {
  name = "tuigu"
}

Fk:loadTranslationTable{
  ['tuigu'] = '蜕骨',
  ['#tuigu-invoke'] = '蜕骨：你可以将武将牌翻面，令本回合手牌上限+%arg ，然后摸 %arg 张牌',
  ['#tuigu-jiejia'] = '蜕骨：选择你使用【解甲归田】的目标（令其收回装备区所有牌）',
  ['@@tuigu-inhand'] = '蜕骨',
  [':tuigu'] = '回合开始时，你可以翻面令你本回合手牌上限+X，然后摸X张牌并视为使用一张【解甲归田】（目标角色不能使用这些装备牌直到其回合结束，X为场上角色数的一半，向下取整）；每轮结束时，若你本轮未行动过，你执行一个额外的回合；当你失去装备区里的牌后，你回复一点体力。',
  ['$tuigu1'] = '臣老年虚乏，唯愿乞骸骨。',
  ['$tuigu2'] = '今指水为誓，若有相违，天弃之！',
  ['$tuigu3'] = '汉室世衰，天命在曹；曹氏世衰，天命归我。',
  ['$tuigu4'] = '天时已至而犹谦让，舜禹所不为也。',
  ['$tuigu5'] = '皇天眷我，神人同谋，当取此天下。',
}

tuigu:addEffect(fk.TurnStart, {
  mute = true,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local draw = #room.alive_players // 2
    return room:askToSkillInvoke(player, {skill_name = tuigu.name, prompt = "#tuigu-invoke:::"..tostring(draw)})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tuigu.name, math.random(2))
    room:notifySkillInvoked(player, tuigu.name, "drawcard")
    player:turnOver()
    if player.dead then return false end
    local n = #room.alive_players // 2
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, n)
    room:drawCards(player, n, tuigu.name)
    if player.dead then return false end
    U.askForUseVirtualCard(room, player, "demobilized", nil, tuigu.name, "#tuigu-jiejia", false)
  end,
})

tuigu:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "demobilized" then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insertIfNeed(cards, id)
          end
        end
      end
    end
    if #cards == 0 then return false end
    local cardEffectData = event:findParent(GameEvent.CardEffect)
    if cardEffectData then
      local cardEffectEvent = cardEffectData.data[1]
      if table.contains(cardEffectEvent.card.skillNames, "tuigu") then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@tuigu-inhand", 1)
        end
      end
    end
  end,
})

tuigu:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    U.clearHandMark(player, "@@tuigu-inhand")
  end,
})

local tuigu_recoverAndTurn = fk.CreateSkill {
  name = "#tuigu_recoverAndTurn"
}

tuigu_recoverAndTurn:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tuigu.name) then return false end
    if not player:isWounded() then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tuigu", "defensive")
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = tuigu.name
    })
  end,
})

tuigu_recoverAndTurn:addEffect(fk.RoundEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tuigu.name) then return false end
    return #player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
      return e.data[1] == player
    end, Player.HistoryRound) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tuigu", math.random(3,5))
    room:notifySkillInvoked(player, "tuigu", "control")
    player:gainAnExtraTurn(true, tuigu.name)
  end,
})

local tuigu_prohibit = fk.CreateSkill {
  name = "#tuigu_prohibit"
}

tuigu_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return Fk:getCardById(id):getMark("@@tuigu-inhand") > 0 end)
  end,
})

return tuigu
