-- 修正批量医生姓名：避免同一科室医生同姓
-- 仅更新 seed_large_demo_data.sql 生成的 doctor_bulk_001 ~ doctor_bulk_050

USE `medical_health`;

UPDATE `sys_user` u
JOIN `doctor_info` d ON d.user_id = u.id
SET
  u.nickname = CONCAT(
    CASE MOD((d.id - 8300) * 7, 12)
      WHEN 0 THEN '周' WHEN 1 THEN '林' WHEN 2 THEN '陈' WHEN 3 THEN '王'
      WHEN 4 THEN '赵' WHEN 5 THEN '李' WHEN 6 THEN '韩' WHEN 7 THEN '吴'
      WHEN 8 THEN '徐' WHEN 9 THEN '沈' WHEN 10 THEN '郑' ELSE '高'
    END,
    CASE MOD((d.id - 8300) * 3 + FLOOR((d.id - 8300) / 10), 10)
      WHEN 0 THEN '明远' WHEN 1 THEN '雅宁' WHEN 2 THEN '亦舟' WHEN 3 THEN '清越'
      WHEN 4 THEN '安和' WHEN 5 THEN '景行' WHEN 6 THEN '知夏' WHEN 7 THEN '若尘'
      WHEN 8 THEN '书禾' ELSE '予安'
    END
  ),
  d.real_name = CONCAT(
    CASE MOD((d.id - 8300) * 7, 12)
      WHEN 0 THEN '周' WHEN 1 THEN '林' WHEN 2 THEN '陈' WHEN 3 THEN '王'
      WHEN 4 THEN '赵' WHEN 5 THEN '李' WHEN 6 THEN '韩' WHEN 7 THEN '吴'
      WHEN 8 THEN '徐' WHEN 9 THEN '沈' WHEN 10 THEN '郑' ELSE '高'
    END,
    CASE MOD((d.id - 8300) * 3 + FLOOR((d.id - 8300) / 10), 10)
      WHEN 0 THEN '明远' WHEN 1 THEN '雅宁' WHEN 2 THEN '亦舟' WHEN 3 THEN '清越'
      WHEN 4 THEN '安和' WHEN 5 THEN '景行' WHEN 6 THEN '知夏' WHEN 7 THEN '若尘'
      WHEN 8 THEN '书禾' ELSE '予安'
    END
  ),
  u.update_time = NOW(),
  d.update_time = NOW()
WHERE d.id BETWEEN 8301 AND 8350
  AND u.username LIKE 'doctor_bulk_%';
