local eqian = fk.CreateSkill {
  name = "eqian"
}

Fk:loadTranslationTable{
  ['eqian'] = '遏前',
  ['#eqian-put'] = '遏前：你可以“蓄谋”任意次，将一张手牌作为“蓄谋”牌扣置于判定区',
  ['#eqian-invoke'] = '遏前：你可以令此%arg不计次数，并获得目标一张牌',
  ['#eqian-prey'] = '遏前：获得 %dest 一张牌',
  ['#eqian-distance'] = '遏前：是否令 %src 本回合与你距离+2？',
  ['@eqian-turn'] = '遏前',
  [':eqian'] = '结束阶段，你可以“蓄谋”任意次；当你使用【杀】或“蓄谋”牌指定其他角色为唯一目标后，你可以令此牌不计入次数限制且获得目标一张牌，然后目标可以令你本回合计算与其的距离+2。<br/><font color=>#<b>蓄谋</b>：将一张手牌扣置于判定区，判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌：1.使用此牌，然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。',
}

eqian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(eqian) then
      return player.phase == Player.Finish and not player:isKongcheng() and not table.contains(player.sealedSlots, Player.JudgeSlot)
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = eqian.name,
      cancelable = true,
      prompt = "#eqian-put",
    })
    if #cards > 0 then
      event:setCostData(self, cards[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    premeditate(player, event:getCostData(self), eqian.name, player.id)
    while not player:isKongcheng() and not player.dead and not table.contains(player.sealedSlots, Player.JudgeSlot) do
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = eqian.name,
        cancelable = true,
        prompt = "#eqian-put",
      })
      if #cards > 0 then
        premeditate(player, cards[1], eqian.name, player.id)
      else
        return
      end
    end
  end,
})

eqian:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(eqian) then
      return (data.card.trueName == "slash" or (data.extra_data and data.extra_data.premeditate)) and
        #AimGroup:getAllTargets(data.tos) == 1 and data.to ~= player.id
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = eqian.name,
      prompt = "#eqian-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extraUse = true
    player:addCardUseHistory(data.card.trueName, -1)
    local to = room:getPlayerById(data.to)
    if not to.dead and not to:isNude() then
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = eqian.name,
        prompt = "#eqian-prey::"..to.id,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, eqian.name, "", false, player.id)
      if not to.dead and room:askToSkillInvoke(to, {
        skill_name = eqian.name,
        prompt = "#eqian-distance:"..player.id
      }) then
        room:addPlayerMark(to, "@eqian-turn", 2)
      end
    end
  end,
})

eqian:addEffect("distance", {
  correct_func = function(self, from, to)
    if from.phase ~= Player.NotActive then
      return to:getMark("@eqian-turn")
    end
    return 0
  end,
})

return eqian
