local yingshi = fk.CreateSkill {
  name = "js__yingshi"
}

Fk:loadTranslationTable{
  ['js__yingshi'] = '鹰视',
  [':js__yingshi'] = '当你翻面后，你可以观看牌堆底的三张牌（若场上阵亡角色数大于2则改为五张），然后将其中任意牌以任意顺序放置牌堆顶，其余牌以任意顺序放置牌堆底。',
  ['$js__yingshi1'] = '亮志大而不见机，已堕吾画中。',
  ['$js__yingshi2'] = '贼偏执一端不能察变，破之必矣。',
}

yingshi:addEffect(fk.TurnedOver, {
  anim_type = "control",
  on_use = function(self, event, target, player)
    local room = player.room
    local n = #table.filter(room.players, function(p) return p.dead end)
    local num = 3
    if n > 2 then 
      num = 5 
    end
    local cards = room:getNCards(num, "bottom")
    local ret = room:askToArrangeCards(player, {
      skill_name = skill.name,
      card_map = {{}, cards, "Top", "Bottom"},
      prompt = "",
      box_size = true,
      free_arrange = 0,
      max_limit = {num, num},
      min_limit = {0, 0}
    })
    local top, bottom = ret[1], ret[2]
    for i = #top, 1, -1 do
      table.removeOne(room.draw_pile, top[i])
      table.insert(room.draw_pile, 1, top[i])
    end
    for i = 1, #bottom, 1 do
      table.removeOne(room.draw_pile, bottom[i])
      table.insert(room.draw_pile, bottom[i])
    end
    room:sendLog{
      type = "#GuanxingResult",
      from = player.id,
      arg = #top,
      arg2 = #bottom,
    }
  end,
})

return yingshi
