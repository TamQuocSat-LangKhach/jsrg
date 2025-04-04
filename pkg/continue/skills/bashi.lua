local bashi = fk.CreateSkill {
  name = "bashi$"
}

Fk:loadTranslationTable{
  ['#bashi-invoke'] = '霸世：你可令其他吴势力角色替你打出【杀】或【闪】',
  ['#bashi-choice'] = '霸世：选择你想打出的牌，令其他吴势力角色替你打出之',
  ['#bashi-ask'] = '霸世：你可打出一张【%arg】，视为 %src 打出之',
}

bashi:addEffect(fk.AskForCardResponse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bashi.name) and
      table.find(Fk:currentRoom().alive_players, function(p) return p.kingdom == "wu" and p ~= player end) and
      ((data.cardName and (data.cardName == "slash" or data.cardName == "jink")) or
      (data.pattern and Exppattern:Parse(data.pattern):matchExp("slash,jink")))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = bashi.name,
      prompt = "#bashi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for _, name in ipairs({"slash", "jink"}) do
      local card = Fk:cloneCard(name)
      if data.pattern then
        if Exppattern:Parse(data.pattern):match(card) then
          table.insert(choices, name)
        end
      elseif data.cardName and data.cardName == name then
        table.insert(choices, name)
      end
    end
    local name = room:askToChoice(player, {
      choices = choices,
      skill_name = bashi.name,
      prompt = "#bashi-choice",
    })
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "wu" and p:isAlive() then
        local cardResponded = room:askToResponse(p, {
          pattern = name,
          skill_name = bashi.name,
          prompt = "#bashi-ask:"..player.id.."::"..name,
          cancelable = true,
        })
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })
          data.result = cardResponded
          data.result.skillName = bashi.name
          return true
        end
      end
    end
  end,
})

return bashi
