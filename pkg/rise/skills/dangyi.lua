local dangyi = fk.CreateSkill {
  name = "dangyi"
}

Fk:loadTranslationTable{
  ['dangyi'] = '荡异',
  ['@dangyi'] = '荡异',
  ['#dangyi-invoke'] = '荡异：是否令你对 %dest 造成的伤害+1？（还剩%arg次！）',
  [':dangyi'] = '主公技，当你造成伤害时，你可以令此伤害值+1，本局游戏限X次（X为你获得此技能时已损失体力值+1）。',
}

dangyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangyi.name) and player:getMark("@dangyi") > 0
  end,
  on_cost = function (skill, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = dangyi.name,
      prompt = "#dangyi-invoke::"..data.to.id..":"..player:getMark("@dangyi")
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@dangyi", 1)
    data.damage = data.damage + 1
  end,
})

dangyi.on_acquire = function (self, player, is_start)
  player.room:addPlayerMark(player, "@dangyi", player:getLostHp() + 1)
end

dangyi.on_lose = function (self, player, is_death)
  player.room:setPlayerMark(player, "@dangyi", 0)
end

return dangyi
