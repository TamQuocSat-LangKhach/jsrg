local shenchong = fk.CreateSkill {
  name = "shenchong"
}

Fk:loadTranslationTable{
  ['shenchong'] = '甚宠',
  ['#shenchong'] = '甚宠：令一名其他角色获得〖飞扬〗和〖跋扈〗！',
  [':shenchong'] = '限定技，出牌阶段，你可以令一名其他角色获得〖飞扬〗和〖跋扈〗，若如此做，当你死亡时，其失去所有技能，然后其弃置全部手牌。',
}

shenchong:addEffect('active', {
  name = "shenchong",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#shenchong",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(shenchong.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:handleAddLoseSkills(target, "m_feiyang|m_bahu", nil, true, false)
    room:setPlayerMark(player, shenchong.name, target.id)
  end,
})

shenchong:addEffect(fk.Death, {
  name = "#shenchong_trigger",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark(shenchong.name) ~= 0 and not player.room:getPlayerById(player:getMark(shenchong.name)).dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shenchong")
    room:notifySkillInvoked(player, "shenchong", "negative")
    local to = room:getPlayerById(player:getMark(shenchong.name))
    room:doIndicate(player.id, {to.id})
    local skills = table.map(table.filter(to.player_skills, function(skill)
      return skill:isPlayerSkill(to)
    end), function(s)
        return s.name
      end)
    room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    to:throwAllCards("h")
  end,
})

return shenchong
