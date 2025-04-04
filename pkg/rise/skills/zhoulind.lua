local zhoulind = fk.CreateSkill {
  name = "zhoulind"
}

Fk:loadTranslationTable{
  ['zhoulind'] = '骤临',
  [':zhoulind'] = '当你使用【杀】对一名角色造成伤害时，若本回合开始时其不在你的攻击范围内，此伤害+1。',
}

zhoulind:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhoulind.name) and data.card and data.card.trueName == "slash" and
      table.contains(player:getTableMark("zhoulind-turn"), data.to.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  can_refresh = Util.TrueFunc,
  on_refresh = function (skill, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, p in ipairs(room.alive_players) do
      if not player:inMyAttackRange(p) then
        table.insert(mark, p.id)
      end
    end
    room:setPlayerMark(player, "zhoulind-turn", mark)
  end,
})

return zhoulind
  ```

