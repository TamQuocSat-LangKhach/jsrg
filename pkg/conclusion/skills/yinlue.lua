local yinlue = fk.CreateSkill {
  name = "yinlue"
}

Fk:loadTranslationTable{
  ['yinlue'] = '隐略',
  ['#yinlue-ask'] = '隐略：你可以防止 %dest 受到的 %arg 伤害，回合结束执行仅有 %arg2 的回合',
  [':yinlue'] = '每轮每项各限一次，当一名角色受到火焰/雷电伤害时，你可以防止此伤害，然后若此时在一名角色的回合内，\\\n  你于此回合结束后执行一个仅有摸牌/弃牌阶段的额外回合。',
}

yinlue:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local availableDMGTypes = {fk.ThunderDamage, fk.FireDamage}
    return
      player:hasSkill(yinlue.name) and
      table.contains(availableDMGTypes, data.damageType) and
      player:getMark("yinlueUsed" .. data.damageType .. "-round") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local damageTypeTable = {
      [fk.FireDamage] = "fire_damage",
      [fk.ThunderDamage] = "thunder_damage",
    }
    local phase =  data.damageType == fk.FireDamage and "phase_draw" or "phase_discard"

    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = yinlue.name,
        prompt = "#yinlue-ask::" .. data.to.id .. ":" .. damageTypeTable[data.damageType] .. ":" .. phase
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yinlueUsed".. data.damageType.. "-round", 1)
    if room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) then
      local phase = data.damageType == fk.FireDamage and Player.Draw or Player.Discard
      player:gainAnExtraTurn(true, yinlue.name, { phase_table = { phase } })
    end
    return true
  end,
})

return yinlue
