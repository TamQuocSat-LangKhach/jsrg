local jvxiang = fk.CreateSkill {
  name = "jvxiang",
}

Fk:loadTranslationTable{
  ["jvxiang"] = "拒降",
  ["#jvxiang-invoke"] = "拒降：是否弃置这些牌，令当前回合角色使用【杀】次数上限增加？",
  [":jvxiang"] = "当你于摸牌阶段外获得牌后，你可以弃置这些牌，令当前回合角色于本回合出牌阶段使用【杀】次数上限+X（X为你此次弃置牌的花色数）。",
}

jvxiang:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jvxiang.name) then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Player.Hand and player.phase ~= Player.Draw then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jvxiang.name,
      prompt = "#jvxiang-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local suits = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand and player.phase ~= Player.Draw then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
          local suit = Fk:getCardById(info.cardId).suit
          if suit ~= Card.NoSuit then
            table.insertIfNeed(suits, suit)
          end
        end
      end
    end
    room:throwCard(cards, jvxiang.name, player, player)
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event and not turn_event.data[1].dead then
      room:addPlayerMark(turn_event.data[1], MarkEnum.SlashResidue.."-turn", #suits)
    end
  end,
})

return jvxiang
