local yangge = fk.CreateSkill {
  name = "yangge"
}

Fk:loadTranslationTable{
  ['yangge'] = '扬戈',
  ['yangge&'] = '扬戈',
  [':yangge'] = '每轮限一次，体力值最低的其他角色可以于其出牌阶段对你发动〖密诏〗。',
}

yangge:addEffect("PhaseStart", {
  attached_skill_name = "yangge&",
  can_trigger = function(self, event, player, data)
    return player:getPhase() == .phasePlay
  end,
  on_refresh = function(self, event, player, data)
    local minHpPlayer = nil
    local minHp = 999
    for _, p in sgs.PlayerListIterator(player:getRoom():getOtherPlayers(player)) do
      if p:isAlive() and p:getHp() < minHp then
        minHp = p:getHp()
        minHpPlayer = p
      end
    end
    return minHpPlayer
  end,
})

return yangge
