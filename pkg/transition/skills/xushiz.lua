local xushiz = fk.CreateSkill {
  name = "xushiz"
}

Fk:loadTranslationTable{
  ['xushiz'] = '虚势',
  ['#xushiz-invoke'] = '虚势：交给任意名角色各一张牌，获得两倍数量的【影】',
  [':xushiz'] = '出牌阶段限一次，你可以交给任意名角色各一张牌，然后你获得两倍数量的【影】。',
}

xushiz:addEffect('active', {
  anim_type = "offensive",
  prompt = "#xushiz-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(xushiz.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  card_num = 0,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local list = room:askToYiji(player, {
      cards = player:getCardIds("he"),
      targets = room:getOtherPlayers(player, false),
      skill_name = xushiz.name,
      min_num = 1,
      max_num = 999,
      prompt = "#xushiz-invoke",
      single_max = 1
    })
    if player.dead then return end
    local x = 0
    for _, value in pairs(list) do
      if #value > 0 then
        x = x + 2
      end
    end
    room:moveCards({
      ids = getShade(room, x),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = player.id,
      skillName = xushiz.name,
      moveVisible = true,
    })
  end,
})

return xushiz
