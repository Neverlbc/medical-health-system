package com.medical.ai.controller;

import com.medical.ai.service.DeepSeekService;
import com.medical.common.result.Result;
import com.medical.common.utils.SecurityUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import javax.validation.constraints.NotBlank;

/**
 * AI问诊控制器
 *
 * @author lbc
 * @date 2025-11-06
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/ai")
@Tag(name = "AI智能问诊", description = "AI症状分析、用药指导、健康知识问答")
public class AIConsultationController {

    @Autowired
    private DeepSeekService deepSeekService;

    @PostMapping("/symptom-analysis")
    @Operation(summary = "症状分析")
    public Result<String> analyzeSymptom(@RequestBody @Valid SymptomRequest request) {
        String result = deepSeekService.analyzeSymptom(request.getSymptoms());
        return Result.success(result);
    }

    @PostMapping("/medication-guide")
    @Operation(summary = "用药指导")
    public Result<String> getMedicationGuide(@RequestBody @Valid MedicationRequest request) {
        String result = deepSeekService.getMedicationGuide(request.getMedicineName());
        return Result.success(result);
    }

    @PostMapping("/health-question")
    @Operation(summary = "健康知识问答")
    public Result<String> answerHealthQuestion(@RequestBody @Valid HealthQuestionRequest request) {
        String result = deepSeekService.answerHealthQuestion(request.getQuestion());
        return Result.success(result);
    }

    @Data
    public static class SymptomRequest {
        @NotBlank(message = "症状描述不能为空")
        private String symptoms;
    }

    @Data
    public static class MedicationRequest {
        @NotBlank(message = "药品名称不能为空")
        private String medicineName;
    }

    @Data
    public static class HealthQuestionRequest {
        @NotBlank(message = "问题不能为空")
        private String question;
    }
    @Autowired
    private com.medical.system.service.HealthProfileService healthProfileService;

    @PostMapping("/health-analysis")
    @Operation(summary = "全量健康分析")
    public Result<String> analyzeHealth(@RequestBody @Valid HealthAnalysisRequest request) {
        Long userId = com.medical.common.utils.SecurityUtils.getUserId();
        // 获取健康档案 (Service内部会进行权限校验)
        // 注意：这里我们假设当前用户就是患者。如果是医生查看患者，需要前端传 patientId，这里暂简化为查看自己
        // 如果需要支持医生查看，Request需增加 patientId 字段，并在此处判断
        Long targetId = request.getPatientId() != null ? request.getPatientId() : userId;
        
        var profile = healthProfileService.getProfile(targetId);
        String json = com.alibaba.fastjson2.JSON.toJSONString(profile);
        
        String result = deepSeekService.analyzeHealthProfile(json, request.getQuestion());
        return Result.success(result);
    }

    @GetMapping("/daily-tip")
    @Operation(summary = "每日健康小贴士")
    public Result<String> getDailyTip() {
        if (!isPatientRole()) {
            String result = deepSeekService.answerHealthQuestion("请生成一条适合医护或管理人员的今日健康与工作提醒，简短、专业、温和。");
            return Result.success(result);
        }

        Long userId = SecurityUtils.getUserId();
        var profile = healthProfileService.getProfile(userId);
        String json = com.alibaba.fastjson2.JSON.toJSONString(profile);
        
        String result = deepSeekService.generateDailyTip(json);
        return Result.success(result);
    }

    @PostMapping("/chat")
    @Operation(summary = "智能问诊(带档案)")
    public Result<String> chat(@RequestBody @Valid ChatRequest request) {
        var deepSeekRequest = deepSeekService.buildRequest(buildChatSystemPrompt(), request.getMessage(), null);
        var response = deepSeekService.chat(deepSeekRequest);
        String result = extractContent(response);
        return Result.success(result);
    }

    @PostMapping(value = "/chat/stream", produces = org.springframework.http.MediaType.TEXT_EVENT_STREAM_VALUE)
    @Operation(summary = "智能问诊-流式输出(SSE)")
    public org.springframework.web.servlet.mvc.method.annotation.SseEmitter chatStream(@RequestBody @Valid ChatRequest request) {
        org.springframework.web.servlet.mvc.method.annotation.SseEmitter emitter = 
            new org.springframework.web.servlet.mvc.method.annotation.SseEmitter(120000L); // 2分钟超时
        
        String systemPrompt = buildChatSystemPrompt();
        
        com.medical.ai.model.DeepSeekRequest deepSeekRequest = deepSeekService.buildRequest(systemPrompt, request.getMessage(), null);
        
        deepSeekService.chatStream(deepSeekRequest, 
            chunk -> {
                try {
                    // JSON encode to preserve newlines and special characters
                    String jsonChunk = com.alibaba.fastjson2.JSON.toJSONString(chunk);
                    emitter.send(org.springframework.web.servlet.mvc.method.annotation.SseEmitter.event()
                        .data(jsonChunk)
                        .name("message"));
                } catch (java.io.IOException e) {
                    log.debug("SSE发送失败: {}", e.getMessage());
                    emitter.completeWithError(e);
                }
            },
            () -> {
                try {
                    emitter.send(org.springframework.web.servlet.mvc.method.annotation.SseEmitter.event()
                        .data("[DONE]")
                        .name("done"));
                    emitter.complete();
                } catch (java.io.IOException e) {
                    log.debug("SSE完成失败: {}", e.getMessage());
                }
            }
        );
        
        return emitter;
    }

    @Data
    public static class ChatRequest {
        @NotBlank(message = "消息不能为空")
        private String message;
    }

    @Data
    public static class HealthAnalysisRequest {
        private String question;
        private Long patientId; // 可选，医生查询时使用
    }

    private boolean isPatientRole() {
        return "PATIENT".equals(SecurityUtils.getUserRole());
    }

    private String buildChatSystemPrompt() {
        if (isPatientRole()) {
            Long userId = SecurityUtils.getUserId();
            var profile = healthProfileService.getProfile(userId);
            String json = com.alibaba.fastjson2.JSON.toJSONString(profile);
            return "你是一位专业的医疗AI助手。以下是当前患者的健康档案（JSON格式）：" + json
                    + "。请结合档案回答患者的问题。如果问题与档案无关，则正常回答。请注意：1. 如果患者询问用药，务必检查过敏史。2. 回答要严谨、专业，但语气要亲切。";
        }

        String role = SecurityUtils.getUserRole();
        if ("DOCTOR".equals(role)) {
            return "你是智慧医疗系统中的医生侧 Agent「云小医」。当前用户是医生。请只基于用户消息中提供的系统提醒和问题回答，帮助医生整理接诊优先级、重点患者复核方向和随访建议。不要假装拥有未提供的患者完整档案，不要触发或要求读取当前医生本人的患者档案。";
        }
        if ("ADMIN".equals(role)) {
            return "你是智慧医疗系统中的管理侧 Agent「云小医」。当前用户是管理员。请只基于用户消息中提供的系统提醒和问题回答，帮助管理员整理运营风险、排班风险、预约处理和协同动作。不要输出患者隐私明细，不要假装拥有未提供的患者完整档案。";
        }
        return "你是智慧医疗系统中的角色化 Agent「云小医」。请基于用户消息中提供的角色、系统提醒和问题回答，不要假装拥有未提供的患者完整档案。";
    }

    private String extractContent(com.medical.ai.model.DeepSeekResponse response) {
        if (response == null || response.getChoices() == null || response.getChoices().isEmpty()) {
            return "云小医暂时无法生成回复，请稍后再试。";
        }
        var message = response.getChoices().get(0).getMessage();
        return message != null && message.getContent() != null
                ? message.getContent()
                : "云小医暂时无法生成回复，请稍后再试。";
    }
}

