local chaozheng = fk.CreateSkill {
  name = "chaozheng",
}

Fk:loadTranslationTable{
  ["chaozheng"] = "朝争",
  [":chaozheng"] = "准备阶段，你可以令所有其他角色议事，结果为：红色，意见为红色的角色各回复1点体力；黑色，意见为红色的角色各失去1点体力。"..
  "若所有角色意见相同，则议事结束后，你摸X张牌（X为此次议事的角色数）。",

  ["#chaozheng-invoke"] = "朝争：你可以令所有其他角色议事！",
}

local U = require "packages/utility/utility"

chaozheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaozheng.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chaozheng.name,
      prompt = "#chaozheng-invoke",
    }) then
      local tos = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    local discussion = U.Discussion(player, targets, chaozheng.name)
    if discussion.color == "red" then
      for _, p in ipairs(targets) do
        if p:isWounded() and not p.dead and discussion.results[p].opinion == "red" then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = chaozheng.name,
          }
        end
      end
    elseif discussion.color == "black" then
      for _, p in ipairs(targets) do
        if not p.dead and discussion.results[p].opinion == "red" then
          room:loseHp(p, 1, chaozheng.name)
        end
      end
    end
    if not player.dead and
      table.every(targets, function(p)
        return discussion.results[p].opinion == discussion.results[targets[1]].opinion
      end) then
      player:drawCards(#targets, chaozheng.name)
    end
  end,
})

return chaozheng
