local js__yizheng = fk.CreateSkill {
  name = "js__yizheng"
}

Fk:loadTranslationTable{
  ['js__yizheng'] = '义争',
  ['#js__yizheng'] = '义争：你可以与一名手牌数大于你的角色拼点，若赢，其跳过下个摸牌阶段；没赢，其可以对你造成至多2点伤害',
  ['@@js__yizheng'] = '义争',
  ['#js__yizheng-damage'] = '义争：你可以对 %src 造成至多2点伤害',
  [':js__yizheng'] = '出牌阶段限一次，你可以与一名手牌数大于你的角色拼点：若你赢，其跳过下个摸牌阶段；没赢，其可以对你造成至多2点伤害。',
}

js__yizheng:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#js__yizheng",
  can_use = function(self, player)
    return player:usedSkillTimes(js__yizheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getHandcardNum() > player:getHandcardNum() and player:canPindian(target)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, js__yizheng.name)
    if pindian.results[target.id].winner == player then
      if not target.dead then
        room:setPlayerMark(target, "@@js__yizheng", 1)
      end
    else
      if player.dead or target.dead then return end
      local choice = room:askToChoice(target, {
        choices = {"0", "1", "2"},
        skill_name = js__yizheng.name,
        prompt = "#js__yizheng-damage:"..player.id,
      })
      if choice ~= "0" then
        room:doIndicate(target.id, {player.id})
        room:damage{
          from = target,
          to = player,
          damage = tonumber(choice),
          skillName = js__yizheng.name,
        }
      end
    end
  end,
})

js__yizheng:addEffect(fk.EventPhaseChanging, {
  mute = true,
  can_trigger = function(self, event, target, player)
    return player == target and target:getMark("@@js__yizheng") > 0 and event.to == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    player.room:setPlayerMark(player, "@@js__yizheng", 0)
    player:skip(Player.Draw)
    return true
  end,
})

return js__yizheng
