local guiji = fk.CreateSkill {
  name = "guiji"
}

Fk:loadTranslationTable{
  ['guiji'] = '闺忌',
  ['#guiji-prompt'] = '闺忌：你可以与一名手牌数小于你的男性角色交换手牌',
  ['@@guiji'] = '闺忌',
  ['#guiji_delay'] = '闺忌',
  ['#guiji-invoke'] = '闺忌：是否与 %dest 交换手牌？',
  [':guiji'] = '每回合限一次，出牌阶段，你可以与一名手牌数小于你的男性角色交换手牌，然后其下个出牌阶段结束时，你可以与其交换手牌。',
  ['$guiji1'] = '孙家虎女，向来无所忌讳。',
  ['$guiji2'] = '厮杀半生，尚惧兵器邪？',
}

guiji:addEffect('active', {
  anim_type = "support",
  target_num = 1,
  prompt = "#guiji-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(guiji.name, Player.HistoryTurn) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return player.id ~= to_select and target:isMale() and #selected == 0 and target:getHandcardNum() < player:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    U.swapHandCards(room, player, player, to, guiji.name)
    local mark = to:getMark("@@guiji")
    if type(mark) ~= "table" then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(to, "@@guiji", mark)
  end,
})

guiji:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.dead or player.dead then return false end
    local mark = target:getMark("@@guiji")
    if type(mark) == "table" and table.contains(mark, player.id) and target.phase == Player.Play then
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = guiji.name, prompt = "#guiji-invoke::"..target.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, guiji.name)
    player:broadcastSkillInvoke(guiji.name)
    room:doIndicate(player.id, {target.id})
    U.swapHandCards(room, player, player, target, guiji.name)
    local mark = target:getMark("@@guiji")
    if type(mark) == "table" and table.removeOne(mark, player.id) then
      room:setPlayerMark(target, "@@guiji", #mark > 0 and mark or 0)
    end
  end,
})

guiji:addEffect(fk.EventPhaseChanging, {
  can_refresh = function(self, event, target, player, data)
    return player == target and target:getMark("@@guiji") ~= 0 and data.from == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@guiji", 0)
  end,
})

return guiji
