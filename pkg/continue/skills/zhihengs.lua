local zhihengs = fk.CreateSkill {
  name = "zhihengs"
}

Fk:loadTranslationTable{
  ['zhihengs'] = '猘横',
  [':zhihengs'] = '锁定技，当你使用牌对目标角色造成伤害时，若其本回合使用或打出牌响应过你使用的牌，此伤害+1。',
  ['$zhihengs1'] = '杀尽逆竖，何人还敢平视！',
  ['$zhihengs2'] = '畏罪而返，区区螳臂，我何惧之！',
}

zhihengs:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhihengs.name) and data.card and not data.chain then
      local room = player.room
      local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if useEvent then
        local dat = useEvent.data[1]
        if table.contains(TargetGroup:getRealTargets(dat.tos), data.to.id) then
          local events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            return use.responseToEvent and use.responseToEvent.from == player.id and use.from == data.to.id
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
            local response = e.data[1]
            return response.responseToEvent and response.responseToEvent.from == player.id and response.from == data.to.id
          end, Player.HistoryTurn)
          if #events > 0 then return true end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return zhihengs
