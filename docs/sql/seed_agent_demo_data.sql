-- 云小医 / 首页 / 健康数据演示测试数据
-- 用途：本地开发环境快速录入医生、患者、健康监测、病史和预约数据
-- 账号密码：以下新增账号统一使用 test123

USE `medical_health`;

START TRANSACTION;

-- 先清理本脚本写入的数据，保证可重复执行
DELETE FROM `appointment` WHERE `patient_id` BETWEEN 8201 AND 8206 OR `doctor_id` BETWEEN 8101 AND 8103;
DELETE FROM `doctor_schedule` WHERE `doctor_id` BETWEEN 8101 AND 8103;
DELETE FROM `health_data` WHERE `patient_id` BETWEEN 8201 AND 8206;
DELETE FROM `diagnosis_record` WHERE `patient_id` BETWEEN 8201 AND 8206;
DELETE FROM `patient_history` WHERE `patient_id` BETWEEN 8201 AND 8206;
DELETE FROM `patient_allergy` WHERE `patient_id` BETWEEN 8201 AND 8206;
DELETE FROM `patient_record` WHERE `user_id` BETWEEN 8201 AND 8206;
DELETE FROM `doctor_info` WHERE `id` BETWEEN 8101 AND 8103 OR `user_id` BETWEEN 8101 AND 8103;
DELETE FROM `patient_info` WHERE `id` BETWEEN 8201 AND 8206 OR `user_id` BETWEEN 8201 AND 8206;
DELETE FROM `sys_user` WHERE `id` BETWEEN 8101 AND 8103 OR `id` BETWEEN 8201 AND 8206;

-- 医生账号
INSERT INTO `sys_user` (`id`, `username`, `password`, `nickname`, `phone`, `email`, `avatar`, `role`, `status`, `create_time`, `update_time`, `last_login_time`, `deleted`) VALUES
(8101, 'doctor_cardio', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '周明远', '13800008101', 'doctor_cardio@test.com', NULL, 'DOCTOR', 1, NOW(), NOW(), NULL, 0),
(8102, 'doctor_endo', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '林雅宁', '13800008102', 'doctor_endo@test.com', NULL, 'DOCTOR', 1, NOW(), NOW(), NULL, 0),
(8103, 'doctor_rehab', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '陈亦舟', '13800008103', 'doctor_rehab@test.com', NULL, 'DOCTOR', 1, NOW(), NOW(), NULL, 0);

INSERT INTO `doctor_info` (`id`, `user_id`, `real_name`, `gender`, `department`, `title`, `specialty`, `introduction`, `certificate_no`, `work_years`, `consultation_fee`, `rating`, `patient_count`, `status`, `create_time`, `update_time`) VALUES
(8101, 8101, '周明远', 1, '心内科', '主任医师', '高血压、冠心病、心律失常、慢病管理', '长期从事心血管慢病管理，擅长高血压分层管理和复诊随访。', 'DOC-DEMO-8101', 22, 10.00, 4.95, 1280, 1, NOW(), NOW()),
(8102, 8102, '林雅宁', 0, '内分泌科', '副主任医师', '糖尿病、甲状腺疾病、代谢综合征', '关注血糖波动与生活方式干预，擅长糖尿病用药和饮食运动指导。', 'DOC-DEMO-8102', 16, 10.00, 4.88, 940, 1, NOW(), NOW()),
(8103, 8103, '陈亦舟', 1, '康复医学科', '主治医师', '术后康复、颈肩腰腿痛、运动处方', '擅长康复评估、运动处方制定和慢性疼痛管理。', 'DOC-DEMO-8103', 11, 10.00, 4.76, 610, 1, NOW(), NOW());

-- 患者账号
INSERT INTO `sys_user` (`id`, `username`, `password`, `nickname`, `phone`, `email`, `avatar`, `role`, `status`, `create_time`, `update_time`, `last_login_time`, `deleted`) VALUES
(8201, 'patient_bp_high', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '许安然', '13900008201', 'patient_bp_high@test.com', NULL, 'PATIENT', 1, NOW(), NOW(), NULL, 0),
(8202, 'patient_sugar', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '赵一诺', '13900008202', 'patient_sugar@test.com', NULL, 'PATIENT', 1, NOW(), NOW(), NULL, 0),
(8203, 'patient_normal', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '顾清和', '13900008203', 'patient_normal@test.com', NULL, 'PATIENT', 1, NOW(), NOW(), NULL, 0),
(8204, 'patient_elder', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '孙桂兰', '13900008204', 'patient_elder@test.com', NULL, 'PATIENT', 1, NOW(), NOW(), NULL, 0),
(8205, 'patient_rehab', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '沈星河', '13900008205', 'patient_rehab@test.com', NULL, 'PATIENT', 1, NOW(), NOW(), NULL, 0),
(8206, 'patient_child', '$2a$10$K8aIDyfnZYQS.UgdYiw1s.05P5qqvaTfk65hASDDDxvMAxy1vPTT6', '程小满', '13900008206', 'patient_child@test.com', NULL, 'PATIENT', 1, NOW(), NOW(), NULL, 0);

INSERT INTO `patient_info` (`id`, `user_id`, `real_name`, `gender`, `birthday`, `age`, `id_card`, `address`, `emergency_contact`, `emergency_phone`, `height`, `weight`, `blood_type`, `allergies`, `family_history`, `medical_history`, `create_time`, `update_time`) VALUES
(8201, 8201, '许安然', 1, '1982-03-18', 44, '110101198203188201', '北京市朝阳区望京街道演示地址1号', '许敏', '13910008201', 172.00, 78.00, 'A', '青霉素过敏', '父亲高血压，母亲冠心病', '原发性高血压5年', NOW(), NOW()),
(8202, 8202, '赵一诺', 0, '1978-09-02', 47, '110101197809028202', '北京市海淀区中关村演示地址2号', '赵阳', '13910008202', 160.00, 66.00, 'O', '无明确药物过敏', '母亲2型糖尿病', '2型糖尿病3年', NOW(), NOW()),
(8203, 8203, '顾清和', 1, '1994-12-20', 31, '110101199412208203', '北京市西城区演示地址3号', '顾晓', '13910008203', 178.00, 72.00, 'B', '无', '无明显家族遗传史', '无重大疾病史', NOW(), NOW()),
(8204, 8204, '孙桂兰', 0, '1958-07-11', 67, '110101195807118204', '北京市东城区演示地址4号', '孙磊', '13910008204', 156.00, 61.00, 'AB', '磺胺类药物过敏', '父亲脑卒中史', '高血压、骨质疏松', NOW(), NOW()),
(8205, 8205, '沈星河', 1, '1989-01-08', 37, '110101198901088205', '北京市丰台区演示地址5号', '沈宁', '13910008205', 181.00, 82.00, 'A', '花粉过敏', '无', '右膝半月板术后康复中', NOW(), NOW()),
(8206, 8206, '程小满', 0, '2016-05-21', 9, '110101201605218206', '北京市通州区演示地址6号', '程女士', '13910008206', 135.00, 32.00, 'O', '芒果过敏', '无', '过敏性鼻炎', NOW(), NOW());

INSERT INTO `patient_record` (`user_id`, `allergies`, `family_history`, `medical_history`, `medication_history`, `remark`, `create_time`, `update_time`, `deleted`) VALUES
(8201, '青霉素过敏，皮疹', '父亲高血压，母亲冠心病', '原发性高血压5年', '氨氯地平 5mg qd', '近期晨起血压偏高，建议复诊评估。', NOW(), NOW(), 0),
(8202, '无明确药物过敏', '母亲2型糖尿病', '2型糖尿病3年', '二甲双胍 0.5g bid', '餐后血糖波动，建议记录饮食。', NOW(), NOW(), 0),
(8203, '无', '无', '无重大疾病史', '无长期用药', '健康状态稳定，适合普通健康档案演示。', NOW(), NOW(), 0),
(8204, '磺胺类药物过敏', '父亲脑卒中史', '高血压、骨质疏松', '缬沙坦 80mg qd；钙剂 qd', '老年慢病随访重点患者。', NOW(), NOW(), 0),
(8205, '花粉过敏', '无', '右膝半月板术后康复', '布洛芬按需使用', '用于康复医学场景演示。', NOW(), NOW(), 0),
(8206, '芒果过敏', '无', '过敏性鼻炎', '氯雷他定按需', '儿童患者健康提醒演示。', NOW(), NOW(), 0);

INSERT INTO `patient_allergy` (`patient_id`, `allergen`, `allergy_type`, `reaction`, `severity`, `record_date`, `create_time`) VALUES
(8201, '青霉素', 'DRUG', '皮疹、瘙痒', 'MODERATE', '2012-04-01', NOW()),
(8204, '磺胺类药物', 'DRUG', '皮疹', 'SEVERE', '2008-06-12', NOW()),
(8205, '花粉', 'ENV', '鼻塞、流涕', 'MILD', '2021-03-18', NOW()),
(8206, '芒果', 'FOOD', '口唇肿胀', 'MILD', '2024-08-12', NOW());

INSERT INTO `patient_history` (`patient_id`, `history_type`, `disease_name`, `diagnosis_date`, `relationship`, `description`, `status`, `create_time`, `update_time`) VALUES
(8201, 'PAST', '原发性高血压', '2021-05-10', NULL, '最高血压约165/100mmHg，间断服药。', 1, NOW(), NOW()),
(8201, 'FAMILY', '冠心病', NULL, '母亲', '母亲有冠心病病史。', 1, NOW(), NOW()),
(8202, 'PAST', '2型糖尿病', '2023-09-18', NULL, '空腹和餐后血糖波动，需饮食运动管理。', 1, NOW(), NOW()),
(8202, 'FAMILY', '2型糖尿病', NULL, '母亲', '母亲患2型糖尿病10余年。', 1, NOW(), NOW()),
(8204, 'PAST', '骨质疏松', '2024-01-06', NULL, '腰背酸痛，规律补钙。', 1, NOW(), NOW()),
(8205, 'PAST', '右膝半月板损伤术后', '2025-11-20', NULL, '术后康复训练中。', 1, NOW(), NOW()),
(8206, 'PAST', '过敏性鼻炎', '2024-04-01', NULL, '季节性发作，春季明显。', 1, NOW(), NOW());

INSERT INTO `diagnosis_record` (`patient_id`, `diagnosis_type`, `disease_name`, `icd10_code`, `diagnosis_date`, `doctor_id`, `description`, `create_time`) VALUES
(8201, 'CONFIRMED', '原发性高血压', 'I10.x00', DATE_SUB(CURDATE(), INTERVAL 20 DAY), 8101, '家庭血压记录偏高，建议规律服药并复诊。', NOW()),
(8202, 'CONFIRMED', '2型糖尿病', 'E11.900', DATE_SUB(CURDATE(), INTERVAL 18 DAY), 8102, '餐后血糖偏高，建议饮食记录和药物调整评估。', NOW()),
(8204, 'CONFIRMED', '高血压伴骨质疏松', 'I10.x00', DATE_SUB(CURDATE(), INTERVAL 12 DAY), 8101, '老年慢病随访，需关注跌倒风险。', NOW()),
(8205, 'PRELIMINARY', '膝关节术后康复', 'Z47.800', DATE_SUB(CURDATE(), INTERVAL 7 DAY), 8103, '康复训练阶段，建议逐步增加活动量。', NOW());

-- 近期健康数据：包含正常、需关注和优先处理三类状态，便于首页 / 云小医演示
INSERT INTO `health_data` (`patient_id`, `data_type`, `systolic_pressure`, `diastolic_pressure`, `blood_sugar`, `heart_rate`, `temperature`, `weight`, `remark`, `measure_time`, `status`, `create_time`) VALUES
(8201, 'BLOOD_PRESSURE', 142, 92, NULL, 82, NULL, NULL, '晨起血压偏高', DATE_SUB(NOW(), INTERVAL 6 DAY), 2, NOW()),
(8201, 'BLOOD_PRESSURE', 150, 96, NULL, 86, NULL, NULL, '连续偏高，建议复诊', DATE_SUB(NOW(), INTERVAL 1 DAY), 3, NOW()),
(8201, 'HEART_RATE', NULL, NULL, NULL, 88, NULL, NULL, '心率稍快', DATE_SUB(NOW(), INTERVAL 1 DAY), 1, NOW()),
(8202, 'BLOOD_SUGAR', NULL, NULL, 7.20, NULL, NULL, NULL, '餐后血糖偏高', DATE_SUB(NOW(), INTERVAL 5 DAY), 2, NOW()),
(8202, 'BLOOD_SUGAR', NULL, NULL, 9.60, NULL, NULL, NULL, '餐后2小时明显偏高', DATE_SUB(NOW(), INTERVAL 1 DAY), 3, NOW()),
(8202, 'WEIGHT', NULL, NULL, NULL, NULL, NULL, 66.30, '体重稳定', DATE_SUB(NOW(), INTERVAL 2 DAY), 0, NOW()),
(8203, 'BLOOD_PRESSURE', 118, 76, NULL, 70, NULL, NULL, '正常', DATE_SUB(NOW(), INTERVAL 1 DAY), 0, NOW()),
(8203, 'BLOOD_SUGAR', NULL, NULL, 5.40, NULL, NULL, NULL, '正常', DATE_SUB(NOW(), INTERVAL 1 DAY), 0, NOW()),
(8203, 'TEMPERATURE', NULL, NULL, NULL, NULL, 36.50, NULL, '正常', DATE_SUB(NOW(), INTERVAL 12 HOUR), 0, NOW()),
(8204, 'BLOOD_PRESSURE', 168, 102, NULL, 90, NULL, NULL, '老年患者血压危险偏高', DATE_SUB(NOW(), INTERVAL 10 HOUR), 4, NOW()),
(8204, 'HEART_RATE', NULL, NULL, NULL, 96, NULL, NULL, '心率偏快', DATE_SUB(NOW(), INTERVAL 10 HOUR), 2, NOW()),
(8205, 'WEIGHT', NULL, NULL, NULL, NULL, NULL, 82.00, '康复期体重记录', DATE_SUB(NOW(), INTERVAL 1 DAY), 0, NOW()),
(8205, 'HEART_RATE', NULL, NULL, NULL, 78, NULL, NULL, '运动后恢复可', DATE_SUB(NOW(), INTERVAL 8 HOUR), 0, NOW()),
(8206, 'TEMPERATURE', NULL, NULL, NULL, NULL, 37.80, NULL, '低热，观察', DATE_SUB(NOW(), INTERVAL 6 HOUR), 2, NOW()),
(8206, 'HEART_RATE', NULL, NULL, NULL, 102, NULL, NULL, '儿童心率偏快，结合体温观察', DATE_SUB(NOW(), INTERVAL 6 HOUR), 1, NOW());

-- 未来 7 天排班
INSERT INTO `doctor_schedule` (`doctor_id`, `schedule_date`, `time_period`, `max_patients`, `booked_patients`, `status`, `create_time`, `update_time`) VALUES
(8101, CURDATE(), '上午', 20, 2, 1, NOW(), NOW()),
(8101, CURDATE(), '下午', 20, 1, 1, NOW(), NOW()),
(8101, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '上午', 20, 1, 1, NOW(), NOW()),
(8102, CURDATE(), '上午', 18, 1, 1, NOW(), NOW()),
(8102, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '下午', 18, 1, 1, NOW(), NOW()),
(8103, CURDATE(), '下午', 16, 1, 1, NOW(), NOW()),
(8103, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '上午', 16, 1, 1, NOW(), NOW());

-- 待接诊 / 近期预约
INSERT INTO `appointment` (`patient_id`, `doctor_id`, `appointment_date`, `appointment_time`, `department`, `symptoms`, `status`, `cancel_reason`, `diagnosis`, `prescription`, `fee`, `create_time`, `update_time`) VALUES
(8201, 8101, CURDATE(), '上午', '心内科', '近一周晨起血压偏高，偶有头胀', 0, NULL, NULL, NULL, 10.00, NOW(), NOW()),
(8204, 8101, CURDATE(), '下午', '心内科', '血压升高，夜间睡眠差', 0, NULL, NULL, NULL, 10.00, NOW(), NOW()),
(8202, 8102, CURDATE(), '上午', '内分泌科', '餐后血糖偏高，咨询用药调整', 0, NULL, NULL, NULL, 10.00, NOW(), NOW()),
(8205, 8103, CURDATE(), '下午', '康复医学科', '膝关节术后复查和运动处方调整', 0, NULL, NULL, NULL, 10.00, NOW(), NOW()),
(8206, 8102, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '下午', '内分泌科', '近期低热，伴鼻塞流涕', 0, NULL, NULL, NULL, 10.00, NOW(), NOW()),
(8203, 8101, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '上午', '心内科', '年度健康咨询', 0, NULL, NULL, NULL, 10.00, NOW(), NOW());

COMMIT;

-- 快速登录账号：
-- 医生：doctor_cardio / test123，doctor_endo / test123，doctor_rehab / test123
-- 患者：patient_bp_high / test123，patient_sugar / test123，patient_normal / test123
