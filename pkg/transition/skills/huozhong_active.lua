local huozhong = fk.CreateSkill {
  name = "huozhong"
}

Fk:loadTranslationTable{
  ['huozhong&'] = '惑众',
  ['#huozhong&-invoke'] = '惑众：你可以将一张黑色非锦囊牌当【兵粮寸断】置于判定区，令张楚摸两张牌',
  ['huozhong'] = '惑众',
  [':huozhong&'] = '出牌阶段限一次，你可以将一张黑色非锦囊牌当【兵粮寸断】置于判定区，令张楚摸两张牌。',
}

huozhong:addEffect('active', {
  name = "huozhong&",
  anim_type = "support",
  target_num = 0,
  card_num = 1,
  prompt = "#huozhong&-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(huozhong.name, Player.HistoryPhase) == 0 and not player:hasDelayedTrick("supply_shortage")
      and not table.contains(player.sealedSlots, Player.JudgeSlot)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeTrick and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    player:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, player, fk.ReasonPut, huozhong.name)
    local target
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill(huozhong.name, true) then
        target = p
        break
      end
    end
    if not target then return end
    target:broadcastSkillInvoke("huozhong")
    room:notifySkillInvoked(target, "huozhong", "drawcard")
    room:doIndicate(player.id, {target.id})
    target:drawCards(2, huozhong.name)
  end,
})

return huozhong
