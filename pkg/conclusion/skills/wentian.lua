local wentian = fk.CreateSkill {
  name = "wentian"
}

Fk:loadTranslationTable{
  ['wentian'] = '问天',
  ['#wentian_trigger'] = '问天',
  ['#wentian-ask'] = '你是否发动技能“问天”（当前为 %arg ）？',
  ['#wentian-give'] = '问天：请选择其中一张牌交给一名其他角色',
  [':wentian'] = '你可以将牌堆顶的牌当【无懈可击】/【火攻】使用，若此牌不为黑色/红色，本技能于本轮内失效；\\\n  每回合限一次，你的任意阶段开始时，你可以观看牌堆顶五张牌，然后将其中一张牌交给一名其他角色，其余牌以任意顺序置于牌堆顶或牌堆底。',
}

wentian:addEffect('viewas', {
  pattern = "fire_attack,nullification",
  interaction = function()
    local availableNames = { "fire_attack", "nullification" }
    local names = U.getViewAsCardNames(Self, "wentian", availableNames)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = availableNames }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards ~= 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = wentian.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local topCardId = room:getNCards(1)[1]

    use.card:addSubcard(topCardId)
    local cardColor = Fk:getCardById(topCardId).color
    if (use.card.name == "nullification" and cardColor ~= Card.Black) or
      (use.card.name == "fire_attack" and cardColor ~= Card.Red)
    then
      room:invalidateSkill(player, wentian.name, "-round")
    end
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

wentian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(wentian.name) and
      player:getMark("wentian_trigger-turn") == 0 and
      player.phase > 1 and player.phase < 8
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wentian.name,
      prompt = "#wentian-ask:::" .. Util.PhaseStrMapper(player.phase),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "wentian_trigger-turn", 1)
    local topCardIds = U.turnOverCardsFromDrawPile(player, 5, wentian.name, false)

    local others = room:getOtherPlayers(player, false)
    if #others > 0 then
      local _, ret = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        targets = table.map(others, Util.IdMapper),
        min_target_num = 1,
        max_target_num = 1,
        pattern = tostring(Exppattern{ id = topCardIds }),
        skill_name = "wentian",
        expand_pile = topCardIds,
      })

      local toGive = ret and ret.cards[1] or topCardIds[1]
      table.removeOne(topCardIds, toGive)
      room:moveCardTo(
        toGive,
        Card.PlayerHand,
        ret and room:getPlayerById(ret.targets[1]) or room:getOtherPlayers(player)[1],
        fk.ReasonGive,
        "wentian",
        nil,
        false,
        player.id,
        nil,
        player.id
      )

      if player.dead then
        room:cleanProcessingArea(topCardIds, wentian.name)
        return false
      end
    end

    local result = room:askToGuanxing(player, {
      cards = topCardIds,
      skill_name = "wentian",
      skip = true,
    })

    room:sendLog{
      type = "#GuanxingResult",
      from = player.id,
      arg = #result.top,
      arg2 = #result.bottom,
    }

    local moveInfos = {}
    if #result.top > 0 then
      table.insert(moveInfos, {
        ids = table.reverse(result.top),
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = wentian.name,
        proposer = player.id,
        moveVisible = false,
        visiblePlayers = player.id,
        drawPilePosition = 1
      })
    end

    if #result.bottom > 0 then
      table.insert(moveInfos, {
        ids = result.bottom,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = wentian.name,
        proposer = player.id,
        moveVisible = false,
        visiblePlayers = player.id,
        drawPilePosition = -1
      })
    end

    room:moveCards(table.unpack(moveInfos))
  end,
})

return wentian
