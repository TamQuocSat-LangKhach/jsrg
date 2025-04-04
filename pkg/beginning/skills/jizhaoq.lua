local jizhaoq = fk.CreateSkill {
  name = "jizhaoq"
}

Fk:loadTranslationTable{
  ['jizhaoq'] = '急召',
  ['#jizhaoq-choose'] = '急召：你可以指定一名角色，令其选择使用一张手牌或你移动其区域内一张牌',
  ['#jizhaoq-use'] = '急召：使用一张手牌，或点“取消” %src 可以移动你区域内一张牌',
  ['jizhaoq_hand'] = '移动手牌',
  ['jizhaoq_board'] = '移动场上牌',
  ['#jizhaoq-move'] = '急召：你可以选择一名角色，将 %dest 区域内的一张牌移至目标角色区域',
  [':jizhaoq'] = '准备阶段和结束阶段，你可以令一名角色选择一项：1.使用一张手牌；2.令你可以移动其区域里的一张牌。',
}

jizhaoq:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(jizhaoq.name) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() or table.find(room.alive_players, function(to)
        return p:canMoveCardsInBoardTo(to, nil)
      end)
    end), Util.IdMapper)

    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#jizhaoq-choose",
      skill_name = jizhaoq.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    local use = nil

    if not to:isKongcheng() then
      use = room:askToUseRealCard(to, {
        pattern = to:getCardIds("h"),
        skill_name = jizhaoq.name,
        prompt = "#jizhaoq-use:"..player.id,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        cancelable = true,
        skip = true,
      })
    end

    if use then
      room:useCard(use)
    else
      local choices = {}
      if not to:isKongcheng() then table.insert(choices, "jizhaoq_hand") end
      local targets = table.filter(room.alive_players, function(p) return to:canMoveCardsInBoardTo(p, nil) end)

      if #targets > 0 then table.insert(choices, "jizhaoq_board") end

      if #choices == 0 then return end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = jizhaoq.name,
      })

      if choice == "jizhaoq_hand" then targets = room:getOtherPlayers(to) end

      local t = room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#jizhaoq-move::"..to.id,
        skill_name = jizhaoq.name,
        cancelable = true,
      })

      if #t > 0 then
        if choice == "jizhaoq_hand" then
          local cid = room:askToChooseCard(player, {
            target = to,
            flag = "h",
            skill_name = jizhaoq.name,
          })
          room:moveCardTo(cid, Player.Hand, room:getPlayerById(t[1]), fk.ReasonJustMove, jizhaoq.name, nil, false, player.id)
        else
          room:askToMoveCardInBoard(player, {
            target_one = to,
            target_two = room:getPlayerById(t[1]),
            skill_name = jizhaoq.name,
            move_from = to,
            skip = true,
          })
        end
      end
    end
  end,
})

return jizhaoq
