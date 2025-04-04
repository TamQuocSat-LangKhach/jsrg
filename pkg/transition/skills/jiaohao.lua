local jiaohao = fk.CreateSkill {
  name = "jiaohao"
}

Fk:loadTranslationTable{
  ['jiaohao'] = '骄豪',
  ['jiaohao&'] = '骄豪',
  [':jiaohao'] = '其他角色出牌阶段限一次，其可以将手牌中的一张装备牌置于你的装备区中；准备阶段，你获得X张【影】（X为你空置的装备栏数的一半且向上取整）。',
  ['$jiaohao1'] = '桃花马、请长缨，将军何必是丈夫。',
  ['$jiaohao2'] = '本夫人处事，何须犬马置喙？',
}

jiaohao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  attached_skill_name = "jiaohao&",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(jiaohao.name) and player.phase == Player.Start then
      return #player:getCardIds("e") < #player:getAvailableEquipSlots()
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local num = (#player:getAvailableEquipSlots() - #player:getCardIds("e") + 1) // 2
    room:moveCards({
      ids = getShade(room, num),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = player.id,
      skill_name = jiaohao.name,
      moveVisible = true,
    })
  end
})

return jiaohao
