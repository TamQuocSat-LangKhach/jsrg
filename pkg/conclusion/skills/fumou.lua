local fumou = fk.CreateSkill {
  name = "js__fumou"
}

Fk:loadTranslationTable{
  ['js__fumou'] = '复谋',
  ['@js__fumouDebuff-turn'] = '复谋',
  ['#js__fumou_viewas'] = '复谋',
  ['#js__fumou-use'] = '复谋：你可将一张【影】当【出其不意】对其中一名角色使用',
  [':js__fumou'] = '魏势力技，当你参与的议事结束后，所有与你意见不同的角色本回合内不能使用或打出其意见颜色的牌，然后你可将一张【影】当【出其不意】对其中一名角色使用。',
}

fumou:addEffect("fk.DiscussionFinished", {
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(fumou.name) and data.results[player.id]) then
      return false
    end

    for playerId, result in pairs(data.results) do
      if player.room:getPlayerById(playerId):isAlive() and result.opinion ~= data.results[player.id].opinion then
        return true
      end
    end

    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local diffResults = {}
    local diffPlayerIds = {}
    for playerId, result in pairs(data.results) do
      if player.room:getPlayerById(playerId):isAlive() and result.opinion ~= data.results[player.id].opinion then
        diffResults[playerId] = result
        table.insert(diffPlayerIds, playerId)
      end
    end

    room:doIndicate(player.id, diffPlayerIds)

    for playerId, result in pairs(diffResults) do
      if result.opinion ~= "nocolor" then
        local to = room:getPlayerById(playerId)
        room:addTableMark(to, "@js__fumouDebuff-turn", result.opinion)
      end
    end

    room:setPlayerMark(player, "js__fumou_targets", diffPlayerIds)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "#js__fumou_viewas",
      prompt = "#js__fumou-use",
      cancelable = true,
    })
    room:setPlayerMark(player, "js__fumou_targets", 0)
    if success then
      local card = Fk.skills["#js__fumou_viewas"]:viewAs(dat.cards)
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
    end
  end,
})

fumou:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("@js__fumouDebuff-turn"), card:getColorString())
  end,
  prohibit_response = function(self, player, card)
    return card and table.contains(player:getTableMark("@js__fumouDebuff-turn"), card:getColorString())
  end,
  is_prohibited = function(self, from, to, card)
    return card and table.contains(card.skillNames, "js__fumou_tag") and not table.contains(from:getTableMark("js__fumou_targets"), to.id)
  end,
})

return fumou
