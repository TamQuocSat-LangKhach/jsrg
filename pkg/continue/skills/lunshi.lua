local lunshi = fk.CreateSkill {
  name = "lunshi"
}

Fk:loadTranslationTable{
  ['lunshi'] = '论势',
  ['#lunshi'] = '论势：令一名角色摸其攻击范围内角色数牌，然后其弃置攻击范围内含有其角色数牌',
  [':lunshi'] = '出牌阶段限一次，你可以令一名角色摸等同于其攻击范围内角色数的牌（至多摸至五张），然后令该角色弃置等同于攻击范围内含有其的角色数的牌。',
}

lunshi:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#lunshi",
  can_use = function(self, player)
    return player:usedSkillTimes(lunshi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = #table.filter(room.alive_players, function(p) return target:inMyAttackRange(p) end)
    if n > 0 and target:getHandcardNum() < 5 then
      target:drawCards(math.min(n, 5 - target:getHandcardNum()), lunshi.name)
    end
    if target.dead then return end
    n = #table.filter(room.alive_players, function(p) return p:inMyAttackRange(target) end)
    if n > 0 then
      room:askToDiscard(target, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = lunshi.name,
        cancelable = false,
      })
    end
  end,
})

return lunshi
