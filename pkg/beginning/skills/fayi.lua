local fayi = fk.CreateSkill {
  name = "fayi"
}

Fk:loadTranslationTable{
  ['fayi'] = '伐异',
  ['#fayi-choose'] = '伐异：你可以对一名意见与你不同的角色造成1点伤害',
  [':fayi'] = '当你参与议事结束后，你可以对一名意见与你不同的角色造成1点伤害。',
}

fayi:addEffect("fk.DiscussionFinished", {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fayi) and data.results[player.id] and
      table.find(data.tos, function(p)
        return not p.dead and data.results[p.id] and data.results[player.id].opinion ~= data.results[p.id].opinion
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(data.tos, function(p)
      return not p.dead and data.results[p.id] and data.results[player.id].opinion ~= data.results[p.id].opinion
    end)
    local to = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#fayi-choose",
      skill_name = fayi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(cost_data.tos[1]),
      damage = 1,
      skillName = fayi.name,
    }
  end,
})

return fayi
