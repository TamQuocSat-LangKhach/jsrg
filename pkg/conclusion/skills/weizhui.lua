local weizhui = fk.CreateSkill {
  name = "weizhui",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["weizhui"] = "危坠",
  [":weizhui"] = "主公技，其他魏势力角色的结束阶段，其可以将一张黑色牌当【过河拆桥】对你使用。",

  ["#weizhui-use"] = "危坠：你可以将一张黑色牌当【过河拆桥】对 %src 使用",

  ["$weizhui1"] = "大魏高楼百尺，竟无一栋梁。",
  ["$weizhui2"] = "高飞入危云，簌簌兮如坠。",
}

weizhui:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player ~= target and player:hasSkill(weizhui.name) and target.phase == Player.Finish and not target.dead and
      target.kingdom == "wei" and not player:isAllNude() and not (target:isNude() and #target:getHandlyIds() == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(target, {
      skill_name = "weizhui_viewas",
      prompt = "#weizhui-use:"..player.id,
      cancelable = true,
      extra_data = {
        exclusive_targets = {player.id},
      },
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("dismantlement", event:getCostData(self).cards, target, player, weizhui.name, true)
  end,
})

return weizhui
