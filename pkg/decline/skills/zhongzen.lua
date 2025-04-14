local zhongzen = fk.CreateSkill {
  name = "zhongzen"
}

Fk:loadTranslationTable{
  ['zhongzen'] = '众谮',
  ['#zhongzhen'] = '众谮：请交给 %dest 一张手牌',
  ['@@zhongzen-phase'] = '众谮',
  ['#zhongzen_debuff'] = '众谮',
  [':zhongzen'] = '锁定技，弃牌阶段开始时，你令所有手牌数小于你的角色各交给你一张手牌。若如此做，此阶段结束时，若你本阶段弃置的♠牌数大于体力值，你弃置所有牌。',
}

-- 主技能效果
zhongzen:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(zhongzen.name) and
      player.phase == Player.Discard and
      player:getHandcardNum() > 1 and
      table.find(
        player.room.alive_players,
        function(p) return p:getHandcardNum() < player:getHandcardNum() and not p:isKongcheng() end
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      room:getAlivePlayers(),
      function(p) return p:getHandcardNum() < player:getHandcardNum() end
    )

    if #targets > 0 then
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))

      for _, p in ipairs(targets) do
        if player:isAlive() and p:getHandcardNum() > 0 and p:isAlive() then
          local ids = room:askToCards(p, {
            min_num = 1,
            max_num = 1,
            pattern = '.',
            prompt = '#zhongzhen::' .. player.id,
            skill_name = zhongzen.name,
          })
          room:obtainCard(player, ids, false, fk.ReasonGive, p.id, zhongzen.name)
        end
      end

      room:setPlayerMark(player, "@@zhongzen-phase", 1)
    end
  end,
})

-- 副技能效果
zhongzen:addEffect(fk.EventPhaseEnd, {
  name = "#zhongzen_debuff",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:getMark("@@zhongzen-phase") > 0 and not player:isNude()) then
      return false
    end

    local spadeDiscarded = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, info in ipairs(e.data) do
        if info.moveReason == fk.ReasonDiscard and info.proposer == player.id then
          table.insertTable(
            spadeDiscarded,
            table.map(
              table.filter(info.moveInfo, function(moveInfo) return Fk:getCardById(moveInfo.cardId).suit == Card.Spade end),
              function(moveInfo) return moveInfo.cardId end
            )
          )
        end
      end
      return false
    end, Player.HistoryPhase)

    return #spadeDiscarded > player.hp
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:throwAllCards("he")
  end,
})

return zhongzen
