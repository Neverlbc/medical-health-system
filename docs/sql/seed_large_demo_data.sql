-- 大批量演示数据：50 个医生、100 个患者、患者健康数据、排班与预约
-- 账号密码：全部为 test123
-- 医生账号：doctor_bulk_001 ~ doctor_bulk_050
-- 患者账号：patient_bulk_001 ~ patient_bulk_100

USE `medical_health`;

DELIMITER $$

DROP PROCEDURE IF EXISTS seed_large_demo_data $$
CREATE PROCEDURE seed_large_demo_data()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE doctor_id BIGINT;
  DECLARE doctor_user_id BIGINT;
  DECLARE patient_id BIGINT;
  DECLARE patient_user_id BIGINT;
  DECLARE current_doctor_id BIGINT;
  DECLARE department_name VARCHAR(50);
  DECLARE title_name VARCHAR(50);
  DECLARE patient_name VARCHAR(50);
  DECLARE gender_value TINYINT;
  DECLARE status_value TINYINT;
  DECLARE bp_sys INT;
  DECLARE bp_dia INT;
  DECLARE sugar DECIMAL(5,2);

  -- 清理本脚本数据，保证可重复执行
  DELETE FROM `appointment` WHERE `patient_id` BETWEEN 8401 AND 8500 OR `doctor_id` BETWEEN 8301 AND 8350;
  DELETE FROM `doctor_schedule` WHERE `doctor_id` BETWEEN 8301 AND 8350;
  DELETE FROM `health_data` WHERE `patient_id` BETWEEN 8401 AND 8500;
  DELETE FROM `diagnosis_record` WHERE `patient_id` BETWEEN 8401 AND 8500 OR `doctor_id` BETWEEN 8301 AND 8350;
  DELETE FROM `patient_history` WHERE `patient_id` BETWEEN 8401 AND 8500;
  DELETE FROM `patient_allergy` WHERE `patient_id` BETWEEN 8401 AND 8500;
  DELETE FROM `patient_record` WHERE `user_id` BETWEEN 8401 AND 8500;
  DELETE FROM `doctor_info` WHERE `id` BETWEEN 8301 AND 8350 OR `user_id` BETWEEN 8301 AND 8350;
  DELETE FROM `patient_info` WHERE `id` BETWEEN 8401 AND 8500 OR `user_id` BETWEEN 8401 AND 8500;
  DELETE FROM `sys_user` WHERE `id` BETWEEN 8301 AND 8350 OR `id` BETWEEN 8401 AND 8500;

  -- 50 个医生
  SET i = 1;
  WHILE i <= 50 DO
    SET doctor_id = 8300 + i;
    SET doctor_user_id = 8300 + i;
    SET department_name = CASE MOD(i, 10)
      WHEN 0 THEN '心内科'
      WHEN 1 THEN '内分泌科'
      WHEN 2 THEN '呼吸内科'
      WHEN 3 THEN '消化内科'
      WHEN 4 THEN '儿科'
      WHEN 5 THEN '骨科'
      WHEN 6 THEN '康复医学科'
      WHEN 7 THEN '妇产科'
      WHEN 8 THEN '皮肤科'
      ELSE '全科医学科'
    END;
    SET title_name = CASE MOD(i, 4)
      WHEN 0 THEN '主任医师'
      WHEN 1 THEN '副主任医师'
      WHEN 2 THEN '主治医师'
      ELSE '医师'
    END;

    INSERT INTO `sys_user` (`id`, `username`, `password`, `nickname`, `phone`, `email`, `avatar`, `role`, `status`, `create_time`, `update_time`, `last_login_time`, `deleted`)
    VALUES (
      doctor_user_id,
      CONCAT('doctor_bulk_', LPAD(i, 3, '0')),
      '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6',
      CONCAT(CASE MOD(i * 7, 12) WHEN 0 THEN '周' WHEN 1 THEN '林' WHEN 2 THEN '陈' WHEN 3 THEN '王' WHEN 4 THEN '赵' WHEN 5 THEN '李' WHEN 6 THEN '韩' WHEN 7 THEN '吴' WHEN 8 THEN '徐' WHEN 9 THEN '沈' WHEN 10 THEN '郑' ELSE '高' END,
             CASE MOD(i * 3 + FLOOR(i / 10), 10) WHEN 0 THEN '明远' WHEN 1 THEN '雅宁' WHEN 2 THEN '亦舟' WHEN 3 THEN '清越' WHEN 4 THEN '安和' WHEN 5 THEN '景行' WHEN 6 THEN '知夏' WHEN 7 THEN '若尘' WHEN 8 THEN '书禾' ELSE '予安' END),
      CONCAT('138', LPAD(81000 + i, 8, '0')),
      CONCAT('doctor_bulk_', LPAD(i, 3, '0'), '@test.com'),
      NULL,
      'DOCTOR',
      1,
      NOW(),
      NOW(),
      NULL,
      0
    );

    INSERT INTO `doctor_info` (`id`, `user_id`, `real_name`, `gender`, `department`, `title`, `specialty`, `introduction`, `certificate_no`, `work_years`, `consultation_fee`, `rating`, `patient_count`, `status`, `create_time`, `update_time`)
    VALUES (
      doctor_id,
      doctor_user_id,
      (SELECT `nickname` FROM `sys_user` WHERE `id` = doctor_user_id),
      MOD(i, 2),
      department_name,
      title_name,
      CASE department_name
        WHEN '心内科' THEN '高血压、冠心病、心律失常'
        WHEN '内分泌科' THEN '糖尿病、甲状腺疾病、代谢综合征'
        WHEN '呼吸内科' THEN '慢性咳嗽、哮喘、慢阻肺'
        WHEN '消化内科' THEN '胃炎、消化不良、肝胆疾病'
        WHEN '儿科' THEN '儿童发热、咳嗽、过敏性鼻炎'
        WHEN '骨科' THEN '关节疼痛、骨折、运动损伤'
        WHEN '康复医学科' THEN '术后康复、颈肩腰腿痛、运动处方'
        WHEN '妇产科' THEN '孕期管理、妇科炎症、产后康复'
        WHEN '皮肤科' THEN '湿疹、荨麻疹、痤疮'
        ELSE '常见病、慢病管理、健康咨询'
      END,
      CONCAT('从事', department_name, '临床工作', 5 + MOD(i, 26), '年，擅长常见病与慢病连续管理，适合演示预约、接诊与云小医医生提醒。'),
      CONCAT('DOC-BULK-', doctor_id),
      5 + MOD(i, 26),
      10.00,
      4.50 + (MOD(i, 45) / 100),
      80 + i * 7,
      1,
      NOW(),
      NOW()
    );

    -- 每名医生最近 7 天排班，部分满号/停诊用于管理端风险展示
    INSERT INTO `doctor_schedule` (`doctor_id`, `schedule_date`, `time_period`, `max_patients`, `booked_patients`, `status`, `create_time`, `update_time`)
    VALUES
      (doctor_id, CURDATE(), '上午', 20, MOD(i, 6), 1, NOW(), NOW()),
      (doctor_id, CURDATE(), '下午', 20, MOD(i + 2, 8), IF(MOD(i, 17) = 0, 0, 1), NOW(), NOW()),
      (doctor_id, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '上午', 20, MOD(i + 3, 10), 1, NOW(), NOW()),
      (doctor_id, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '下午', 20, IF(MOD(i, 13) = 0, 20, MOD(i + 4, 12)), 1, NOW(), NOW()),
      (doctor_id, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '上午', 20, MOD(i + 5, 9), 1, NOW(), NOW()),
      (doctor_id, DATE_ADD(CURDATE(), INTERVAL 5 DAY), '下午', 20, MOD(i + 1, 7), 1, NOW(), NOW());

    SET i = i + 1;
  END WHILE;

  -- 100 个患者
  SET i = 1;
  WHILE i <= 100 DO
    SET patient_id = 8400 + i;
    SET patient_user_id = 8400 + i;
    SET current_doctor_id = 8301 + MOD(i, 50);
    SET gender_value = MOD(i, 2);
    SET patient_name = CONCAT(CASE MOD(i * 7, 24)
      WHEN 0 THEN '许' WHEN 1 THEN '赵' WHEN 2 THEN '顾' WHEN 3 THEN '孙'
      WHEN 4 THEN '沈' WHEN 5 THEN '程' WHEN 6 THEN '林' WHEN 7 THEN '周'
      WHEN 8 THEN '陈' WHEN 9 THEN '吴' WHEN 10 THEN '韩' WHEN 11 THEN '王'
      WHEN 12 THEN '郑' WHEN 13 THEN '高' WHEN 14 THEN '唐' WHEN 15 THEN '何'
      WHEN 16 THEN '宋' WHEN 17 THEN '梁' WHEN 18 THEN '罗' WHEN 19 THEN '谢'
      WHEN 20 THEN '马' WHEN 21 THEN '郭' WHEN 22 THEN '胡' ELSE '叶' END,
      CASE MOD(i * 11 + FLOOR(i / 24), 20)
        WHEN 0 THEN '安然' WHEN 1 THEN '一诺' WHEN 2 THEN '清和' WHEN 3 THEN '桂兰'
        WHEN 4 THEN '星河' WHEN 5 THEN '小满' WHEN 6 THEN '知予' WHEN 7 THEN '明轩'
        WHEN 8 THEN '若溪' WHEN 9 THEN '景行' WHEN 10 THEN '舒然' WHEN 11 THEN '以宁'
        WHEN 12 THEN '子衿' WHEN 13 THEN '云澈' WHEN 14 THEN '嘉禾' WHEN 15 THEN '南星'
        WHEN 16 THEN '予初' WHEN 17 THEN '若安' WHEN 18 THEN '怀瑾' ELSE '书遥' END);
    SET bp_sys = 112 + MOD(i * 7, 62);
    SET bp_dia = 70 + MOD(i * 5, 38);
    SET sugar = 4.80 + (MOD(i * 11, 62) / 10);
    SET status_value = CASE
      WHEN bp_sys >= 160 OR sugar >= 10.0 THEN 4
      WHEN bp_sys >= 145 OR sugar >= 8.5 THEN 3
      WHEN bp_sys >= 135 OR sugar >= 7.0 THEN 2
      WHEN bp_sys >= 128 OR sugar >= 6.1 THEN 1
      ELSE 0
    END;

    INSERT INTO `sys_user` (`id`, `username`, `password`, `nickname`, `phone`, `email`, `avatar`, `role`, `status`, `create_time`, `update_time`, `last_login_time`, `deleted`)
    VALUES (
      patient_user_id,
      CONCAT('patient_bulk_', LPAD(i, 3, '0')),
      '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6',
      patient_name,
      CONCAT('139', LPAD(82000 + i, 8, '0')),
      CONCAT('patient_bulk_', LPAD(i, 3, '0'), '@test.com'),
      NULL,
      'PATIENT',
      1,
      NOW(),
      NOW(),
      NULL,
      0
    );

    INSERT INTO `patient_info` (`id`, `user_id`, `real_name`, `gender`, `birthday`, `age`, `id_card`, `address`, `emergency_contact`, `emergency_phone`, `height`, `weight`, `blood_type`, `allergies`, `family_history`, `medical_history`, `create_time`, `update_time`)
    VALUES (
      patient_id,
      patient_user_id,
      patient_name,
      gender_value,
      DATE_SUB(CURDATE(), INTERVAL (22 + MOD(i, 52)) YEAR),
      22 + MOD(i, 52),
      CONCAT('110101', DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL (22 + MOD(i, 52)) YEAR), '%Y%m%d'), LPAD(i, 4, '0')),
      CONCAT('北京市演示区健康管理街道', i, '号'),
      CONCAT('联系人', i),
      CONCAT('139', LPAD(83000 + i, 8, '0')),
      150 + MOD(i * 3, 38),
      45 + MOD(i * 4, 48),
      CASE MOD(i, 4) WHEN 0 THEN 'A' WHEN 1 THEN 'B' WHEN 2 THEN 'O' ELSE 'AB' END,
      CASE MOD(i, 8) WHEN 0 THEN '青霉素过敏' WHEN 1 THEN '花粉过敏' WHEN 2 THEN '无' WHEN 3 THEN '芒果过敏' ELSE '无明确药物过敏' END,
      CASE MOD(i, 5) WHEN 0 THEN '父亲高血压' WHEN 1 THEN '母亲2型糖尿病' WHEN 2 THEN '无明显家族史' WHEN 3 THEN '母亲冠心病' ELSE '父亲脑卒中史' END,
      CASE MOD(i, 6) WHEN 0 THEN '原发性高血压' WHEN 1 THEN '2型糖尿病' WHEN 2 THEN '无重大疾病史' WHEN 3 THEN '过敏性鼻炎' WHEN 4 THEN '骨关节疼痛' ELSE '胃炎' END,
      NOW(),
      NOW()
    );

    INSERT INTO `patient_record` (`user_id`, `allergies`, `family_history`, `medical_history`, `medication_history`, `remark`, `create_time`, `update_time`, `deleted`)
    VALUES (
      patient_user_id,
      CASE MOD(i, 8) WHEN 0 THEN '青霉素过敏' WHEN 1 THEN '花粉过敏' WHEN 3 THEN '芒果过敏' ELSE '无' END,
      CASE MOD(i, 5) WHEN 0 THEN '父亲高血压' WHEN 1 THEN '母亲2型糖尿病' ELSE '无特殊家族史' END,
      CASE MOD(i, 6) WHEN 0 THEN '原发性高血压' WHEN 1 THEN '2型糖尿病' WHEN 3 THEN '过敏性鼻炎' ELSE '无重大疾病史' END,
      CASE MOD(i, 6) WHEN 0 THEN '氨氯地平 5mg qd' WHEN 1 THEN '二甲双胍 0.5g bid' WHEN 3 THEN '氯雷他定按需' ELSE '无长期用药' END,
      '批量演示患者，用于首页、健康档案、云小医提醒和医生接诊测试。',
      NOW(),
      NOW(),
      0
    );

    IF MOD(i, 8) IN (0, 1, 3) THEN
      INSERT INTO `patient_allergy` (`patient_id`, `allergen`, `allergy_type`, `reaction`, `severity`, `record_date`, `create_time`)
      VALUES (
        patient_id,
        CASE MOD(i, 8) WHEN 0 THEN '青霉素' WHEN 1 THEN '花粉' ELSE '芒果' END,
        CASE MOD(i, 8) WHEN 0 THEN 'DRUG' WHEN 1 THEN 'ENV' ELSE 'FOOD' END,
        CASE MOD(i, 8) WHEN 0 THEN '皮疹、瘙痒' WHEN 1 THEN '鼻塞、流涕' ELSE '口唇肿胀' END,
        CASE MOD(i, 8) WHEN 0 THEN 'MODERATE' ELSE 'MILD' END,
        DATE_SUB(CURDATE(), INTERVAL (300 + i) DAY),
        NOW()
      );
    END IF;

    INSERT INTO `patient_history` (`patient_id`, `history_type`, `disease_name`, `diagnosis_date`, `relationship`, `description`, `status`, `create_time`, `update_time`)
    VALUES
      (patient_id, 'PAST', CASE MOD(i, 6) WHEN 0 THEN '原发性高血压' WHEN 1 THEN '2型糖尿病' WHEN 2 THEN '无重大疾病史' WHEN 3 THEN '过敏性鼻炎' WHEN 4 THEN '骨关节疼痛' ELSE '胃炎' END, DATE_SUB(CURDATE(), INTERVAL (200 + i) DAY), NULL, '批量生成既往史，用于健康档案摘要展示。', 1, NOW(), NOW()),
      (patient_id, 'FAMILY', CASE MOD(i, 5) WHEN 0 THEN '高血压' WHEN 1 THEN '2型糖尿病' WHEN 2 THEN '无明显家族史' WHEN 3 THEN '冠心病' ELSE '脑卒中' END, NULL, CASE MOD(i, 2) WHEN 0 THEN '父亲' ELSE '母亲' END, '批量生成家族史，用于搜索和摘要兜底。', 1, NOW(), NOW());

    INSERT INTO `diagnosis_record` (`patient_id`, `diagnosis_type`, `disease_name`, `icd10_code`, `diagnosis_date`, `doctor_id`, `description`, `create_time`)
    VALUES (
      patient_id,
      IF(MOD(i, 3) = 0, 'PRELIMINARY', 'CONFIRMED'),
      CASE MOD(i, 6) WHEN 0 THEN '原发性高血压' WHEN 1 THEN '2型糖尿病' WHEN 2 THEN '健康咨询' WHEN 3 THEN '过敏性鼻炎' WHEN 4 THEN '膝关节疼痛' ELSE '慢性胃炎' END,
      CASE MOD(i, 6) WHEN 0 THEN 'I10.x00' WHEN 1 THEN 'E11.900' ELSE '' END,
      DATE_SUB(CURDATE(), INTERVAL MOD(i, 30) DAY),
      current_doctor_id,
      '批量生成诊断记录，用于医生端患者风险和健康档案摘要展示。',
      NOW()
    );

    -- 每人 5 条健康数据
    INSERT INTO `health_data` (`patient_id`, `data_type`, `systolic_pressure`, `diastolic_pressure`, `blood_sugar`, `heart_rate`, `temperature`, `weight`, `remark`, `measure_time`, `status`, `create_time`)
    VALUES
      (patient_id, 'BLOOD_PRESSURE', bp_sys - 8, bp_dia - 5, NULL, 72 + MOD(i, 18), NULL, NULL, '7日前血压记录', DATE_SUB(NOW(), INTERVAL 7 DAY), IF(bp_sys - 8 >= 145, 3, IF(bp_sys - 8 >= 135, 2, IF(bp_sys - 8 >= 128, 1, 0))), NOW()),
      (patient_id, 'BLOOD_PRESSURE', bp_sys, bp_dia, NULL, 76 + MOD(i, 20), NULL, NULL, '最新血压记录', DATE_SUB(NOW(), INTERVAL MOD(i, 24) HOUR), status_value, NOW()),
      (patient_id, 'BLOOD_SUGAR', NULL, NULL, sugar, NULL, NULL, NULL, '最新血糖记录', DATE_SUB(NOW(), INTERVAL MOD(i + 3, 30) HOUR), CASE WHEN sugar >= 10.0 THEN 4 WHEN sugar >= 8.5 THEN 3 WHEN sugar >= 7.0 THEN 2 WHEN sugar >= 6.1 THEN 1 ELSE 0 END, NOW()),
      (patient_id, 'HEART_RATE', NULL, NULL, NULL, 65 + MOD(i * 3, 42), NULL, NULL, '心率记录', DATE_SUB(NOW(), INTERVAL MOD(i + 5, 36) HOUR), IF(65 + MOD(i * 3, 42) > 100, 2, 0), NOW()),
      (patient_id, 'WEIGHT', NULL, NULL, NULL, NULL, NULL, 48 + MOD(i * 4, 46), '体重记录', DATE_SUB(NOW(), INTERVAL MOD(i + 2, 10) DAY), 0, NOW());

    -- 预约：60 个今日待接诊，40 个未来预约
    INSERT INTO `appointment` (`patient_id`, `doctor_id`, `appointment_date`, `appointment_time`, `department`, `symptoms`, `status`, `cancel_reason`, `diagnosis`, `prescription`, `fee`, `create_time`, `update_time`)
    VALUES (
      patient_id,
      current_doctor_id,
      IF(i <= 60, CURDATE(), DATE_ADD(CURDATE(), INTERVAL (1 + MOD(i, 6)) DAY)),
      CASE MOD(i, 4) WHEN 0 THEN '上午' WHEN 1 THEN '下午' WHEN 2 THEN '09:30' ELSE '15:00' END,
      (SELECT `department` FROM `doctor_info` WHERE `id` = current_doctor_id),
      CASE MOD(i, 6) WHEN 0 THEN '血压偏高，头胀' WHEN 1 THEN '血糖波动，咨询用药' WHEN 2 THEN '体检报告咨询' WHEN 3 THEN '鼻塞流涕，过敏症状' WHEN 4 THEN '关节疼痛复查' ELSE '胃部不适，饮食后明显' END,
      0,
      NULL,
      NULL,
      NULL,
      (SELECT `consultation_fee` FROM `doctor_info` WHERE `id` = current_doctor_id),
      NOW(),
      NOW()
    );

    SET i = i + 1;
  END WHILE;
END $$

DELIMITER ;

CALL seed_large_demo_data();
DROP PROCEDURE IF EXISTS seed_large_demo_data;

-- 验证建议：
-- SELECT COUNT(*) FROM doctor_info WHERE id BETWEEN 8301 AND 8350;
-- SELECT COUNT(*) FROM patient_info WHERE id BETWEEN 8401 AND 8500;
-- SELECT COUNT(*) FROM health_data WHERE patient_id BETWEEN 8401 AND 8500;
