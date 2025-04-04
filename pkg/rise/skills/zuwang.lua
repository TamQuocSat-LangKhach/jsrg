local zuwang = fk.CreateSkill {
  name = "zuwang"
}

Fk:loadTranslationTable{
  ['zuwang'] = '族望',
  [':zuwang'] = '锁定技，准备阶段和结束阶段，你将手牌摸至体力上限。',
}

zuwang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zuwang.name) and
      (player.phase == Player.Start or player.phase == Player.Finish) and
      player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player)
    player:drawCards(player.maxHp - player:getHandcardNum(), zuwang.name)
  end,
})

return zuwang
