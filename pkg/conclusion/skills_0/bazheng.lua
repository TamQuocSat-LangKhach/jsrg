local bazheng = fk.CreateSkill {
  name = "bazheng"
}

Fk:loadTranslationTable{
  ['bazheng'] = '霸政',
  ['#LogChangeOpinion'] = '%to 的意见被视为 %arg',
  [':bazheng'] = '锁定技，当你参与的议事展示意见后，参与议事角色中本回合受到过你造成伤害的角色意见改为与你相同。',
}

bazheng:addEffect("fk.DiscussionCardsDisplayed", {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(bazheng.name) and data.results[player.id] and
      #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        return damage.from and damage.from == player and damage.to ~= player and damage.to:isAlive() and data.results[damage.to.id]
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local targets = {}
    player.room.logic:getActualDamageEvents(999, function(event)
      local damageData = event.data[1]
      local victimId = damageData.to.id
      if damageData.from == player and damageData.to ~= player and damageData.to:isAlive() and data.results[victimId] then
        data.results[victimId].opinion = data.results[player.id].opinion
        table.insert(targets, victimId)
      end
    end, Player.HistoryTurn)
    room:doIndicate(player.id, targets)

    room:sendLog{
      type = "#LogChangeOpinion",
      to = targets,
      arg = data.results[player.id].opinion,
      toast = true,
    }
  end,
})

return bazheng
