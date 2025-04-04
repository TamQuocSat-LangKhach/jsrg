local zhuiming = fk.CreateSkill {
  name = "zhuiming"
}

Fk:loadTranslationTable{
  ['zhuiming'] = '追命',
  ['#zhuiming-invoke'] = '追命：你可以对 %dest 发动“追命”声明一种颜色',
  ['#zhuiming'] = '%from 声明 %arg',
  ['#zhuiming-discard'] = '追命：%src 声明%arg，你可以弃置任意张牌',
  [':zhuiming'] = '当你使用【杀】指定唯一目标后，你可以声明一种颜色并令目标弃置任意张牌，然后你展示目标一张牌，若此牌颜色与你声明的颜色相同，则此【杀】不计入次数限制、不可被响应且伤害+1。',
}

zhuiming:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiming.name) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and
      not player.room:getPlayerById(AimGroup:getAllTargets(data.tos)[1]):isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"red", "black", "Cancel"},
      skill_name = zhuiming.name,
      prompt = "#zhuiming-invoke::"..AimGroup:getAllTargets(data.tos)[1]
    })
    event:setCostData(self, choice)
    return choice ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
    room:doIndicate(player.id, {to.id})
    room:sendLog{
      type = "#zhuiming",
      from = player.id,
      arg = event:getCostData(self),
      toast = true,
    }
    room:askToDiscard(to, {
      min_num = 0,
      max_num = 999,
      include_equip = true,
      skill_name = zhuiming.name,
      cancelable = true,
      prompt = "#zhuiming-discard:"..player.id.."::"..event:getCostData(self),
      no_indicate = false
    })
    if player.dead or to.dead or to:isNude() then return end
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = zhuiming.name
    })
    to:showCards({id})
    if Fk:getCardById(id):getColorString() == event:getCostData(self) then
      player:addCardUseHistory("slash", -1)
      data.disresponsiveList = data.disresponsiveList or {}
      table.insert(data.disresponsiveList, to.id)
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return zhuiming
