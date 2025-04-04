local fushan = fk.CreateSkill {
  name = "fushan"
}

Fk:loadTranslationTable{
  ['fushan'] = '负山',
  ['@fushan-phase'] = '负山',
  ['#fushan-give'] = '负山：是否交给 %src 一张牌令其本阶段使用【杀】次数上限+1？',
  [':fushan'] = '出牌阶段开始时，所有其他角色依次可以交给你一张牌并令你本阶段使用【杀】的次数上限+1；此阶段结束时，若你使用【杀】的次数未达上限且本阶段以此法交给你牌的角色均存活，你失去2点体力，否则你将手牌摸至体力上限。',
}

fushan:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(skill.name) and player.phase == Player.Play then
      return not table.every(player.room:getOtherPlayers(player, false), function(p) return p:isNude() end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(fushan.name)
    room:notifySkillInvoked(player, fushan.name, "special")
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
    if #targets == 0 then return end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local mark = {}
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead and not p:isNude() then
        local cards = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = fushan.name,
          cancelable = true,
          prompt = "#fushan-give:"..player.id
        })
        if #cards > 0 then
          room:moveCardTo(Fk:getCardById(cards[1]), Card.PlayerHand, player, fk.ReasonGive, fushan.name, nil, false, p.id)
          room:addPlayerMark(player, "@fushan-phase", 1)
          table.insert(mark, p.id)
        end
      end
    end
    if #mark > 0 then
      room:setPlayerMark(player, "fushan-phase", mark)
    end
  end,
})

fushan:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(skill.name) and player.phase == Player.Play then
      if player:getMark("@fushan-phase") == 0 then return end
      local card = Fk:cloneCard("slash")
      local skill = card.skill
      local n = skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)
      if not n or player:usedCardTimes("slash", Player.HistoryPhase) < n then
        return table.every(player:getMark("fushan-phase"), function(id) return not room:getPlayerById(id).dead end)
      else
        return player:getHandcardNum() < player.maxHp
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(fushan.name)
    local card = Fk:cloneCard("slash")
    local skill = card.skill
    local n = skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)
    if not n or player:usedCardTimes("slash", Player.HistoryPhase) < n then
      if table.every(player:getMark("fushan-phase"), function(id) return not room:getPlayerById(id).dead end) then
        room:notifySkillInvoked(player, fushan.name, "negative")
        room:loseHp(player, 2, fushan.name)
        return
      end
    end
    room:notifySkillInvoked(player, fushan.name, "drawcard")
    player:drawCards(player.maxHp - player:getHandcardNum(), fushan.name)
  end,
})

fushan:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@fushan-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@fushan-phase")
    end
  end,
})

return fushan
