local jueyin = fk.CreateSkill {
  name = "jueyin"
}

Fk:loadTranslationTable{
  ['jueyin'] = '绝禋',
  ['@jueyin_debuff-turn'] = '绝禋+',
  ['#jueyin_debuff'] = '绝禋',
  [':jueyin'] = '当你每回合首次受到伤害后，你可以摸三张牌，然后本回合所有角色受到的伤害+1。',
}

jueyin:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if not (target == player and player:hasSkill(jueyin.name)) then
      return false
    end

    local room = player.room
    local record_id = player:getMark("jueyin_damage-turn")
    if record_id == 0 then
      room.logic:getActualDamageEvents(1, function(e)
        if e.data[1].to == player then
          record_id = e.id
          room:setPlayerMark(player, "jueyin_damage-turn", record_id)
          return true
        end
      end)
    end
    return room.logic:getCurrentEvent().id == record_id
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(3, jueyin.name)
    for _, p in ipairs(room.alive_players) do
      room:addPlayerMark(p, "@jueyin_debuff-turn")
    end
  end,
})

jueyin:addEffect(fk.DamageInflicted, {
  name = "#jueyin_debuff",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@jueyin_debuff-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return jueyin
