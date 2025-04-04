local dangren = fk.CreateSkill {
  name = "dangren"
}

Fk:loadTranslationTable{
  ['dangren'] = '当仁',
  ['#dangren_trigger'] = '当仁',
  [':dangren'] = '转换技，阳：当你需要对你使用【桃】时，你可以视为使用之；阴：当你需要对其他角色使用【桃】时，你须视为使用之。',
}

dangren:addEffect('viewas', {
  anim_type = "support",
  pattern = "peach",
  switch_skill_name = "dangren",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("peach")
    c.skillName = skill.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getSwitchSkillState(skill.name) == fk.SwitchYang
  end,
  enabled_at_response = function(self, player, res)
    return
      not res and
      player:getSwitchSkillState(skill.name) == fk.SwitchYang and
      not table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p.dying end)
  end,
})

dangren:addEffect(fk.AskForCardUse, {
  anim_type = "support",
  switch_skill_name = "dangren",
  can_trigger = function(self, event, target, player, data)
    if
      not (
      target == player and
      player:hasSkill(dangren) and
      player:getSwitchSkillState(dangren.name) == fk.SwitchYin and 
      data.pattern
    )
    then
      return false
    end

    local matcherParsed = Exppattern:Parse(data.pattern)
    local peach = Fk:cloneCard("peach")
    return
      table.find(
        matcherParsed.matchers,
        function(matcher)
          return
            table.contains(matcher.name or {}, "peach") or
            table.contains(matcher.trueName or {}, "peach")
        end
      ) and
      matcherParsed:match(peach) and
      table.find(
        ((data.extraData or {}).must_targets or {}),
        function(p)
          return
            p ~= player.id and
            not (
            player:prohibitUse(peach) and
            player:isProhibited(player.room:getPlayerById(p), peach)
          )
        end
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local peach = Fk:cloneCard("peach")
    local others = table.filter(
      data.extraData.must_targets, 
      function(p)
        return
          p ~= player.id and
          not (
          player:prohibitUse(peach) and
          player:isProhibited(player.room:getPlayerById(p), peach)
        )
      end
    )

    if #others > 0 then
      room:sortPlayersByAction(others)
      local target_player = room:getPlayerById(others[1])
      data.result = {
        from = player.id,
        to = others[1],
        card = peach,
      }

      return true
    end
  end,
})

return dangren
