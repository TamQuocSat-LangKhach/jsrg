local daoren = fk.CreateSkill {
  name = "daoren"
}

Fk:loadTranslationTable{
  ['daoren'] = '蹈刃',
  ['#daoren'] = '蹈刃：你可交给一名角色手牌，你对你与其攻击范围内均包含的所有角色各造成1点伤害',
  [':daoren'] = '出牌阶段限一次，你可以交给一名角色一张手牌，然后你对你与其攻击范围内均包含的所有角色各造成1点伤害。',
}

daoren:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#daoren",
  can_use = function(self, player)
    local alivePlayers = Fk:currentRoom().alive_players
    return player:usedSkillTimes(daoren.name, Player.HistoryPhase) == 0 and not (#alivePlayers == 1 and alivePlayers[1] == player.id)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:obtainCard(to, effect.cards, false, fk.ReasonGive, player.id, daoren.name)

    local sameTargets = table.filter(room:getAlivePlayers(), function(p) return player:inMyAttackRange(p) and to:inMyAttackRange(p) end)
    if #sameTargets then
      for _, p in ipairs(sameTargets) do
        room:damage{
          from = player,
          to = p,
          num = 1,
          skill_name = daoren.name,
        }
      end
    end
  end,
})

return daoren
