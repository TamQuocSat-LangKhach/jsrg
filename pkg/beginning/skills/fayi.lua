local fayi = fk.CreateSkill {
  name = "fayi",
}

Fk:loadTranslationTable{
  ["fayi"] = "伐异",
  [":fayi"] = "当你参与议事结束后，你可以对一名意见与你不同的角色造成1点伤害。",

  ["#fayi-choose"] = "伐异：你可以对一名意见与你不同的角色造成1点伤害",
}

local U = require "packages/utility/utility"

fayi:addEffect(U.DiscussionFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fayi.name) and data.results[player] and
      table.find(data.tos, function(p)
        return not p.dead and data.results[p] and data.results[player].opinion ~= data.results[p].opinion
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function(p)
      return not p.dead and data.results[p] and data.results[player].opinion ~= data.results[p].opinion
    end)
    local to = room:askToChoosePlayers(player, {
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
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = fayi.name,
    }
  end,
})

return fayi
