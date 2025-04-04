local yangming = fk.CreateSkill {
  name = "yangming"
}

Fk:loadTranslationTable{
  ['yangming'] = '养名',
  ['#yangming'] = '养名：与一名角色拼点，若其没赢，你可以继续与其拼点；若其赢，其摸拼点没赢次数的牌，你回复1点体力',
  ['#yangming-invoke'] = '养名：你可以继续发动“养名”与 %dest 拼点',
  [':yangming'] = '出牌阶段限一次，你可以与一名角色拼点：若其没赢，你可以与其重复此流程；若其赢，其摸等同于其本阶段拼点没赢次数的牌，你回复1点体力。',
}

yangming:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#yangming",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(yangming.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    while not (player.dead or target.dead) and player:canPindian(target) do
      local pindian = player:pindian({target}, yangming.name)
      if pindian.results[target.id].winner ~= target then
        if not player.dead and not target.dead and player:canPindian(target)
          and room:askToSkillInvoke(player, {skill_name = yangming.name, prompt = "#yangming-invoke::"..target.id}) then
          player:broadcastSkillInvoke(yangming.name)
          room:notifySkillInvoked(player, yangming.name)
          room:doIndicate(player.id, {target.id})
        else
          break
        end
      else
        if not target.dead then
          local n = #room.logic:getEventsOfScope(GameEvent.Pindian, 999, function (e)
            local dat = e.data[1]
            return dat.results[target.id] and dat.results[target.id].winner ~= target
          end, Player.HistoryPhase)
          if n > 0 then
            target:drawCards(n, yangming.name)
          end
        end
        if not player.dead and player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = yangming.name
          }
        end
        break
      end
    end
  end,
})

return yangming
