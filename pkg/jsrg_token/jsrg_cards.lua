

local premeditate = fk.CreateDelayedTrickCard{
  name = "&premeditate",
}
extension:addCard(premeditate)
Fk:loadTranslationTable{
  ["premeditate"] = "蓄谋",
  [":premeditate"] = "这张牌视为延时锦囊<br/><b>效果：</b>判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌：1.使用此牌，"..
  "然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。",
}
