local longlin = fk.CreateSkill {
  name = "longlin"
}

Fk:loadTranslationTable{
  ['longlin'] = '龙临',
  ['#longlin-invoke'] = '龙临:是否弃置一张牌，令%dest 使用的%arg 无效，然后其可以视为对你使用一张【决斗】 ',
  ['#longlin-duel'] = '龙临:是否对%dest 视为使用一张【决斗】',
  ['@@longlin-phase'] = '龙临 禁用手牌',
  [':longlin'] = '当其他角色于其出牌阶段内首次使用【杀】指定目标后，你可以弃置一张牌令此【杀】无效，然后其可以视为对你使用一张【决斗】，你以此法造成伤害后，其本阶段不能再使用手牌。',
}

longlin:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if
      player:hasSkill(longlin) and
      target ~= player and
      target.phase == Player.Play and
      data.card.trueName == "slash" and
      data.firstTarget and
      not player:isNude()
    then
      local room = player.room
      local logic = room.logic

      local mark = player:getMark("longlin_record-phase")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.card.trueName == "slash" and use.from == target.id then
            mark = e.id
            room:setPlayerMark(player, "longlin_record-phase", mark)
            return true
          end
          return false
        end, Player.HistoryPhase)
      end

      return mark == logic:getCurrentEvent().id
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = longlin.name,
      cancelable = true,
      prompt = "#longlin-invoke::"..data.from..":"..data.card:toLogString(),
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    room:throwCard(event:getCostData(self), longlin.name, player, player)
    data.nullifiedTargets = table.map(room.players, Util.IdMapper)
    if not target:isProhibited(player, Fk:cloneCard("duel")) and room:askToSkillInvoke(from, {
      skill_name = longlin.name,
      prompt = "#longlin-duel::"..player.id
    }) then
      room:useVirtualCard("duel", nil, target, player, longlin.name, true)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(longlin, true) and data.card and data.card.trueName == "duel" and data.to ~= player and not data.to.dead and table.contains(data.card.skillNames, longlin.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(data.to, "@@longlin-phase", 1)
  end,
})

local longlin_prohibit = fk.CreateSkill{
  name = "#longlin_prohibit",
}

longlin_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    if player:getMark("@@longlin-phase") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
})

return longlin
