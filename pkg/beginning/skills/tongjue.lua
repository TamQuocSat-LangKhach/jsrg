local tongjue = fk.CreateSkill {
  name = "tongjue$"
}

Fk:loadTranslationTable{
  ['#tongjue-invoke'] = '通绝：你可以将手牌分配其他群势力角色（每名角色至多1张）',
}

tongjue:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  prompt = "#tongjue-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(tongjue.name, Player.HistoryPhase) == 0 and not player:isKongcheng() and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local list = room:askToYiji(
      player,
      {
        cards = player:getCardIds(Player.Hand),
        targets = table.filter(room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end),
        skill_name = tongjue.name,
        min_num = 1,
        max_num = 999,
        prompt = "#tongjue-invoke",
        single_max = 1,
        skip = false
      }
    )
    if player.dead then return end
    local mark = player:getTableMark("tongjue-turn")
    for key, value in pairs(list) do
      if #value > 0 then
        table.insert(mark, key)
      end
    end
    room:setPlayerMark(player, "tongjue-turn", mark)
  end,
})

tongjue:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    if from and card then
      return table.contains(from:getTableMark("tongjue-turn"), to.id)
    end
  end,
})

return tongjue
