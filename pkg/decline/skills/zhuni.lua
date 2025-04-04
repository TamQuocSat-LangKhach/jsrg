local zhuni = fk.CreateSkill {
  name = "zhuni"
}

Fk:loadTranslationTable{
  ['zhuni'] = '诛逆',
  ['#zhuni'] = '诛逆：你可令所有角色同时选择角色，你对唯一指定次数最多的角色使用牌无距离次数限制',
  ['#zhuni-choose'] = '诛逆：请选择其中一名角色，若你选择角色为被选择次数唯一最多的角色，%src 对其使用牌无距离次数限制',
  ['hezhi'] = '合志',
  ['#ShowPlayerChosen'] = '%from 选择了 %to',
  ['#ChangeZhuNiChosen'] = '%from 选择的角色被改为了 %to',
  ['@@zhuniOnwers-turn'] = '被诛逆',
  [':zhuni'] = '出牌阶段限一次，你可以令所有角色同时选择一名除你外的角色，你本回合对此次被指定次数唯一最多的角色使用牌无距离次数限制。',
}

zhuni:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#zhuni",
  can_use = function(self, player)
    local alivePlayers = Fk:currentRoom().alive_players
    return player:usedSkillTimes(zhuni.name, Player.HistoryPhase) == 0 and not (#alivePlayers == 1 and alivePlayers[1] == player.id)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    for _, p in ipairs(room.alive_players) do
      room:askToChoosePlayers(p, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhuni-choose:"..player.id,
        skill_name = zhuni.name,
        cancelable = false,
      })
    end

    local yourTarget
    if player:hasSkill("hezhi") then
      local result = room:getRequestResult(player)
      if type(result) == "table" then
        yourTarget = result.targets[1]
      else
        yourTarget = table.random(targets)
      end
    end

    print(room:getPlayerById(yourTarget).general)

    local targetsMap = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      local to
      local result = room:getRequestResult(p)
      if type(result) == "table" then
        to = result.targets[1]
      else
        to = table.random(targets).id
      end
      room:sendLog{
        type = "#ShowPlayerChosen",
        from = p.id,
        to = { to },
        toast = true,
      }
      room:doIndicate(p.id, { to })
      room:delay(500)

      if yourTarget and p.kingdom == "qun" and p ~= player and yourTarget ~= to then
        to = yourTarget
        player:broadcastSkillInvoke("hezhi")
        room:notifySkillInvoked(player, "hezhi", "control")
        room:sendLog{
          type = "#ChangeZhuNiChosen",
          from = p.id,
          to = { to },
          toast = true,
        }
      end
      targetsMap[to] = (targetsMap[to] or 0) + 1
    end

    local maxTarget, maxNum = nil, 0
    for pId, num in pairs(targetsMap) do
      if num > maxNum then
        maxNum = num
        maxTarget = pId
      elseif num == maxNum and maxTarget then
        maxTarget = nil
      end
    end

    if maxTarget then
      local maxPlayer = room:getPlayerById(maxTarget)
      local zhuniOwners = maxPlayer:getTableMark(("@@zhuniOnwers-turn"))
      table.insertIfNeed(zhuniOwners, player.id)
      room:setPlayerMark(maxPlayer, "@@zhuniOnwers-turn", zhuniOwners)
    end
  end,
})

zhuni:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    if card and to then
      return table.contains(to:getTableMark("@@zhuniOnwers-turn"), player.id)
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    if card and to then
      return table.contains(to:getTableMark("@@zhuniOnwers-turn"), player.id)
    end
  end,
})

return zhuni
