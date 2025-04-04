local shacheng = fk.CreateSkill {
  name = "shacheng"
}

Fk:loadTranslationTable{
  ['shacheng'] = '沙城',
  ['shacheng_active'] = '沙城',
  ['#shacheng-invoke'] = '沙城：你可以移去一张“沙城”，令其中一名目标摸其本回合失去牌数的牌',
  [':shacheng'] = '游戏开始时，你将牌堆顶的两张牌置于你的武将牌上；当一名角色使用一张【杀】结算后，你可以移去武将牌上的一张牌，令其中一名目标角色摸X张牌（X为该目标本回合失去的牌数且至多为5）。',
}

shacheng:addEffect({fk.GameStart, fk.CardUseFinished}, {
  derived_piles = "shacheng",
  expand_pile = "shacheng",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shacheng) then
      return event == fk.GameStart or (data.card.trueName == "slash" and #player:getPile(shacheng.name) > 0 and data.tos and
        table.find(TargetGroup:getRealTargets(data.tos), function(id) return not player.room:getPlayerById(id).dead end))
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local room = player.room
      room:setPlayerMark(player, "shacheng-tmp", table.filter(TargetGroup:getRealTargets(data.tos),
        function(id) return not room:getPlayerById(id).dead end))
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "shacheng_active",
        prompt = "#shacheng-invoke",
        cancelable = true
      })
      room:setPlayerMark(player, "shacheng-tmp", 0)
      if success then
        event:setCostData(self, dat)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:addToPile(shacheng.name, room:getNCards(2), true, shacheng.name)
    else
      room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, player, fk.ReasonJustMove, shacheng.name, shacheng.name, true, player.id)
      local to = room:getPlayerById(event:getCostData(self).targets[1])
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == to.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if n == 0 or to.dead then return end
      to:drawCards(n, shacheng.name)
    end
  end,
})

return shacheng
