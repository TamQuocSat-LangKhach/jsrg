local jizhan = fk.CreateSkill {
  name = "jizhan"
}

Fk:loadTranslationTable{
  ['jizhan'] = '吉占',
  ['jizhan_more'] = '下一张牌点数较大',
  ['jizhan_less'] = '下一张牌点数较小',
  ['#jizhan-choice'] = '吉占：猜测下一张牌的点数与上一张（%arg点）比大小',
  [':jizhan'] = '摸牌阶段，你可以改为展示牌堆顶的一张牌，猜测牌堆顶下一张牌点数大于或小于此牌，然后展示之，若猜对则继续猜测。最后你获得所有展示的牌。',
  ['$jizhan1'] = '得吉占之兆，延福运之气。',
  ['$jizhan2'] = '吉占逢时，化险为夷。',
}

jizhan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local get = room:getNCards(1)
    room:moveCardTo(get, Card.Processing, nil, fk.ReasonJustMove, jizhan.name, nil, true, player.id)
    while true do
      room:delay(500)
      local num1 = Fk:getCardById(get[#get]).number
      local choice = room:askToChoice(player, {
        choices = {"jizhan_more", "jizhan_less"},
        skill_name = jizhan.name,
        prompt = "#jizhan-choice:::"..tostring(num1)
      })
      local id = room:getNCards(1)[1]
      local num2 = Fk:getCardById(id).number
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, jizhan.name, nil, true, player.id)
      table.insert(get, id)
      if (choice == "jizhan_more" and num1 >= num2) or (choice == "jizhan_less" and num1 <= num2) then
        room:setCardEmotion(id, "judgebad")
        room:delay(600)
        break
      else
        room:setCardEmotion(id, "judgegood")
        room:delay(600)
      end
    end
    room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, jizhan.name, nil, true, player.id)
    return true
  end,
})

return jizhan
