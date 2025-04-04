local gangfen = fk.CreateSkill {
  name = "gangfen",
}

Fk:loadTranslationTable{
  ['gangfen'] = '刚忿',
  ['#gangfen-invoke'] = '刚忿：你可以成为 %dest 使用的 %arg 的额外目标，若最后使用者手中黑牌少于目标数则取消所有目标（当前目标数为%arg2）',
  ['#GangFenAdd'] = '%from 因“刚忿”选择成为 %to 使用的 %arg 的目标（当前目标数为%arg2）',
  ['#GangFenCancel'] = '%from 手牌中的黑色牌数小于 %arg 的目标数，因“刚忿”被取消',
  [':gangfen'] = '当手牌数大于你的角色使用【杀】指定第一个目标时，你可以成为此【杀】的额外目标，并令所有其他角色均可以如此做。然后使用者展示所有手牌，若其中黑色牌小于目标数，则取消所有目标。',
}

gangfen:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player, data)
    return
      data.firstTarget and
      data.card.trueName == "slash" and
      player:hasSkill(gangfen.name) and
      target:getHandcardNum() > player:getHandcardNum() and
      table.contains(player.room:getUseExtraTargets(data, true, true), player.id)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return
    room:askToSkillInvoke(
      player,
      {
        skill_name = gangfen.name,
        prompt = "#gangfen-invoke::" .. target.id .. ":" .. data.card:toLogString() .. ":" .. #U.getActualUseTargets(room, data, event)
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AimGroup:addTargets(room, data, player.id)
    room:sendLog{
      type = "#GangFenAdd",
      from = player.id,
      to = { target.id },
      arg = data.card:toLogString(),
      arg2 = #U.getActualUseTargets(room, data, event),
      toast = true,
    }
    local availableTargets = room:getUseExtraTargets(data, true, true)
    room:sortPlayersByAction(availableTargets)
    for _, pId in ipairs(availableTargets) do
      if
        room:askToSkillInvoke(
          room:getPlayerById(pId),
          {
            skill_name = gangfen.name,
            prompt = "#gangfen-invoke::" .. target.id .. ":" .. data.card:toLogString() .. ":" .. #U.getActualUseTargets(room, data, event)
          }
        )
      then
        room:doIndicate(target.id, { pId })
        AimGroup:addTargets(room, data, pId)
        room:sendLog{
          type = "#GangFenAdd",
          from = pId,
          to = { target.id },
          arg = data.card:toLogString(),
          arg2 = #U.getActualUseTargets(room, data, event),
          toast = true,
        }
      end
    end

    local handcards = target:getCardIds("h")
    if target:isAlive() and #handcards > 0 then
      target:showCards(handcards)
      room:delay(2000)
    end

    if
      #table.filter(handcards, function(id) return Fk:getCardById(id).color == Card.Black end) <
      #U.getActualUseTargets(room, data, event)
    then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        AimGroup:cancelTarget(data, id)
      end
      room:sendLog{
        type = "#GangFenCancel",
        from = target.id,
        arg = data.card:toLogString(),
        toast = true,
      }

      return true
    end
  end,
})

return gangfen
