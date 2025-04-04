local tianyu = fk.CreateSkill {
  name = "js__tianyu"
}

Fk:loadTranslationTable{
  ['js__tianyu'] = '天予',
  ['#js__tianyu-choose'] = '天予：选择要获得的牌',
  [':js__tianyu'] = '当一张伤害牌或装备牌进入弃牌堆后，若此牌于本回合内未属于过任何角色，则你可以获得之。',
}

tianyu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tianyu) then
      return false
    end

    local toObtain = {}
    for _, info in ipairs(data) do
      if info.toArea == Card.DiscardPile then
        for _, moveInfo in ipairs(info.moveInfo) do
          if moveInfo.fromArea ~= Player.Hand and moveInfo.fromArea ~= Player.Equip then
            local cardMoved = Fk:getCardById(moveInfo.cardId)
            if cardMoved.is_damage_card or cardMoved.type == Card.TypeEquip then
              table.insert(toObtain, moveInfo.cardId)
            end
          end
        end
      end
    end

    local room = player.room
    toObtain = table.filter(toObtain, function(id) return room:getCardArea(id) == Card.DiscardPile end)

    if #toObtain == 0 then
      return false
    end

    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, info in ipairs(e.data) do
        if info.from then
          local infosFound = table.filter(
            info.moveInfo,
            function(moveInfo) return table.contains({ Card.PlayerHand, Card.PlayerEquip }, moveInfo.fromArea) end
          )
          for _, moveInfo in ipairs(infosFound) do
            table.removeOne(toObtain, moveInfo.cardId)
          end
        end
      end
      return #toObtain == 0
    end, Player.HistoryTurn)

    if #toObtain > 0 then
      event:setCostData(self, toObtain)
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards, choice = player.room:askToChoices(
      player,
      {
        choices = { "OK" },
        skill_name = tianyu.name,
        prompt = "#js__tianyu-choose",
        all_choices = { "get_all", "Cancel" },
        cancelable = true
      }
    )

    if choice == "Cancel" then
      return false
    end

    if choice == "OK" then
      event:setCostData(self, cards)
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toObtain = table.filter(event:getCostData(self), function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #toObtain > 0 then
      room:obtainCard(player, toObtain, true, fk.ReasonPrey, player.id, tianyu.name)
    end
  end,
})

return tianyu
