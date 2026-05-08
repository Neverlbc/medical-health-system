package com.medical.system.mapper;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.medical.system.entity.PatientRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface PatientRecordMapper extends com.baomidou.mybatisplus.core.mapper.BaseMapper<PatientRecord> {

    @Select("<script>" +
            "SELECT p.user_id as userId, p.real_name as patientName, p.gender, p.age, " +
            "r.id, " +
            "COALESCE(NULLIF(TRIM(r.allergies), ''), pa.allergySummary, NULLIF(TRIM(p.allergies), '')) as allergies, " +
            "COALESCE(NULLIF(TRIM(r.family_history), ''), fh.familyHistorySummary, NULLIF(TRIM(p.family_history), '')) as familyHistory, " +
            "COALESCE(NULLIF(TRIM(r.medical_history), ''), ph.pastHistorySummary, NULLIF(TRIM(p.medical_history), ''), dr.diagnosisSummary) as medicalHistory, " +
            "r.medication_history as medicationHistory, r.remark, r.create_time as createTime " +
            "FROM patient_info p " +
            "LEFT JOIN patient_record r ON p.user_id = r.user_id AND r.deleted = 0 " +
            "LEFT JOIN ( " +
            "  SELECT patient_id, " +
            "         GROUP_CONCAT( " +
            "           CONCAT(allergen, " +
            "             CASE WHEN severity IS NOT NULL AND TRIM(severity) != '' THEN " +
            "               CONCAT('（', CASE severity WHEN 'SEVERE' THEN '严重' WHEN 'MODERATE' THEN '中度' WHEN 'MILD' THEN '轻微' ELSE severity END, " +
            "                 CASE WHEN reaction IS NOT NULL AND TRIM(reaction) != '' THEN CONCAT('：', reaction) ELSE '' END, '）') " +
            "             WHEN reaction IS NOT NULL AND TRIM(reaction) != '' THEN CONCAT('（', reaction, '）') " +
            "             ELSE '' END) " +
            "           ORDER BY CASE severity WHEN 'SEVERE' THEN 1 WHEN 'MODERATE' THEN 2 WHEN 'MILD' THEN 3 ELSE 4 END, id " +
            "           SEPARATOR '；' " +
            "         ) as allergySummary " +
            "  FROM patient_allergy " +
            "  WHERE allergen IS NOT NULL AND TRIM(allergen) != '' " +
            "  GROUP BY patient_id " +
            ") pa ON pa.patient_id = p.id " +
            "LEFT JOIN ( " +
            "  SELECT patient_id, " +
            "         GROUP_CONCAT( " +
            "           CONCAT( " +
            "             COALESCE(NULLIF(TRIM(disease_name), ''), NULLIF(TRIM(description), ''), '病史记录'), " +
            "             CASE WHEN diagnosis_date IS NOT NULL THEN CONCAT('（', diagnosis_date, '）') ELSE '' END " +
            "           ) " +
            "           ORDER BY diagnosis_date DESC, id DESC " +
            "           SEPARATOR '；' " +
            "         ) as pastHistorySummary " +
            "  FROM patient_history " +
            "  WHERE history_type = 'PAST' AND (status IS NULL OR status = 1) " +
            "  GROUP BY patient_id " +
            ") ph ON ph.patient_id = p.id " +
            "LEFT JOIN ( " +
            "  SELECT patient_id, " +
            "         GROUP_CONCAT( " +
            "           CONCAT( " +
            "             CASE WHEN relationship IS NOT NULL AND TRIM(relationship) != '' THEN CONCAT(relationship, '：') ELSE '' END, " +
            "             COALESCE(NULLIF(TRIM(disease_name), ''), NULLIF(TRIM(description), ''), '家族史记录') " +
            "           ) " +
            "           ORDER BY id DESC " +
            "           SEPARATOR '；' " +
            "         ) as familyHistorySummary " +
            "  FROM patient_history " +
            "  WHERE history_type = 'FAMILY' AND (status IS NULL OR status = 1) " +
            "  GROUP BY patient_id " +
            ") fh ON fh.patient_id = p.id " +
            "LEFT JOIN ( " +
            "  SELECT patient_id, " +
            "         CONCAT('近诊：', GROUP_CONCAT( " +
            "           CONCAT(disease_name, CASE WHEN diagnosis_date IS NOT NULL THEN CONCAT('（', diagnosis_date, '）') ELSE '' END) " +
            "           ORDER BY diagnosis_date DESC, id DESC " +
            "           SEPARATOR '；' " +
            "         )) as diagnosisSummary " +
            "  FROM diagnosis_record " +
            "  WHERE disease_name IS NOT NULL AND TRIM(disease_name) != '' " +
            "  GROUP BY patient_id " +
            ") dr ON dr.patient_id = p.id " +
            "WHERE 1=1 " +
            "<if test='userId != null'> AND p.user_id = #{userId} </if>" +
            "<if test='keyword != null and keyword != \"\"'>" +
            "  AND (p.real_name LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR r.remark LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR r.allergies LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR p.allergies LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR pa.allergySummary LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR r.family_history LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR p.family_history LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR fh.familyHistorySummary LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR r.medical_history LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR p.medical_history LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR ph.pastHistorySummary LIKE CONCAT('%', #{keyword}, '%') " +
            "       OR dr.diagnosisSummary LIKE CONCAT('%', #{keyword}, '%')) " +
            "</if>" +
            "ORDER BY r.create_time DESC, p.id DESC" +
            "</script>")
    IPage<PatientRecord> selectPatientRecordsPage(Page<PatientRecord> page, 
                                                  @Param("keyword") String keyword, 
                                                  @Param("userId") Long userId);
}

