local chaozheng = fk.CreateSkill {
  name = "chaozheng"
}

Fk:loadTranslationTable{
  ['chaozheng'] = '朝争',
  ['#chaozheng-invoke'] = '朝争：你可以令所有其他角色议事！',
  [':chaozheng'] = '准备阶段，你可以令所有其他角色议事，结果为：红色，意见为红色的角色各回复1点体力；黑色，意见为红色的角色各失去1点体力。若所有角色意见相同，则议事结束后，你摸X张牌（X为此次议事的角色数）。',
}

chaozheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(chaozheng.name) and player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player, false), function(p) return p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = chaozheng.name,
      prompt = "#chaozheng-invoke"
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isKongcheng() end)
    if #targets == 0 then return end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local discussion = U.Discussion(player, targets, chaozheng.name)
    if discussion.color == "red" then
      for _, p in ipairs(targets) do
        if p:isWounded() and not p.dead and discussion.results[p.id].opinion == "red" then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = chaozheng.name,
          })
        end
      end
    elseif discussion.color == "black" then
      for _, p in ipairs(targets) do
        if not p.dead and discussion.results[p.id].opinion == "red" then
          room:loseHp(p, 1, chaozheng.name)
        end
      end
    end
    if not player.dead and table.every(targets, function(p)
      return discussion.results[p.id].opinion == discussion.results[targets[1].id].opinion end) then
      player:drawCards(#targets, chaozheng.name)
    end
  end,
})

return chaozheng
