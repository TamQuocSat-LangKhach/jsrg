local qinrao = fk.CreateSkill {
  name = "qinrao"
}

Fk:loadTranslationTable{
  ['qinrao'] = '侵扰',
  ['qinrao_viewas'] = '侵扰',
  ['#qinrao-use'] = '侵扰：你可以将一张牌当【决斗】对 %dest 使用',
  [':qinrao'] = '其他角色出牌阶段开始时，你可以将一张牌当【决斗】对其使用，若其手牌中有可以打出的【杀】，其必须打出响应，否则其展示所有手牌。',
}

qinrao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(qinrao) and target.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "qinrao_viewas",
      prompt = "#qinrao-use::" .. target.id,
      cancelable = true,
      extra_data = { must_targets = {target.id} }
    })
    if success then
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("duel", event:getCostData(self).cards, player, target, qinrao.name)
  end,
})

qinrao:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return data.from == player.id and data.card.trueName == "duel" and table.contains(data.card.skillNames, "qinrao")
  end,
  on_refresh = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = qinraoDuelSkill
    data.card = card
  end,
})

return qinrao
