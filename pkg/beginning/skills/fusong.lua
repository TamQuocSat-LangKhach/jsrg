local fusong = fk.CreateSkill {
  name = "fusong"
}

Fk:loadTranslationTable{
  ['fusong'] = '赋颂',
  ['fengzi'] = '丰姿',
  ['jizhan'] = '吉占',
  ['#fusong-choose'] = '赋颂：你可以令一名角色获得〖丰姿〗或〖吉占〗',
  ['#fusong-choice'] = '赋颂：选择你获得的技能',
  [':fusong'] = '当你死亡时，你可以令一名体力上限大于你的角色选择获得〖丰姿〗或〖吉占〗。',
  ['$fusong1'] = '陛下垂爱，妾身方有此位。',
  ['$fusong2'] = '长情颂，君王恩。',
}

fusong:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(fusong.name, false, true) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p.maxHp > player.maxHp and not (p:hasSkill("fengzi", true) and p:hasSkill("jizhan", true))
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p.maxHp > player.maxHp and not (p:hasSkill("fengzi", true) and p:hasSkill("jizhan", true))
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#fusong-choose",
      skill_name = fusong.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    local choices = {}
    for _, s in ipairs({"fengzi", "jizhan"}) do
      if not to:hasSkill(s, true) then
        table.insert(choices, s)
      end
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = fusong.name,
      prompt = "#fusong-choice"
    })
    room:handleAddLoseSkills(to, choice, nil, true, false)
  end,
})

return fusong
