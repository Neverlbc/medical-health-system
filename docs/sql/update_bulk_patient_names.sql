-- 修正批量患者姓名：去掉姓名后面的数字
-- 仅更新 seed_large_demo_data.sql 生成的 patient_bulk_001 ~ patient_bulk_100

USE `medical_health`;

UPDATE `sys_user` u
JOIN `patient_info` p ON p.user_id = u.id
SET
  u.nickname = CONCAT(
    CASE MOD((p.id - 8400) * 7, 24)
      WHEN 0 THEN '许' WHEN 1 THEN '赵' WHEN 2 THEN '顾' WHEN 3 THEN '孙'
      WHEN 4 THEN '沈' WHEN 5 THEN '程' WHEN 6 THEN '林' WHEN 7 THEN '周'
      WHEN 8 THEN '陈' WHEN 9 THEN '吴' WHEN 10 THEN '韩' WHEN 11 THEN '王'
      WHEN 12 THEN '郑' WHEN 13 THEN '高' WHEN 14 THEN '唐' WHEN 15 THEN '何'
      WHEN 16 THEN '宋' WHEN 17 THEN '梁' WHEN 18 THEN '罗' WHEN 19 THEN '谢'
      WHEN 20 THEN '马' WHEN 21 THEN '郭' WHEN 22 THEN '胡' ELSE '叶'
    END,
    CASE MOD((p.id - 8400) * 11 + FLOOR((p.id - 8400) / 24), 20)
      WHEN 0 THEN '安然' WHEN 1 THEN '一诺' WHEN 2 THEN '清和' WHEN 3 THEN '桂兰'
      WHEN 4 THEN '星河' WHEN 5 THEN '小满' WHEN 6 THEN '知予' WHEN 7 THEN '明轩'
      WHEN 8 THEN '若溪' WHEN 9 THEN '景行' WHEN 10 THEN '舒然' WHEN 11 THEN '以宁'
      WHEN 12 THEN '子衿' WHEN 13 THEN '云澈' WHEN 14 THEN '嘉禾' WHEN 15 THEN '南星'
      WHEN 16 THEN '予初' WHEN 17 THEN '若安' WHEN 18 THEN '怀瑾' ELSE '书遥'
    END
  ),
  p.real_name = CONCAT(
    CASE MOD((p.id - 8400) * 7, 24)
      WHEN 0 THEN '许' WHEN 1 THEN '赵' WHEN 2 THEN '顾' WHEN 3 THEN '孙'
      WHEN 4 THEN '沈' WHEN 5 THEN '程' WHEN 6 THEN '林' WHEN 7 THEN '周'
      WHEN 8 THEN '陈' WHEN 9 THEN '吴' WHEN 10 THEN '韩' WHEN 11 THEN '王'
      WHEN 12 THEN '郑' WHEN 13 THEN '高' WHEN 14 THEN '唐' WHEN 15 THEN '何'
      WHEN 16 THEN '宋' WHEN 17 THEN '梁' WHEN 18 THEN '罗' WHEN 19 THEN '谢'
      WHEN 20 THEN '马' WHEN 21 THEN '郭' WHEN 22 THEN '胡' ELSE '叶'
    END,
    CASE MOD((p.id - 8400) * 11 + FLOOR((p.id - 8400) / 24), 20)
      WHEN 0 THEN '安然' WHEN 1 THEN '一诺' WHEN 2 THEN '清和' WHEN 3 THEN '桂兰'
      WHEN 4 THEN '星河' WHEN 5 THEN '小满' WHEN 6 THEN '知予' WHEN 7 THEN '明轩'
      WHEN 8 THEN '若溪' WHEN 9 THEN '景行' WHEN 10 THEN '舒然' WHEN 11 THEN '以宁'
      WHEN 12 THEN '子衿' WHEN 13 THEN '云澈' WHEN 14 THEN '嘉禾' WHEN 15 THEN '南星'
      WHEN 16 THEN '予初' WHEN 17 THEN '若安' WHEN 18 THEN '怀瑾' ELSE '书遥'
    END
  ),
  u.update_time = NOW(),
  p.update_time = NOW()
WHERE p.id BETWEEN 8401 AND 8500
  AND u.username LIKE 'patient_bulk_%';
