local js__zunwei = fk.CreateSkill {
  name = "js__zunwei"
}

Fk:loadTranslationTable{
  ['js__zunwei'] = '尊位',
  ['#js__zunwei-active'] = '发动 尊位，选择一名其他角色并执行一项效果',
  ['js__zunwei_choice1'] = '1.将手牌补至与其手牌数相同（至多摸五张）；</font>',
  ['js__zunwei_choice2'] = '2.将其装备里的牌移至你的装备区，直到你装备区里的牌数不小于其装备区里的牌数；</font>',
  ['js__zunwei_choice3'] = '3.将体力值回复至与其相同</font>',
  ['js__zunwei_color'] = '<font color=>',
  ['js__zunwei1'] = '将手牌摸至与其相同（最多摸五张）',
  ['js__zunwei2'] = '移动其装备至你的装备区直到比你少',
  ['js__zunwei3'] = '回复体力至与其相同',
  [':js__zunwei'] = '出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一个选项，然后移除该选项：1.将手牌补至与其手牌数相同（至多摸五张）；2.将其装备里的牌移至你的装备区，直到你装备区里的牌数不小于其装备区里的牌数；3.将体力值回复至与其相同。',
  ['$js__zunwei1'] = '妾蒲柳之姿，幸蒙君恩方化从龙之凤。',
  ['$js__zunwei2'] = '尊位椒房、垂立九五，君之恩也、妾之幸也。',
}

js__zunwei:addEffect('active', {
  anim_type = "control",
  prompt = "#js__zunwei-active",
  dynamic_desc = function(self, player)
    local texts = {"js__zunwei_inner", "", "js__zunwei_choice1", "", "js__zunwei_choice2", "", "js__zunwei_choice3"}
    local x = 0
    for i = 1, 3, 1 do
      if player:getMark(skill.name .. tostring(i)) > 0 then
        texts[2 * i] = "js__zunwei_color"
        x = x + 1
      end
    end
    return (x == 3) and "dummyskill" or table.concat(texts, ":")
  end,
  card_num = 0,
  target_num = 1,
  interaction = function()
    local choices, all_choices = {}, {}
    for i = 1, 3 do
      local choice = "js__zunwei"..tostring(i)
      table.insert(all_choices, choice)
      if player:getMark(choice) == 0 then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(skill.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return skill.interaction.data and #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = skill.interaction.data
    if choice == "js__zunwei1" then
      local x = math.min(target:getHandcardNum() - player:getHandcardNum(), 5)
      if x > 0 then
        room:drawCards(player, x, js__zunwei.name)
      end
    elseif choice == "js__zunwei2" then
      while not (player.dead or target.dead) and
        #player.player_cards[Player.Equip] <= #target.player_cards[Player.Equip] and
        target:canMoveCardsInBoardTo(player, "e") do
        room:askToMoveCardInBoard(player, {
          target_one = target,
          target_two = player,
          skill_name = js__zunwei.name,
          flag = "e",
          move_from = target
        })
      end
    elseif choice == "js__zunwei3" and player:isWounded() then
      local x = target.hp - player.hp
      if x > 0 then
        room:recover{
          who = player,
          num = math.min(player:getLostHp(), x),
          recoverBy = player,
          skillName = js__zunwei.name}
      end
    end
    room:setPlayerMark(player, choice, 1)
  end,

  on_lose = function(self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "js__zunwei1", 0)
    room:setPlayerMark(player, "js__zunwei2", 0)
    room:setPlayerMark(player, "js__zunwei3", 0)
  end,
})

return js__zunwei
