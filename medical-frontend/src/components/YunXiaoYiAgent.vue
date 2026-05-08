<template>
  <div class="yun-agent" :class="{ 'is-open': panelOpen }">
    <transition name="agent-panel">
      <section v-if="panelOpen" class="agent-panel">
        <header class="agent-header">
          <div class="agent-identity">
            <div class="bot-head">
              <svg viewBox="0 0 128 128" aria-hidden="true">
                <rect x="24" y="32" width="80" height="72" rx="24" fill="#fffaf5" stroke="#9a6a43" stroke-width="5" />
                <rect x="38" y="49" width="52" height="28" rx="10" fill="#fbf4ec" />
                <circle cx="52" cy="63" r="4.5" fill="#9a6a43" />
                <circle cx="76" cy="63" r="4.5" fill="#9a6a43" />
                <path d="M55 84c6 5 14 5 20 0" fill="none" stroke="#6f8263" stroke-width="5" stroke-linecap="round" />
                <rect x="58" y="21" width="12" height="15" rx="6" fill="#d6a85c" />
                <circle cx="64" cy="18" r="6" fill="#6f8263" />
              </svg>
            </div>
            <div>
              <div class="agent-name">云小医</div>
              <div class="agent-status">
                <span></span>
                {{ roleProfile.status }}
              </div>
            </div>
          </div>

          <div class="agent-actions">
            <button type="button" title="刷新提醒" :disabled="insightLoading" @click="loadRoleInsights">
              <el-icon :class="{ 'is-loading': insightLoading }"><Refresh /></el-icon>
            </button>
            <button type="button" :title="roleProfile.primaryAction" @click="openPrimaryRoute">
              <el-icon><Expand /></el-icon>
            </button>
            <button type="button" title="清空对话记录" aria-label="清空对话记录" @click="resetMessages">
              <el-icon><Delete /></el-icon>
            </button>
            <button type="button" title="收起" @click="panelOpen = false">
              <el-icon><Minus /></el-icon>
            </button>
          </div>
        </header>

        <div ref="messageListRef" class="agent-messages">
          <div
            v-for="message in messages"
            :key="message.id"
            class="agent-message"
            :class="message.role"
          >
            <div v-if="message.role === 'assistant'" class="mini-avatar" aria-hidden="true">
              <svg viewBox="0 0 40 40">
                <rect x="7" y="10" width="26" height="23" rx="9" fill="#fffaf5" stroke="#9a6a43" stroke-width="2" />
                <circle cx="16" cy="21" r="1.7" fill="#9a6a43" />
                <circle cx="24" cy="21" r="1.7" fill="#9a6a43" />
                <path d="M17 27c2.2 1.6 4.8 1.6 7 0" fill="none" stroke="#6f8263" stroke-width="2" stroke-linecap="round" />
                <rect x="18" y="5" width="4" height="6" rx="2" fill="#d6a85c" />
                <circle cx="20" cy="4.5" r="2" fill="#6f8263" />
              </svg>
            </div>
            <div class="message-bubble">
              <div v-if="message.content" class="message-content" v-html="formatContent(message.content)"></div>
              <div v-else class="typing-dots">
                <span></span><span></span><span></span>
              </div>
            </div>
          </div>
        </div>

        <div class="quick-prompts" v-if="!hasUserMessages">
          <button v-for="prompt in roleProfile.prompts" :key="prompt" type="button" @click="sendMessage(prompt)">
            {{ prompt }}
          </button>
        </div>

        <footer class="agent-footer">
          <div class="input-shell">
            <textarea
              v-model="question"
              rows="2"
              maxlength="300"
              :placeholder="roleProfile.placeholder"
              :disabled="loading"
              @keydown="onKeydown"
            ></textarea>
            <button type="button" :disabled="loading || !question.trim()" @click="sendMessage()">
              <el-icon v-if="loading" class="is-loading"><Loading /></el-icon>
              <el-icon v-else><Promotion /></el-icon>
            </button>
          </div>
          <p>{{ roleProfile.footer }}</p>
        </footer>
      </section>
    </transition>

    <button v-if="!panelOpen" type="button" class="agent-pet" @click="openPanel">
      <span class="pet-halo"></span>
      <span class="pet-bubble">{{ collapsedText }}</span>
      <span class="pet-body">
        <svg viewBox="0 0 128 128" aria-hidden="true">
          <rect x="25" y="35" width="78" height="68" rx="24" fill="#fff" />
          <rect x="25" y="35" width="78" height="68" rx="24" fill="none" stroke="#9a6a43" stroke-width="5" />
          <rect x="39" y="51" width="50" height="27" rx="10" fill="#fbf4ec" />
          <circle cx="53" cy="64" r="4.5" fill="#9a6a43" />
          <circle cx="75" cy="64" r="4.5" fill="#9a6a43" />
          <path d="M55 84c6 5 13 5 19 0" fill="none" stroke="#6f8263" stroke-width="5" stroke-linecap="round" />
          <rect x="59" y="23" width="10" height="14" rx="5" fill="#d6a85c" />
          <circle cx="64" cy="20" r="6" fill="#6f8263" />
        </svg>
      </span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { Delete, Expand, Loading, Minus, Promotion, Refresh } from '@element-plus/icons-vue';
import { ElMessage } from 'element-plus';
import { useAuthStore } from '@/store/modules/auth';
import { aiApi } from '@/api/modules/ai';
import { appointmentApi, type Appointment } from '@/api/modules/appointment';
import { getHealthDataPage, type HealthData } from '@/api/modules/health';
import { listRecords, type PatientRecord } from '@/api/modules/record';
import { getOverview } from '@/api/modules/statistics';
import { scheduleApi, type DoctorSchedule } from '@/api/modules/schedule';
import { getPatientInfoByUserId } from '@/api/modules/user';
import { labTestApi, treatmentPlanApi, type LabTest, type TreatmentPlan } from '@/api/modules/health-record-full';

type UserRole = 'PATIENT' | 'DOCTOR' | 'ADMIN';
type ReminderLevel = 'success' | 'info' | 'warning' | 'danger';

interface AgentMessage {
  id: number;
  role: 'assistant' | 'user';
  content: string;
  isStreaming?: boolean;
  meta?: 'reminder' | 'notice';
}

interface AgentReminder {
  id: string;
  level: ReminderLevel;
  title: string;
  description: string;
  actionText?: string;
  routeName?: string;
  routeParams?: Record<string, string | number | undefined>;
}

const API_BASE = import.meta.env.VITE_API_BASE_URL || '/api/v1';
const REMINDER_MESSAGE_ID = -2026042901;

const router = useRouter();
const authStore = useAuthStore();
const panelOpen = ref(false);
const loading = ref(false);
const insightLoading = ref(false);
const question = ref('');
const messages = ref<AgentMessage[]>([]);
const reminders = ref<AgentReminder[]>([]);
const messageListRef = ref<HTMLDivElement>();

const role = computed<UserRole>(() => {
  const value = authStore.userInfo?.role?.replace(/^ROLE_/, '');
  if (value === 'DOCTOR' || value === 'ADMIN') return value;
  return 'PATIENT';
});

const storageKey = computed(() => `yun-xiao-yi-history-${role.value}-${authStore.userInfo?.username || 'guest'}`);
const hasUserMessages = computed(() => messages.value.some(item => item.role === 'user'));

const roleProfile = computed(() => {
  if (role.value === 'DOCTOR') {
    return {
      title: '医生接诊 Agent',
      status: '接诊提醒在线',
      description: '关注今日待接诊患者、重点异常指标和患者风险变化。',
      primaryAction: '查看预约',
      primaryRoute: 'Appointments',
      placeholder: '问云小医：今日接诊怎么排序、重点患者怎么处理...',
      footer: '提醒基于当前系统数据生成，请结合临床判断处理。',
      prompts: ['今天接诊重点是什么', '哪些患者需要优先关注', '帮我整理随访建议']
    };
  }

  if (role.value === 'ADMIN') {
    return {
      title: '管理运营 Agent',
      status: '管理提醒在线',
      description: '关注预约量、排班风险、异常健康数据和运营管理事项。',
      primaryAction: '查看统计',
      primaryRoute: 'DataAnalysis',
      placeholder: '问云小医：今天运营有什么异常、排班怎么优化...',
      footer: '管理建议基于系统数据概览生成，请结合实际业务规则确认。',
      prompts: ['今天运营重点是什么', '排班有没有风险', '帮我总结管理动作']
    };
  }

  return {
    title: '患者健康 Agent',
    status: '健康提醒在线',
    description: '关注健康异常、用药记录、检查复查和预约就诊提醒。',
    primaryAction: '完整问诊',
    primaryRoute: 'AIConsultation',
    placeholder: '问云小医：用药、检查、睡眠、症状都可以...',
    footer: '仅供健康参考，紧急症状请立即就医或拨打 120。',
    prompts: ['我今天要注意什么', '帮我看用药提醒', '近期是否需要复查']
  };
});

const collapsedText = computed(() => {
  const dangerCount = reminders.value.filter(item => item.level === 'danger').length;
  if (dangerCount > 0) return `云小医 · ${dangerCount} 条重点`;
  if (reminders.value.length > 0) return `云小医 · ${reminders.value.length} 条提醒`;
  return '我是云小医';
});

const reminderLevelText: Record<ReminderLevel, string> = {
  success: '正常',
  info: '提醒',
  warning: '需关注',
  danger: '优先处理'
};

const formatReminderLine = (item: AgentReminder) => {
  const action = item.actionText ? ` 建议：前往「${item.actionText}」处理。` : '';
  return `- 【${reminderLevelText[item.level]}】${item.title}：${item.description}${action}`;
};

const reminderDigest = computed(() => {
  if (insightLoading.value) return '正在同步系统提醒，请稍候。';
  if (!reminders.value.length) return '当前没有紧急事项，云小医会持续关注健康、用药、检查和预约动态。';
  return reminders.value.map(formatReminderLine).join('\n');
});

const reminderChatContent = computed(() => {
  if (insightLoading.value) {
    return '我正在同步你的健康提醒，稍后会把需要关注的事项整理在对话里。';
  }

  const priorityReminders = reminders.value.filter(item => item.level === 'danger' || item.level === 'warning');
  const normalReminders = reminders.value.filter(item => item.level === 'info' || item.level === 'success');
  const actionReminders = reminders.value.filter(item => item.actionText).slice(0, 3);

  if (!reminders.value.length) {
    return [
      '## 今日重点',
      '- 当前没有紧急事项。',
      '- 我会继续关注健康、用药、检查和预约动态。',
      '',
      '## 可继续追问',
      '- 今天我还需要注意什么？',
      '- 近期是否需要复查？'
    ].join('\n');
  }

  return [
    '## 今日重点',
    ...(priorityReminders.length ? priorityReminders.map(formatReminderLine) : ['- 暂无高优先级风险。']),
    '',
    '## 其他提醒',
    ...(normalReminders.length ? normalReminders.map(formatReminderLine) : ['- 暂无其他待办提醒。']),
    '',
    '## 建议动作',
    ...(actionReminders.length
      ? actionReminders.map(item => `- 点击「${item.actionText}」查看或处理：${item.title}`)
      : ['- 可以继续向我追问优先级、用药、检查或预约安排。'])
  ].join('\n');
});

const defaultMessages = (): AgentMessage[] => [
  {
    id: Date.now(),
    role: 'assistant',
    content: `我是云小医，${roleProfile.value.description}你也可以直接问我具体问题。`
  }
];

const openPanel = () => {
  panelOpen.value = true;
  loadRoleInsights();
  scrollToBottom();
};

const scrollToBottom = () => {
  nextTick(() => {
    const el = messageListRef.value;
    if (el) {
      el.scrollTo({ top: el.scrollHeight, behavior: 'smooth' });
    }
  });
};

const saveMessages = () => {
  try {
    const history = messages.value.filter(item => !item.isStreaming && !item.meta).slice(-30);
    localStorage.setItem(storageKey.value, JSON.stringify(history));
  } catch {}
};

const loadMessages = () => {
  try {
    const raw = localStorage.getItem(storageKey.value);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) {
        messages.value = parsed;
        scrollToBottom();
        return;
      }
    }
  } catch {}
  messages.value = defaultMessages();
};

const syncReminderMessage = () => {
  const messageIndex = messages.value.findIndex(item => item.meta === 'reminder');
  const message: AgentMessage = {
    id: REMINDER_MESSAGE_ID,
    role: 'assistant',
    content: reminderChatContent.value,
    meta: 'reminder'
  };

  if (messageIndex >= 0) {
    messages.value[messageIndex] = message;
  } else {
    messages.value.push(message);
  }

  scrollToBottom();
};

const resetMessages = () => {
  try {
    localStorage.removeItem(storageKey.value);
  } catch {}

  messages.value = [{
    id: Date.now(),
    role: 'assistant',
    content: '对话记录已清空。我会保留当前系统提醒在这里，方便你继续追问具体事项。',
    meta: 'notice'
  }];
  syncReminderMessage();
  ElMessage.success('云小医对话已清空');
  scrollToBottom();
};

const updateAssistantMessage = (id: number, content: string, isStreaming = true) => {
  const message = messages.value.find(item => item.id === id);
  if (message) {
    message.content = content;
    message.isStreaming = isStreaming;
  }
  if (!isStreaming) {
    saveMessages();
  }
  scrollToBottom();
};

const loadRoleInsights = async () => {
  insightLoading.value = true;
  try {
    if (role.value === 'DOCTOR') {
      reminders.value = await buildDoctorReminders();
    } else if (role.value === 'ADMIN') {
      reminders.value = await buildAdminReminders();
    } else {
      reminders.value = await buildPatientReminders();
    }
  } catch {
    reminders.value = [{
      id: 'insight-error',
      level: 'warning',
      title: '提醒同步失败',
      description: '当前无法获取最新提醒，请稍后刷新。',
      actionText: '刷新'
    }];
  } finally {
    insightLoading.value = false;
    syncReminderMessage();
  }
};

const buildPatientReminders = async () => {
  const nextReminders: AgentReminder[] = [];
  const userId = authStore.userInfo?.id;
  const [healthResult, appointmentResult, recordResult, patientInfoResult] = await Promise.allSettled([
    getHealthDataPage({ current: 1, size: 20 }),
    appointmentApi.list({ pageNum: 1, pageSize: 20 }),
    listRecords({ pageNum: 1, pageSize: 1, userId }),
    userId ? getPatientInfoByUserId(userId) : Promise.resolve(undefined)
  ]);

  const healthRecords = fulfilledValue(healthResult)?.records || [];
  const abnormalRecords = healthRecords.filter(item => (item.status || 0) > 0).slice(0, 2);
  abnormalRecords.forEach(item => {
    nextReminders.push({
      id: `health-${item.id || item.measureTime}`,
      level: (item.status || 0) >= 3 ? 'danger' : 'warning',
      title: `${healthDataName(item.dataType)}异常提醒`,
      description: `${formatHealthValue(item)}，建议关注趋势，必要时咨询医生。`,
      actionText: '查看',
      routeName: 'HealthData'
    });
  });

  const appointments = fulfilledValue(appointmentResult)?.records || [];
  const upcoming = appointments
    .filter(item => item.status === 0 && isTodayOrFuture(item.appointmentDate))
    .sort(sortAppointmentAsc)[0];
  if (upcoming) {
    nextReminders.push({
      id: `appointment-${upcoming.id}`,
      level: isToday(upcoming.appointmentDate) ? 'warning' : 'info',
      title: isToday(upcoming.appointmentDate) ? '今日就诊提醒' : '预约就诊提醒',
      description: `${formatDateText(upcoming.appointmentDate)} ${upcoming.appointmentTime || ''}，${upcoming.doctorName || upcoming.department || '门诊'}。`,
      actionText: '预约',
      routeName: 'Appointments'
    });
  }

  const patientInfo = fulfilledValue(patientInfoResult);
  if (patientInfo?.id) {
    const [planResult, labResult] = await Promise.allSettled([
      treatmentPlanApi.list(patientInfo.id),
      labTestApi.list(patientInfo.id)
    ]);
    const activePlans = (fulfilledValue(planResult) || []).filter(item => item.status === 'ACTIVE');
    if (activePlans.length) {
      nextReminders.push({
        id: `plan-${activePlans[0].id || 'active'}`,
        level: 'info',
        title: '用药/治疗方案提醒',
        description: `当前有 ${activePlans.length} 个进行中的治疗方案，请按医嘱执行并记录异常反应。`,
        actionText: '档案',
        routeName: 'FullRecordDetail',
        routeParams: { patientId: userId }
      });
    }

    const labTests = fulfilledValue(labResult) || [];
    const latestLab = labTests.sort((a, b) => new Date(b.testDate).getTime() - new Date(a.testDate).getTime())[0];
    if (!latestLab) {
      nextReminders.push({
        id: 'lab-empty',
        level: 'info',
        title: '检查记录提醒',
        description: '当前缺少近期检查记录，可在健康档案中补充化验或检查结果。',
        actionText: '补充',
        routeName: 'FullRecordDetail',
        routeParams: { patientId: userId }
      });
    } else if (daysBetween(latestLab.testDate, new Date()) > 180) {
      nextReminders.push({
        id: `lab-${latestLab.id}`,
        level: 'warning',
        title: '检查复查提醒',
        description: `最近一次${latestLab.testType || '检查'}已超过 6 个月，可考虑复查。`,
        actionText: '查看',
        routeName: 'FullRecordDetail',
        routeParams: { patientId: userId }
      });
    }
  }

  const record = fulfilledValue(recordResult)?.records?.[0] as PatientRecord | undefined;
  if (record?.medicationHistory && !nextReminders.some(item => item.title.includes('用药'))) {
    nextReminders.push({
      id: `medication-${record.id || 'record'}`,
      level: 'info',
      title: '用药记录提醒',
      description: '系统检测到既往用药记录，复诊或问诊时请主动告知医生。',
      actionText: '档案',
      routeName: 'Records'
    });
  }

  return nextReminders.slice(0, 5);
};

const buildDoctorReminders = async () => {
  const nextReminders: AgentReminder[] = [];
  const [appointmentResult] = await Promise.allSettled([
    appointmentApi.list({ pageNum: 1, pageSize: 50 })
  ]);

  const appointments = fulfilledValue(appointmentResult)?.records || [];
  const todayAppointments = appointments.filter(item => item.status === 0 && isToday(item.appointmentDate));
  if (todayAppointments.length) {
    const first = todayAppointments.sort(sortAppointmentAsc)[0];
    nextReminders.push({
      id: 'doctor-today-appointments',
      level: 'warning',
      title: `今日待接诊 ${todayAppointments.length} 人`,
      description: `下一位：${first.patientName || '患者'}，${first.appointmentTime || '待定时段'}，主诉：${first.symptoms || '未填写'}。`,
      actionText: '接诊',
      routeName: 'Appointments'
    });
  }

  const futurePending = appointments.filter(item => item.status === 0 && isTodayOrFuture(item.appointmentDate));
  if (!todayAppointments.length && futurePending.length) {
    const next = futurePending.sort(sortAppointmentAsc)[0];
    nextReminders.push({
      id: `doctor-next-${next.id}`,
      level: 'info',
      title: '近期预约提醒',
      description: `${formatDateText(next.appointmentDate)} ${next.appointmentTime || ''} 有 ${next.patientName || '患者'} 预约。`,
      actionText: '查看',
      routeName: 'Appointments'
    });
  }

  if (appointments.length) {
    nextReminders.push({
      id: 'doctor-risk-review',
      level: 'info',
      title: '重点患者风险复核',
      description: '进入患者名单查看名下患者档案与监测异常，云小医不会在首页触发患者权限接口。',
      actionText: '患者',
      routeName: 'DoctorPatients'
    });
  }

  return nextReminders.slice(0, 5);
};

const buildAdminReminders = async () => {
  const nextReminders: AgentReminder[] = [];
  const today = formatDate(new Date());
  const nextWeek = formatDate(addDays(new Date(), 7));
  const [overviewResult, appointmentResult, healthResult, scheduleResult] = await Promise.allSettled([
    getOverview(),
    appointmentApi.list({ pageNum: 1, pageSize: 80 }),
    getHealthDataPage({ current: 1, size: 80 }),
    scheduleApi.list({ startDate: today, endDate: nextWeek })
  ]);

  const overview = fulfilledValue(overviewResult);
  if (overview) {
    nextReminders.push({
      id: 'admin-overview',
      level: 'info',
      title: '运营概览',
      description: `患者 ${overview.totalPatients || 0} 人，今日预约 ${overview.todayAppointments || 0} 单，累计诊断 ${overview.totalDiagnoses || 0} 条。`,
      actionText: '统计',
      routeName: 'DataAnalysis'
    });
  }

  const appointments = fulfilledValue(appointmentResult)?.records || [];
  const todayPending = appointments.filter(item => item.status === 0 && isToday(item.appointmentDate));
  if (todayPending.length) {
    nextReminders.push({
      id: 'admin-today-appointment',
      level: 'warning',
      title: `今日待处理预约 ${todayPending.length} 单`,
      description: '建议关注高峰科室接诊节奏和患者到诊情况。',
      actionText: '预约',
      routeName: 'Appointments'
    });
  }

  const schedules = fulfilledValue(scheduleResult) || [];
  const riskSchedules = schedules.filter(item => item.status !== 1 || isScheduleFull(item));
  if (riskSchedules.length) {
    nextReminders.push({
      id: 'admin-schedule-risk',
      level: 'warning',
      title: `排班风险 ${riskSchedules.length} 项`,
      description: '存在停诊或号源紧张时段，建议及时调整排班。',
      actionText: '排班',
      routeName: 'ScheduleManage'
    });
  }

  const severeRecords = (fulfilledValue(healthResult)?.records || []).filter(item => (item.status || 0) >= 3);
  if (severeRecords.length) {
    nextReminders.push({
      id: 'admin-severe-health',
      level: 'danger',
      title: `重点健康异常 ${severeRecords.length} 条`,
      description: '系统存在重度或危险级别健康指标，请协调医生跟进。',
      actionText: '数据',
      routeName: 'DataAnalysis'
    });
  }

  return nextReminders.slice(0, 5);
};

const buildRoleContext = (content: string) => {
  return [
    '你是医疗健康系统中的角色化 Agent「云小医」。',
    `当前用户角色：${roleProfile.value.title}。`,
    '请围绕该角色职责回答，优先结合系统提醒给出风险点、优先级和下一步动作。',
    '',
    '当前系统提醒：',
    reminderDigest.value,
    '',
    '输出要求：',
    '1. 如果用户询问“今天注意什么 / 用药 / 检查 / 预约 / 症状”，先主动整理提醒事项。',
    '2. 用短标题和项目符号输出，避免大段套话。',
    '3. 不输出 Markdown 分隔线，不重复通用免责声明。',
    '4. 仅提供健康参考和就医建议，不直接下诊断。',
    '',
    `用户问题：${content}`
  ].join('\n');
};

const sendMessage = async (preset?: string) => {
  const content = (preset || question.value).trim();
  if (!content || loading.value) return;

  messages.value.push({ id: Date.now(), role: 'user', content });
  question.value = '';
  loading.value = true;

  const assistantId = Date.now() + 1;
  messages.value.push({ id: assistantId, role: 'assistant', content: '', isStreaming: true });
  scrollToBottom();

  const roleContext = buildRoleContext(content);

  try {
    const reply = await requestStreamingReply(roleContext, assistantId);
    if (!reply) {
      throw new Error('empty stream reply');
    }
  } catch {
    try {
      const fallbackReply = await aiApi.chat({ message: roleContext });
      updateAssistantMessage(assistantId, normalizeContent(String(fallbackReply || '我暂时无法生成回复，请稍后再试。')), false);
    } catch {
      updateAssistantMessage(assistantId, '网络通讯异常，云小医暂时无法连接服务。', false);
    }
  } finally {
    loading.value = false;
    saveMessages();
  }
};

const requestStreamingReply = async (content: string, assistantId: number) => {
  const response = await fetch(`${API_BASE}/ai/chat/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${authStore.token}`
    },
    body: JSON.stringify({ message: content })
  });

  if (!response.ok || !response.body) {
    throw new Error(`stream error: ${response.status}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let fullContent = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const line of lines) {
      if (!line.startsWith('data:')) continue;

      const rawData = line.substring(5);
      if (rawData.trim() === '[DONE]') {
        const normalized = normalizeContent(fullContent);
        updateAssistantMessage(assistantId, normalized || '我暂时没有收到完整回复，请稍后再试。', false);
        return normalized;
      }

      if (!rawData.trim()) continue;

      try {
        fullContent += JSON.parse(rawData.trim());
      } catch {
        fullContent += rawData;
      }
      updateAssistantMessage(assistantId, normalizeContent(fullContent), true);
    }
  }

  const normalized = normalizeContent(fullContent);
  updateAssistantMessage(assistantId, normalized || '我暂时没有收到完整回复，请稍后再试。', false);
  return normalized;
};

const handleReminder = (reminder: AgentReminder) => {
  if (reminder.id === 'insight-error') {
    loadRoleInsights();
    return;
  }

  if (reminder.routeName) {
    router.push({ name: reminder.routeName, params: reminder.routeParams });
  }
};

const openPrimaryRoute = () => {
  router.push({ name: roleProfile.value.primaryRoute });
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendMessage();
  }
};

const fulfilledValue = <T>(result: PromiseSettledResult<T>) => result.status === 'fulfilled' ? result.value : undefined;

const healthDataName = (type: string) => {
  const names: Record<string, string> = {
    BLOOD_PRESSURE: '血压',
    BLOOD_SUGAR: '血糖',
    HEART_RATE: '心率',
    TEMPERATURE: '体温',
    WEIGHT: '体重'
  };
  return names[type] || '健康指标';
};

const formatHealthValue = (record: HealthData) => {
  switch (record.dataType) {
    case 'BLOOD_PRESSURE':
      return `${record.systolicPressure || '-'}/${record.diastolicPressure || '-'} mmHg`;
    case 'BLOOD_SUGAR':
      return `${record.bloodSugar || '-'} mmol/L`;
    case 'HEART_RATE':
      return `${record.heartRate || '-'} bpm`;
    case 'TEMPERATURE':
      return `${record.temperature || '-'} ℃`;
    case 'WEIGHT':
      return `${record.weight || '-'} kg`;
    default:
      return '存在异常记录';
  }
};

const isToday = (date?: string) => Boolean(date && String(date).slice(0, 10) === formatDate(new Date()));

const isTodayOrFuture = (date?: string) => Boolean(date && String(date).slice(0, 10) >= formatDate(new Date()));

const sortAppointmentAsc = (a: Appointment, b: Appointment) => {
  const left = `${a.appointmentDate || ''} ${a.appointmentTime || ''}`;
  const right = `${b.appointmentDate || ''} ${b.appointmentTime || ''}`;
  return left.localeCompare(right);
};

const formatDateText = (date?: string) => {
  if (!date) return '待定日期';
  if (isToday(date)) return '今天';
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) return String(date).slice(0, 10);
  return `${parsed.getMonth() + 1}月${parsed.getDate()}日`;
};

const formatDate = (date: Date) => {
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
};

const addDays = (date: Date, days: number) => {
  const cloned = new Date(date);
  cloned.setDate(cloned.getDate() + days);
  return cloned;
};

const daysBetween = (start: string, end: Date) => {
  const startDate = new Date(start);
  if (Number.isNaN(startDate.getTime())) return 0;
  return Math.floor((end.getTime() - startDate.getTime()) / 86400000);
};

const isScheduleFull = (schedule: DoctorSchedule) => {
  const maxPatients = schedule.maxPatients || 0;
  const bookedPatients = schedule.bookedPatients || 0;
  return maxPatients > 0 && bookedPatients >= maxPatients;
};

const escapeHtml = (content: string) => {
  return content.replace(/[&<>"']/g, char => {
    const entities: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;'
    };
    return entities[char];
  });
};

const normalizeContent = (content: string) => {
  return content
    .replace(/\r\n/g, '\n')
    .replace(/^[-*_]{3,}\s*$/gm, '')
    .replace(/^\*?⚠️?\s*(以上内容由 AI 自动生成，仅供健康参考，不构成医疗诊断。如有疑问请咨询专业医生。)\*?$/gm, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
};

const formatContent = (content: string) => {
  return escapeHtml(normalizeContent(content))
    .replace(/^###\s+(.+)$/gm, '<h3>$1</h3>')
    .replace(/^##\s+(.+)$/gm, '<h2>$1</h2>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/^\s*[-*]\s+(.+)$/gm, '<div class="agent-list-item">$1</div>')
    .replace(/\n/g, '<br>');
};

watch(role, () => {
  loadMessages();
  loadRoleInsights();
});

onMounted(() => {
  loadMessages();
  loadRoleInsights();
});
</script>

<style scoped lang="scss">
.yun-agent {
  position: fixed;
  right: 34px;
  bottom: 32px;
  z-index: 850;
  pointer-events: none;

  &.is-open {
    z-index: 980;
  }
}

.agent-pet,
.agent-panel {
  pointer-events: auto;
}

.agent-pet {
  position: relative;
  width: 86px;
  height: 98px;
  border: none;
  background: transparent;
  cursor: pointer;
  animation: pet-float 3.6s ease-in-out infinite;

  &:hover {
    .pet-body {
      transform: translateY(-4px) scale(1.04);
      box-shadow: 0 24px 44px rgba(154, 106, 67, 0.2);
    }

    .pet-bubble {
      transform: translateY(-3px);
      opacity: 1;
    }
  }
}

.pet-halo {
  position: absolute;
  left: 50%;
  bottom: 2px;
  width: 62px;
  height: 16px;
  border-radius: 999px;
  background: rgba(154, 106, 67, 0.13);
  filter: blur(2px);
  transform: translateX(-50%);
}

.pet-bubble {
  position: absolute;
  right: 68px;
  top: 8px;
  white-space: nowrap;
  padding: 8px 11px;
  border: 1px solid rgba(231, 217, 202, 0.9);
  border-radius: 999px 999px 6px 999px;
  background: rgba(255, 255, 255, 0.94);
  color: #8a5a38;
  box-shadow: 0 14px 32px rgba(15, 23, 42, 0.1);
  font-size: 12px;
  font-weight: 800;
  opacity: 0.92;
  transition: 0.25s ease;
}

.pet-body {
  position: absolute;
  left: 6px;
  bottom: 10px;
  width: 74px;
  height: 74px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 26px;
  background:
    radial-gradient(circle at 24% 18%, rgba(111, 130, 99, 0.12), transparent 24%),
    linear-gradient(145deg, #ffffff, #f8fafc);
  box-shadow: 0 18px 38px rgba(15, 23, 42, 0.12);
  transition: 0.25s ease;

  svg {
    width: 64px;
    height: 64px;
  }
}

.agent-panel {
  width: 388px;
  height: 560px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid rgba(231, 217, 202, 0.88);
  border-radius: 24px;
  background:
    radial-gradient(circle at 88% 0%, rgba(111, 130, 99, 0.08), transparent 30%),
    #ffffff;
  box-shadow: 0 24px 68px rgba(15, 23, 42, 0.13);
  backdrop-filter: blur(18px);
}

.agent-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 14px 12px 16px;
  border-bottom: 1px solid #e5e7eb;
  background: #fff;
}

.agent-identity {
  display: flex;
  align-items: center;
  gap: 10px;
}

.bot-head {
  width: 42px;
  height: 42px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 16px;
  background: #fff;
  box-shadow: 0 12px 24px rgba(154, 106, 67, 0.12);

  svg {
    width: 37px;
    height: 37px;
  }
}

.agent-name {
  color: #2f2923;
  font-size: 16px;
  font-weight: 900;
  letter-spacing: -0.3px;
}

.agent-status {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 2px;
  color: #7b6b5c;
  font-size: 11px;
  font-weight: 700;

  span {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: #22c55e;
    box-shadow: 0 0 0 4px rgba(34, 197, 94, 0.12);
  }
}

.agent-actions {
  display: flex;
  align-items: center;
  gap: 5px;

  button {
    width: 30px;
    height: 30px;
    border: 1px solid #e5e7eb;
    border-radius: 11px;
    background: #fff;
    color: #7b6b5c;
    cursor: pointer;
    transition: 0.2s ease;

    &:hover:not(:disabled) {
      color: #8a5a38;
      border-color: rgba(154, 106, 67, 0.2);
      box-shadow: 0 10px 22px rgba(154, 106, 67, 0.1);
    }

    &:disabled {
      cursor: not-allowed;
      opacity: 0.65;
    }
  }
}

.agent-brief {
  padding: 16px 18px 14px;
  border-bottom: 1px solid #e5e7eb;
  background: #f8fafc;
}

.brief-top {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 12px;

  strong {
    color: #2f2923;
    font-size: 15px;
    font-weight: 900;
  }

  p {
    margin: 4px 0 0;
    color: #7b6b5c;
    font-size: 12px;
    line-height: 1.55;
  }
}

.brief-count {
  height: 24px;
  flex-shrink: 0;
  padding: 0 9px;
  border-radius: 999px;
  background: #f7f3ef;
  color: #8a5a38;
  font-size: 12px;
  font-weight: 900;
  line-height: 24px;
}

.brief-loading,
.empty-reminder {
  display: flex;
  align-items: center;
  min-height: 48px;
  color: #94a3b8;
  font-size: 13px;
  font-weight: 700;
}

.brief-loading {
  gap: 6px;

  span {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: #d6a85c;
    animation: dot-bounce 1.2s infinite ease-in-out;

    &:nth-child(2) { animation-delay: 0.15s; }
    &:nth-child(3) { animation-delay: 0.3s; }
  }
}

.reminder-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 172px;
  overflow-y: auto;
  padding-right: 2px;
}

.reminder-card {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  background: #fff;
  padding: 11px 12px;
  text-align: left;
  cursor: pointer;
  transition: 0.2s ease;

  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 12px 26px rgba(15, 23, 42, 0.07);
  }

  &.success .reminder-dot { background: #22c55e; }
  &.info .reminder-dot { background: #9a6a43; }
  &.warning .reminder-dot { background: #f59e0b; }
  &.danger {
    border-color: rgba(239, 68, 68, 0.2);
    background: #fff7f7;

    .reminder-dot { background: #ef4444; }
  }
}

.reminder-dot {
  width: 9px;
  height: 9px;
  flex-shrink: 0;
  border-radius: 50%;
  box-shadow: 0 0 0 4px rgba(154, 106, 67, 0.09);
}

.reminder-main {
  flex: 1;
  min-width: 0;

  strong {
    display: block;
    color: #2f2923;
    font-size: 13px;
    font-weight: 900;
  }

  small {
    display: block;
    overflow: hidden;
    color: #7b6b5c;
    font-size: 12px;
    line-height: 1.45;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}

.reminder-action {
  flex-shrink: 0;
  color: #8a5a38;
  font-size: 12px;
  font-weight: 900;
}

.agent-messages {
  flex: 1;
  min-height: 0;
  padding: 14px 15px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.agent-message {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  max-width: 94%;

  &.user {
    align-self: flex-end;

    .message-bubble {
      color: #fff;
      background: linear-gradient(135deg, #9a6a43, #c9895d);
      border-radius: 18px 18px 5px 18px;
      box-shadow: 0 12px 28px rgba(154, 106, 67, 0.18);
    }
  }

  &.assistant {
    align-self: flex-start;

    .message-bubble {
      color: #4a3a2e;
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 18px 18px 18px 5px;
      box-shadow: 0 10px 26px rgba(15, 23, 42, 0.05);
    }
  }
}

.mini-avatar {
  width: 30px;
  height: 30px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 2px;
  border: 1px solid rgba(154, 106, 67, 0.16);
  border-radius: 12px;
  background: linear-gradient(145deg, #fff, #f8fafc);
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.07);

  svg {
    width: 25px;
    height: 25px;
  }
}

.message-bubble {
  padding: 10px 12px;
  font-size: 13px;
  line-height: 1.68;
  word-break: break-word;
}

.message-content {
  :deep(h2),
  :deep(h3) {
    margin: 4px 0 6px;
    color: #2f2923;
    font-size: 15px;
  }

  :deep(strong) {
    color: #8a5a38;
  }

  :deep(.agent-list-item) {
    position: relative;
    padding-left: 13px;
    margin: 2px 0;

    &::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0.85em;
      width: 5px;
      height: 5px;
      border-radius: 50%;
      background: #94a3b8;
    }
  }
}

.typing-dots {
  display: inline-flex;
  align-items: center;
  gap: 4px;

  span {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: #94a3b8;
    animation: dot-bounce 1.2s infinite ease-in-out;

    &:nth-child(2) { animation-delay: 0.15s; }
    &:nth-child(3) { animation-delay: 0.3s; }
  }
}

.quick-prompts {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 0 15px 10px;

  button {
    border: 1px solid #e5e7eb;
    border-radius: 999px;
    background: #fff;
    color: #8a5a38;
    padding: 7px 10px;
    font-size: 12px;
    font-weight: 700;
    cursor: pointer;
    transition: 0.2s ease;

    &:hover {
      background: #f8fafc;
      transform: translateY(-1px);
    }
  }
}

.agent-footer {
  padding: 12px 14px 14px;
  border-top: 1px solid #e5e7eb;
  background: #fff;

  p {
    margin: 8px 2px 0;
    color: #94a3b8;
    font-size: 11px;
    line-height: 1.5;
  }
}

.input-shell {
  display: flex;
  gap: 8px;
  align-items: flex-end;

  textarea {
    flex: 1;
    min-height: 48px;
    max-height: 82px;
    resize: none;
    border: 1px solid #e5e7eb;
    border-radius: 14px;
    outline: none;
    padding: 10px 12px;
    background: #f8fafc;
    color: #2f2923;
    font-family: inherit;
    font-size: 13px;
    line-height: 1.5;
    transition: 0.2s ease;

    &:focus {
      background: #fff;
      border-color: rgba(154, 106, 67, 0.42);
      box-shadow: 0 0 0 4px rgba(214, 168, 92, 0.13);
    }

    &:disabled {
      cursor: not-allowed;
      opacity: 0.75;
    }
  }

  button {
    width: 42px;
    height: 42px;
    flex-shrink: 0;
    border: none;
    border-radius: 14px;
    background: linear-gradient(135deg, #9a6a43, #c9895d);
    color: #fff;
    cursor: pointer;
    box-shadow: 0 14px 26px rgba(154, 106, 67, 0.22);
    transition: 0.2s ease;

    &:hover:not(:disabled) {
      transform: translateY(-2px);
      box-shadow: 0 18px 34px rgba(154, 106, 67, 0.28);
    }

    &:disabled {
      cursor: not-allowed;
      background: #cbd5e1;
      box-shadow: none;
    }
  }
}

.agent-panel-enter-active,
.agent-panel-leave-active {
  transition: all 0.24s ease;
}

.agent-panel-enter-from,
.agent-panel-leave-to {
  opacity: 0;
  transform: translateY(16px) scale(0.96);
}

@keyframes pet-float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

@keyframes dot-bounce {
  0%, 80%, 100% { transform: translateY(0); opacity: 0.45; }
  40% { transform: translateY(-4px); opacity: 1; }
}

@media (max-width: 768px) {
  .yun-agent {
    right: 0;
    bottom: 0;
    left: 0;
    display: flex;
    justify-content: flex-end;
    padding: 0 14px 14px;

    &.is-open {
      padding: 0;
    }
  }

  .agent-panel {
    width: 100vw;
    height: min(560px, calc(100vh - 72px));
    border-right: none;
    border-bottom: none;
    border-left: none;
    border-radius: 24px 24px 0 0;
  }

  .agent-pet {
    width: 76px;
    height: 88px;
  }

  .pet-bubble {
    right: 58px;
    top: 6px;
  }

  .pet-body {
    width: 66px;
    height: 66px;

    svg {
      width: 58px;
      height: 58px;
    }
  }
}
</style>
