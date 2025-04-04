local js__juezhi = fk.CreateSkill {
  name = "js__juezhi"
}

Fk:loadTranslationTable{
  ['js__juezhi'] = '绝质',
  ['#js__juezhi-invoke'] = '绝质：你失去了%arg，是否废除对应的装备栏？',
  [':js__juezhi'] = '当你失去一张装备区里的装备牌后，你可以废除对应的装备栏；你回合内每阶段限一次，当你使用牌对目标角色造成伤害时，其装备区里每有一张与你已废除装备栏对应的装备牌，此伤害便+1。',
}

js__juezhi:addEffect(fk.AfterCardsMove, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(js__juezhi.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and player:hasSkill(js__juezhi.name) and 
            #player:getAvailableEquipSlots(Fk:getCardById(info.cardId).sub_type) > 0 then
            local e = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
            if e and e.data[3] == js__juezhi then  
              return false
            end
            skill:doCost(event, target, player, info.cardId)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = js__juezhi.name,
      prompt = "#js__juezhi-invoke:::"..Fk:getCardById(data):toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:abortPlayerArea(player, {Util.convertSubtypeAndEquipSlot(Fk:getCardById(data).sub_type)})
  end
})

js__juezhi:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(js__juezhi.name) and data.card and not data.chain and 
      #player.sealedSlots > 0 and table.find(data.to:getCardIds("e"), function(id) 
        return table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(Fk:getCardById(id).sub_type)) end) and 
      player.phase ~= Player.NotActive and player:usedSkillTimes(js__juezhi.name, Player.HistoryPhase) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("js__juezhi")
    room:notifySkillInvoked(player, "js__juezhi", "offensive")
    local n = 0
    for _, id in ipairs(data.to:getCardIds("e")) do
      if table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(Fk:getCardById(id).sub_type)) then
        n = n + 1
      end
    end
    data.damage = data.damage + n
  end,
})

return js__juezhi
