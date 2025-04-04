local jixiang = fk.CreateSkill {
  name = "jixiang"
}

Fk:loadTranslationTable{
  ['jixiang'] = '济乡',
  ['#jixiang-invoke'] = '济乡：你可以弃置一张牌，令%dest视为使用或打出所需的基本牌',
  ['#jixiang-name'] = '济乡：选择%dest视为使用或打出的所需的基本牌的牌名',
  ['#jixiang-target'] = '济乡：选择使用【%arg】的目标角色',
  ['#jixiang_delay'] = '济乡',
  [':jixiang'] = '当其他角色于你的回合内需要使用或打出基本牌时（每回合每种牌名各限一次），你可以弃置一张牌令其视为使用或打出之，然后你摸一张牌并令〖称贤〗于此阶段可发动次数+1。',
  ['$jixiang1'] = '珠玉不足贵，德行传家久。',
  ['$jixiang2'] = '人情一日不食则饥，愿母亲慎思之。',
}

jixiang:addEffect({fk.AskForCardUse, fk.AskForCardResponse}, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jixiang.name) and player.phase ~= Player.NotActive and player ~= target and data.pattern then
      local names = initializeAllCardNames(player, "jixiang_names")
      local mark = player:getMark("jixiang-turn")
      for _, name in ipairs(names) do
        local card = Fk:cloneCard(name)
        if (type(mark) ~= "table" or not table.contains(mark, card.trueName)) and Exppattern:Parse(data.pattern):match(card) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jixiang.name,
      cancelable = true,
      pattern = ".",
      prompt = "#jixiang-invoke::" .. target.id
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), jixiang.name, player, player)
    local names = initializeAllCardNames(player, "jixiang_names")
    local names2 = {}
    local mark = player:getMark("jixiang-turn")
    for _, name in ipairs(names) do
      local card = Fk:cloneCard(name)
      if (type(mark) ~= "table" or not table.contains(mark, card.trueName)) and Exppattern:Parse(data.pattern):match(card) then
        table.insertIfNeed(names2, name)
      end
    end
    if #names2 == 0 then return false end
    if event == fk.AskForCardUse then
      local extra_data = data.extraData
      local isAvailableTarget = function(card, p)
        if extra_data then
          if type(extra_data.must_targets) == "table" and #extra_data.must_targets > 0 and
            not table.contains(extra_data.must_targets, p.id) then
            return false
          end
          if type(extra_data.exclusive_targets) == "table" and #extra_data.exclusive_targets > 0 and
            not table.contains(extra_data.exclusive_targets, p.id) then
            return false
          end
        end
        return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target, card, true)
      end
      local findCardTarget = function(card)
        local tos = {}
        for _, p in ipairs(room.alive_players) do
          if isAvailableTarget(card, p) then
            table.insert(tos, p.id)
          end
        end
        return tos
      end
      names2 = table.filter(names2, function (c_name)
        local card = Fk:cloneCard(c_name)
        return not target:prohibitUse(card) and (card.skill:getMinTargetNum() == 0 or #findCardTarget(card) > 0)
      end)
      if #names2 == 0 then return false end
      local name = room:askToChoice(player, {
        choices = names2,
        skill_name = jixiang.name,
        prompt = "#jixiang-name::" .. target.id,
        detailed = false,
        all_choices = names
      })
      local card = Fk:cloneCard(name)
      card.skillName = jixiang.name
      data.result = {
        from = target.id,
        card = card,
      }
      if card.skill:getMinTargetNum() == 1 then
        local tos = findCardTarget(card)
        if #tos > 0 then
          data.result.tos = {room:askToChoosePlayers(target, {
            targets = tos,
            min_num = 1,
            max_num = 1,
            prompt = "#jixiang-target:::" .. name,
            skill_name = jixiang.name,
            cancelable = false,
            no_indicate = true
          })}
        else
          return false
        end
      end
      if data.eventData then
        data.result.toCard = data.eventData.toCard
        data.result.responseToEvent = data.eventData.responseToEvent
      end
      local mark = player:getMark("jixiang-turn")
      if type(mark) ~= "table" then mark = {} end
      table.insert(mark, card.trueName)
      room:setPlayerMark(player, "jixiang-turn", mark)
      return true
    else
      names2 = table.filter(names2, function (c_name)
        return not target:prohibitResponse(Fk:cloneCard(c_name))
      end)
      if #names2 == 0 then return false end
      local name = room:askToChoice(player, {
        choices = names2,
        skill_name = jixiang.name,
        prompt = "#jixiang-name::" .. target.id,
        detailed = false,
        all_choices = names
      })
      local card = Fk:cloneCard(name)
      card.skillName = jixiang.name
      data.result = card
      local mark = player:getMark("jixiang-turn")
      if type(mark) ~= "table" then mark = {} end
      table.insert(mark, card.trueName)
      room:setPlayerMark(player, "jixiang-turn", mark)
      return true
    end
  end
})

jixiang:addEffect({fk.CardUseFinished, fk.CardRespondFinished}, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player.phase ~= Player.NotActive and table.contains(data.card.skillNames, jixiang.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jixiang.name)
    player.room:addPlayerMark(player, "chengxian_extratimes-phase")
  end
})

return jixiang
