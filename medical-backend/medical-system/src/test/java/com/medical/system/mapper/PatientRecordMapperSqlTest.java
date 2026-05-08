package com.medical.system.mapper;

import org.apache.ibatis.annotations.Select;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.assertTrue;

@DisplayName("健康档案列表摘要 SQL 测试")
class PatientRecordMapperSqlTest {

    private String selectPatientRecordsPageSql() throws NoSuchMethodException {
        Method method = PatientRecordMapper.class.getMethod(
                "selectPatientRecordsPage",
                com.baomidou.mybatisplus.extension.plugins.pagination.Page.class,
                String.class,
                Long.class
        );
        Select select = method.getAnnotation(Select.class);
        return String.join(" ", Arrays.asList(select.value()));
    }

    @Test
    @DisplayName("列表摘要应从结构化过敏史和病史表兜底")
    void shouldFallbackToStructuredSummaries() throws Exception {
        String sql = selectPatientRecordsPageSql();

        assertTrue(sql.contains("COALESCE(NULLIF(TRIM(r.allergies), ''), pa.allergySummary, NULLIF(TRIM(p.allergies), ''))"));
        assertTrue(sql.contains("COALESCE(NULLIF(TRIM(r.family_history), ''), fh.familyHistorySummary, NULLIF(TRIM(p.family_history), ''))"));
        assertTrue(sql.contains("COALESCE(NULLIF(TRIM(r.medical_history), ''), ph.pastHistorySummary, NULLIF(TRIM(p.medical_history), ''), dr.diagnosisSummary)"));
        assertTrue(sql.contains("FROM patient_allergy"));
        assertTrue(sql.contains("FROM patient_history"));
        assertTrue(sql.contains("FROM diagnosis_record"));
    }

    @Test
    @DisplayName("结构化明细应通过患者信息表主键关联")
    void shouldJoinStructuredTablesByPatientInfoId() throws Exception {
        String sql = selectPatientRecordsPageSql();

        assertTrue(sql.contains("pa ON pa.patient_id = p.id"));
        assertTrue(sql.contains("ph ON ph.patient_id = p.id"));
        assertTrue(sql.contains("fh ON fh.patient_id = p.id"));
        assertTrue(sql.contains("dr ON dr.patient_id = p.id"));
    }

    @Test
    @DisplayName("关键词搜索应覆盖摘要聚合字段")
    void shouldSearchAggregatedSummaryFields() throws Exception {
        String sql = selectPatientRecordsPageSql();

        assertTrue(sql.contains("pa.allergySummary LIKE"));
        assertTrue(sql.contains("fh.familyHistorySummary LIKE"));
        assertTrue(sql.contains("ph.pastHistorySummary LIKE"));
        assertTrue(sql.contains("dr.diagnosisSummary LIKE"));
    }
}
