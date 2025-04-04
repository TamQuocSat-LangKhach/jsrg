local ruzong = fk.CreateSkill {
  name = "ruzong"
}

Fk:loadTranslationTable{
  ['ruzong'] = '儒宗',
  ['#ruzong-invoke'] = '儒宗：你可以将手牌数摸至与 %dest 相同',
  ['#ruzong-choose'] = '儒宗：你可以令至少一名其他角色将手牌数摸至与你相同',
  [':ruzong'] = '回合结束时，若你本回合使用牌指定过的目标角色均为同一角色，则你可以将手牌数摸至与其相同（至多摸五张），若该目标为你，则改为你可令至少一名其他角色将手牌数摸至与你相同。',
}

ruzong:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(ruzong.name)) then
      return false
    end

    local room = player.room
    local sameTarget
    local diffFound = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if e.data[1].from ~= player.id then
        return false
      end

      local tos = TargetGroup:getRealTargets(e.data[1].tos)
      if #tos > 1 then
        return true
      elseif #tos == 0 then
        return false
      elseif not sameTarget then
        sameTarget = tos[1]
      elseif sameTarget ~= tos[1] then
        return true
      end
      return false
    end, Player.HistoryTurn)

    if #diffFound == 0 and sameTarget and room:getPlayerById(sameTarget):isAlive() then
      if
        (sameTarget ~= player.id and player:getHandcardNum() >= room:getPlayerById(sameTarget):getHandcardNum()) or
        (
        sameTarget == player.id and
        not table.find(room.alive_players, function(p) return p ~= player and p:getHandcardNum() < player:getHandcardNum() end)
      )
      then
        return false
      end

      event:setCostData(self, sameTarget)
      return true
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local sameTarget = room:getPlayerById(event:getCostData(self))
    event:setCostData(self, nil)
    if sameTarget ~= player then
      if
        room:askToSkillInvoke(player, {
          skill_name = ruzong.name,
          prompt = "#ruzong-invoke::" .. sameTarget.id
        })
      then
        event:setCostData(self, sameTarget.id)
        return true
      end
    else
      local targets = table.filter(room.alive_players, function(p) return p ~= player and p:getHandcardNum() < player:getHandcardNum() end)
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = #targets,
        prompt = "#ruzong-choose",
        skill_name = ruzong.name
      })
      if #tos > 0 then
        event:setCostData(self, tos)
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(event:getCostData(self)) == "number" then
      local sameTarget = room:getPlayerById(event:getCostData(self))
      if sameTarget:getHandcardNum() > player:getHandcardNum() then
        player:drawCards(math.min(sameTarget:getHandcardNum() - player:getHandcardNum(), 5), ruzong.name)
      end
    else
      for _, pId in ipairs(event:getCostData(self)) do
        local p = room:getPlayerById(pId)
        if player:getHandcardNum() > p:getHandcardNum() then
          p:drawCards(player:getHandcardNum() - p:getHandcardNum(), ruzong.name)
        end
      end
    end
  end,
})

return ruzong
