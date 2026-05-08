<template>
  <div class="appointment-container">
    <div class="page-header">
      <div class="header-content">
        <el-icon class="header-icon"><Calendar /></el-icon>
        <div class="title-group">
          <h1>预约挂号中心</h1>
          <p>专业医生为您提供全方位的健康咨询与诊疗服务</p>
        </div>
      </div>
      <el-button type="primary" size="large" :icon="Plus" @click="openDialog" class="create-btn">
        快速挂号
      </el-button>
    </div>

    <!-- 顶层统计看板 -->
    <div class="stat-row">
      <div v-for="stat in stats" :key="stat.label" class="stat-card">
        <div class="stat-icon" :style="{ backgroundColor: stat.bg }">
          <el-icon :color="stat.color"><component :is="stat.icon" /></el-icon>
        </div>
        <div class="stat-info">
          <span class="stat-value">{{ stat.value }}</span>
          <span class="stat-label">{{ stat.label }}</span>
        </div>
      </div>
    </div>

    <div class="main-content">
      <el-tabs v-model="activeTab" class="modern-tabs">
        <el-tab-pane label="我的预约列表" name="list">
          <div class="table-container">
            <el-table 
              v-loading="loading" 
              :data="appointments" 
              class="med-modern-table"
              border
            >
              <el-table-column label="就诊信息" min-width="200">
                <template #default="{ row }">
                  <div class="table-info-cell">
                    <div class="dept-tag">{{ row.department }}</div>
                    <div class="appointment-id">预约单号: #{{ row.id?.toString().padStart(6, '0') }}</div>
                  </div>
                </template>
              </el-table-column>
              
              <el-table-column label="主治医生" width="160">
                <template #default="{ row }">
                  <div class="doctor-profile">
                    <el-avatar :size="32" class="doc-avatar">{{ row.doctorName?.charAt(0) }}</el-avatar>
                    <span>{{ row.doctorName }}</span>
                  </div>
                </template>
              </el-table-column>

              <el-table-column label="就诊时间" width="220">
                <template #default="{ row }">
                  <div class="time-cell">
                    <span class="date">{{ row.appointmentDate }}</span>
                    <el-tag size="small" effect="plain" round class="period-tag">{{ row.appointmentTime }}</el-tag>
                  </div>
                </template>
              </el-table-column>

              <el-table-column label="当前状态" width="120" align="center">
                <template #default="{ row }">
                  <span :class="['status-dot', getStatusClass(row.status)]"></span>
                  <span :class="['status-text', getStatusClass(row.status)]">
                    {{ getStatusText(row.status) }}
                  </span>
                </template>
              </el-table-column>

              <el-table-column label="操作" width="180" align="center" fixed="right">
                <template #default="{ row }">
                  <div class="action-btns">
                    <el-tooltip content="查看详情" placement="top">
                      <el-button circle :icon="View" size="small" @click="$router.push(`/records/full/${row.patientUserId}`)" />
                    </el-tooltip>
                    <el-button 
                      v-if="row.status === 0 && isDoctor" 
                      type="success" 
                      size="small" 
                      plain
                      @click="handleComplete(row.id)"
                    >完成就诊</el-button>
                    <el-button 
                      v-if="row.status === 0" 
                      type="danger" 
                      link 
                      size="small"
                      @click="handleCancel(row.id)"
                    >取消</el-button>
                  </div>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <el-tab-pane label="排班概览" name="schedule">
          <div class="schedule-view">
             <!-- 科室筛选 -->
             <div class="filter-bar">
               <el-radio-group v-model="selectedDept" size="large" @change="handleDeptFilter">
                 <el-radio-button label="">全部科室</el-radio-button>
                 <el-radio-button v-for="dept in uniqueDepartments" :key="dept" :label="dept" />
               </el-radio-group>
             </div>

             <div class="doctor-cards-grid">
               <div v-for="doc in filterScheduleDoctors" :key="doc.id" class="doctor-card">
                 <div class="doc-card-header">
                   <el-avatar :size="50" class="doc-main-avatar" :icon="UserFilled" />
                   <div class="doc-title-info">
                     <h3>{{ doc.realName }}</h3>
                     <span>{{ doc.title }} | {{ doc.department }}</span>
                   </div>
                 </div>
                 <div class="doc-specialty">
                   <strong>擅长：</strong>{{ doc.specialty || '全科诊疗' }}
                 </div>
                 <div class="doc-footer">
                   <span class="fee">￥{{ doc.consultationFee }}</span>
                   <el-button type="primary" link :icon="ArrowRight" @click="startBooking(doc)">去挂号</el-button>
                 </div>
               </div>
             </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>

    <!-- 挂号弹窗 -->
    <el-dialog 
      v-model="dialogVisible" 
      title="智慧医疗预约服务" 
      width="640px" 
      class="premium-dialog"
      append-to-body
      destroy-on-close
    >
      <div class="booking-dialog-content">
        <el-form :model="form" label-position="top" class="booking-form">
          <div class="form-grid">
            <el-form-item label="选择科室">
              <el-select v-model="form.department" placeholder="请选择科室" class="full-width" @change="handleDepartmentChange">
                <el-option v-for="dept in uniqueDepartments" :key="dept" :label="dept" :value="dept" />
              </el-select>
            </el-form-item>
            
            <el-form-item label="主治医生">
              <el-select v-model="form.doctorId" placeholder="请选择医生" class="full-width" @change="handleDoctorChange">
                <el-option v-for="doc in filteredDoctors" :key="doc.id" :label="doc.realName" :value="doc.id">
                  <span style="float: left">{{ doc.realName }}</span>
                  <span style="float: right; color: #8492a6; font-size: 12px">{{ doc.title }}</span>
                </el-option>
              </el-select>
            </el-form-item>
          </div>

          <!-- 日期排班选择 -->
          <div v-if="form.doctorId" class="schedule-selector">
            <label class="section-label">预约日期与时段</label>
            <div class="date-strip">
              <div 
                v-for="day in next7Days" 
                :key="day.date" 
                class="date-item"
                :class="{ active: form.appointmentDate === day.date, disabled: !day.hasSchedule }"
                @click="day.hasSchedule && selectDate(day.date)"
              >
                <div class="day-name">{{ day.name }}</div>
                <div class="day-num">{{ day.dayNum }}</div>
                <div v-if="day.hasSchedule" class="has-schedule-dot"></div>
              </div>
            </div>

            <div v-if="form.appointmentDate" class="period-selector">
              <div 
                v-for="p in timePeriods" 
                :key="p.value"
                class="period-item"
                :class="{ 
                  active: form.appointmentTime === p.value, 
                  full: p.remaining === 0,
                  unavailable: !p.available 
                }"
                @click="p.available && p.remaining > 0 && (form.appointmentTime = p.value)"
              >
                <div class="p-info">
                  <span class="p-name">{{ p.label }}</span>
                  <span class="p-slots" v-if="p.available">余号: {{ p.remaining }}</span>
                  <span class="p-slots" v-else>未排班</span>
                </div>
                <el-icon v-if="form.appointmentTime === p.value"><Check /></el-icon>
              </div>
            </div>
          </div>

          <el-form-item label="病情描述">
            <el-input 
              v-model="form.symptoms" 
              type="textarea" 
              :rows="3" 
              placeholder="请详细描述您的症状，以便医生提前了解病情" 
              resize="none"
            />
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <div class="fee-preview" v-if="selectedDoctorFee">
            预计挂号费: <span>￥{{ selectedDoctorFee }}</span>
          </div>
          <div>
            <el-button @click="dialogVisible = false">返回</el-button>
            <el-button type="primary" :loading="submitting" @click="handleSubmit">确认提交</el-button>
          </div>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted, computed, watch } from 'vue';
import { 
  Calendar, Plus, UserFilled, Timer, Check, 
  ArrowRight, View, List, Histogram, User
} from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { getDoctorList, type DoctorInfo } from '@/api/modules/doctor';
import { appointmentApi, type Appointment } from '@/api/modules/appointment';
import { scheduleApi, type DoctorSchedule } from '@/api/modules/schedule';
import { useAuthStore } from '@/store/modules/auth';
import dayjs from 'dayjs';

const authStore = useAuthStore();
const isDoctor = computed(() => authStore.userInfo?.role === 'DOCTOR');

const activeTab = ref('list');
const loading = ref(false);
const submitting = ref(false);
const appointments = ref<Appointment[]>([]);
const doctorList = ref<DoctorInfo[]>([]);
const selectedDept = ref('');

// 统计数据
const stats = computed(() => [
  { label: '我的预约', value: appointments.value.length, icon: 'List', color: '#9a6a43', bg: 'rgba(154,106,67,0.1)' },
  { label: '待就诊', value: appointments.value.filter(a => a.status === 0).length, icon: 'Timer', color: '#c9895d', bg: 'rgba(201,137,93,0.12)' },
  { label: '医生总数', value: doctorList.value.length, icon: 'User', color: '#6f8263', bg: 'rgba(111,130,99,0.12)' },
  { label: '累计接诊', value: doctorList.value.reduce((acc, d) => acc + (d.patientCount || 0), 0), icon: 'Histogram', color: '#c87868', bg: 'rgba(200,120,104,0.12)' }
]);

const loadAppointments = async () => {
  loading.value = true;
  try {
    const res = await appointmentApi.list({ pageNum: 1, pageSize: 50 });
    appointments.value = res.records;
  } finally {
    loading.value = false;
  }
};

onMounted(async () => {
  loadAppointments();
  try {
    const res = await getDoctorList();
    doctorList.value = res;
  } catch (err) {
    console.error(err);
  }
});

// 排班逻辑相关
const schedules = ref<DoctorSchedule[]>([]);
const next7Days = ref<any[]>([]);

const generateNext7Days = () => {
  const days = [];
  const weekMap = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  for (let i = 1; i <= 7; i++) {
    const d = dayjs().add(i, 'day');
    days.push({
      date: d.format('YYYY-MM-DD'),
      dayNum: d.date(),
      name: weekMap[d.day()],
      hasSchedule: false
    });
  }
  next7Days.value = days;
};

const updateDaysWithSchedules = () => {
  next7Days.value.forEach(day => {
    day.hasSchedule = schedules.value.some(s => s.scheduleDate === day.date && s.status === 1);
  });
};

const timePeriods = ref([
  { label: '上午', value: '上午', remaining: 0, available: false },
  { label: '下午', value: '下午', remaining: 0, available: false }
]);

const updateTimePeriods = () => {
  const dateSchedules = schedules.value.filter(s => s.scheduleDate === form.appointmentDate);
  timePeriods.value.forEach(p => {
    const s = dateSchedules.find(ds => ds.timePeriod === p.value);
    if (s) {
      p.available = s.status === 1;
      p.remaining = Math.max(0, s.maxPatients - s.bookedPatients);
    } else {
      p.available = false;
      p.remaining = 0;
    }
  });
};

// 交互相关
const uniqueDepartments = computed(() => {
  return Array.from(new Set(doctorList.value.map(doc => doc.department)));
});

const filteredDoctors = computed(() => {
  if (!form.department) return doctorList.value;
  return doctorList.value.filter(doc => doc.department === form.department);
});

const filterScheduleDoctors = computed(() => {
  if (!selectedDept.value) return doctorList.value;
  return doctorList.value.filter(doc => doc.department === selectedDept.value);
});

const selectedDoctorFee = computed(() => {
  const doc = doctorList.value.find(d => d.id === form.doctorId);
  return doc?.consultationFee || 0;
});

const form = reactive<any>({
  doctorId: undefined,
  department: '',
  appointmentDate: '',
  appointmentTime: '',
  symptoms: ''
});

const dialogVisible = ref(false);

const openDialog = () => {
  Object.assign(form, { doctorId: undefined, department: '', appointmentDate: '', appointmentTime: '', symptoms: '' });
  generateNext7Days();
  dialogVisible.value = true;
};

const startBooking = (doc: DoctorInfo) => {
  openDialog();
  form.department = doc.department;
  form.doctorId = doc.id;
  handleDoctorChange();
};

const handleDepartmentChange = () => {
  form.doctorId = undefined;
  form.appointmentDate = '';
  form.appointmentTime = '';
};

const handleDoctorChange = async () => {
  if (!form.doctorId) return;
  form.appointmentDate = '';
  form.appointmentTime = '';
  const start = dayjs().add(1, 'day').format('YYYY-MM-DD');
  const end = dayjs().add(7, 'day').format('YYYY-MM-DD');
  try {
    const res = await scheduleApi.getByDoctor(form.doctorId, start, end);
    schedules.value = res;
    updateDaysWithSchedules();
  } catch (err) {
    console.error(err);
  }
};

const selectDate = (date: string) => {
  form.appointmentDate = date;
  form.appointmentTime = '';
  updateTimePeriods();
};

const handleSubmit = async () => {
  if (!form.doctorId || !form.appointmentDate || !form.appointmentTime) {
    ElMessage.warning('请选择医生和具体的就诊时段');
    return;
  }
  
  submitting.value = true;
  try {
    await appointmentApi.create(form);
    ElMessage.success({
      message: '预约挂号成功！请按时前往医院就诊。',
      duration: 5000
    });
    dialogVisible.value = false;
    loadAppointments();
  } catch (err: any) {
    // 错误处理由响应拦截器完成
  } finally {
    submitting.value = false;
  }
};

const handleCancel = async (id?: number) => {
  if (!id) return;
  try {
    await ElMessageBox.confirm('确定取消该预约吗？取消后号源将释放给其他患者。', '操作提示', { 
      type: 'warning',
      confirmButtonText: '确认取消',
      cancelButtonText: '暂不取消',
      confirmButtonClass: 'el-button--danger'
    });
    await appointmentApi.cancel(id);
    ElMessage.success('预约已取消');
    loadAppointments();
  } catch (e) { /* user cancel */ }
};

const handleComplete = async (id?: number) => {
  if (!id) return;
  await ElMessageBox.confirm('确认患者已完成此次诊疗？', '状态更新', { type: 'success' });
  await appointmentApi.complete(id);
  ElMessage.success('状态已更新为已完成');
  loadAppointments();
};

const handleDeptFilter = () => {
  // handled by computed
};

const getStatusType = (status: number) => {
  switch (status) {
    case 0: return 'primary';
    case 1: return 'success';
    case 2: return 'info';
    default: return '';
  }
};

const getStatusClass = (status: number) => {
  const map: any = { 0: 'pending', 1: 'completed', 2: 'cancelled' };
  return map[status] || 'unknown';
};

const getStatusText = (status: number) => {
  const map: any = { 0: '待就诊', 1: '已完成', 2: '已取消' };
  return map[status] || '未知';
};
</script>

<style scoped lang="scss">
.appointment-container {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;

  .header-content {
    display: flex;
    align-items: center;
    gap: 16px;

    .header-icon {
      font-size: 32px;
      color: #9a6a43;
      background: #fbf4ec;
      padding: 12px;
      border-radius: 12px;
    }

    .title-group {
      h1 {
        margin: 0;
        font-size: 24px;
        font-weight: 600;
        color: var(--el-text-color-primary);
      }
      p {
        margin: 4px 0 0;
        color: var(--el-text-color-secondary);
        font-size: 14px;
      }
    }
  }

  .create-btn {
    padding-left: 24px;
    padding-right: 24px;
    height: 44px;
    border-radius: 22px;
    border: none;
    background: linear-gradient(135deg, #9a6a43 0%, #c9895d 100%);
    box-shadow: 0 12px 28px rgba(154, 106, 67, 0.22);
  }
}

.stat-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 30px;

  .stat-card {
    background: #fff;
    padding: 20px;
    border-radius: 16px;
    display: flex;
    align-items: center;
    gap: 16px;
    border: 1px solid rgba(0,0,0,0.05);
    box-shadow: 0 2px 12px rgba(0,0,0,0.03);

    .stat-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
    }

    .stat-info {
      display: flex;
      flex-direction: column;
      .stat-value {
        font-size: 20px;
        font-weight: 700;
        color: var(--el-text-color-primary);
      }
      .stat-label {
        font-size: 13px;
        color: var(--el-text-color-secondary);
      }
    }
  }
}

.main-content {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.05);
}

.med-modern-table {
  border-radius: 8px;
  overflow: hidden;

  :deep(.el-table__header) {
    background-color: #f8f9fb;
    color: #5c6b77;
    font-weight: 600;
  }

  .table-info-cell {
    display: flex;
    flex-direction: column;
    gap: 4px;
    .dept-tag {
      font-size: 13px;
      font-weight: 600;
      color: #8a5a38;
    }
    .appointment-id {
      font-size: 12px;
      color: #909399;
      font-family: monospace;
    }
  }

  .doctor-profile {
    display: flex;
    align-items: center;
    gap: 10px;
    .doc-avatar {
      background: linear-gradient(135deg, #9a6a43 0%, #6f4b2f 100%);
      color: white;
    }
  }

  .time-cell {
    display: flex;
    align-items: center;
    gap: 8px;
    .date {
      color: #303133;
      font-weight: 500;
    }
  }

  .status-dot {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    margin-right: 6px;
    vertical-align: middle;

    &.pending { background-color: #9a6a43; }
    &.completed { background-color: #6f8263; }
    &.cancelled { background-color: #909399; }
  }

  .status-text {
    font-size: 13px;
    &.pending { color: #8a5a38; }
    &.completed { color: #6f8263; }
    &.cancelled { color: #909399; }
  }

  .action-btns {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
  }
}

/* 排班概览样式 */
.schedule-view {
  .filter-bar {
    margin-bottom: 24px;
    :deep(.el-radio-button__inner) {
      border-radius: 20px !important;
      margin-right: 8px;
      border: 1px solid #dcdfe6;
      border-left: 1px solid #dcdfe6 !important;
    }
  }
}

.doctor-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;

  .doctor-card {
    background: #fdfdfd;
    border: 1px solid rgba(0,0,0,0.06);
    border-radius: 12px;
    padding: 20px;
    transition: all 0.3s;
    &:hover {
      transform: translateY(-4px);
      box-shadow: 0 10px 25px rgba(0,0,0,0.08);
      border-color: rgba(154, 106, 67, 0.28);
    }

    .doc-card-header {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
      .doc-main-avatar {
        background: linear-gradient(135deg, #9a6a43, #d6a85c);
      }
      .doc-title-info {
        h3 { margin: 0; font-size: 18px; }
        span { font-size: 13px; color: #909399; }
      }
    }

    .doc-specialty {
      font-size: 13px;
      color: #606266;
      height: 40px;
      overflow: hidden;
      text-overflow: ellipsis;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      margin-bottom: 16px;
    }

    .doc-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 12px;
      border-top: 1px dashed #ebeef5;
      .fee {
        color: #f56c6c;
        font-weight: 700;
        font-size: 18px;
        &::before { content: '诊酬 '; font-size: 12px; color: #909399; font-weight: 400; }
      }
    }
  }
}

/* 弹窗高级样式 */
.booking-dialog-content {
  padding: 10px 0;
  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }
}

.section-label {
  display: block;
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 12px;
  color: #303133;
}

.date-strip {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 10px;
  margin-bottom: 20px;

  .date-item {
    flex: 0 0 60px;
    height: 80px;
    border-radius: 12px;
    border: 1px solid #ebeef5;
    background: #f8f9fb;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    position: relative;
    transition: all 0.2s;

    .day-name { font-size: 12px; color: #909399; }
    .day-num { font-size: 18px; font-weight: 700; margin-top: 4px; }
    
    .has-schedule-dot {
      width: 4px;
      height: 4px;
      background: #d6a85c;
      border-radius: 50%;
      position: absolute;
      bottom: 8px;
    }

    &.active {
      background: linear-gradient(135deg, #9a6a43, #c9895d);
      color: white;
      border-color: #9a6a43;
      .day-name { color: rgba(255,255,255,0.8); }
    }

    &.disabled {
      opacity: 0.5;
      cursor: not-allowed;
      &:hover { border-color: #ebeef5; transform: none; }
    }

    &:hover:not(.disabled) {
      transform: translateY(-2px);
      border-color: #9a6a43;
    }
  }
}

.period-selector {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 24px;

  .period-item {
    padding: 16px;
    border-radius: 10px;
    border: 1px solid #dcdfe6;
    display: flex;
    justify-content: space-between;
    align-items: center;
    cursor: pointer;
    transition: all 0.2s;

    .p-info {
      display: flex;
      flex-direction: column;
      .p-name { font-weight: 600; }
      .p-slots { font-size: 12px; color: #909399; margin-top: 2px; }
    }

    &.active {
      border-color: #9a6a43;
      background: rgba(154, 106, 67, 0.08);
      .p-name { color: #8a5a38; }
    }

    &.full, &.unavailable {
      opacity: 0.6;
      cursor: not-allowed;
      background: #f5f7fa;
    }
  }
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  .fee-preview {
    font-size: 14px;
    span { color: #f56c6c; font-weight: 700; font-size: 20px; margin-left: 4px; }
  }
}

.full-width { width: 100%; }

:deep(.el-button--primary) {
  --el-button-bg-color: #9a6a43;
  --el-button-border-color: #9a6a43;
  --el-button-hover-bg-color: #8a5a38;
  --el-button-hover-border-color: #8a5a38;
  --el-button-active-bg-color: #6f4b2f;
  --el-button-active-border-color: #6f4b2f;
}

:deep(.el-button--primary.is-link) {
  --el-button-text-color: #8a5a38;
  --el-button-hover-link-text-color: #6f4b2f;
  --el-button-active-color: #6f4b2f;
}

:deep(.modern-tabs) {
  .el-tabs__item {
    color: #66584b;
    font-weight: 700;

    &:hover,
    &.is-active {
      color: #8a5a38;
    }
  }

  .el-tabs__active-bar {
    background-color: #9a6a43;
  }
}

.period-tag {
  border-color: rgba(154, 106, 67, 0.36);
  background: #fffaf5;
  color: #8a5a38;
}

:deep(.el-radio-button__original-radio:checked + .el-radio-button__inner) {
  border-color: #9a6a43;
  background: #9a6a43;
  box-shadow: -1px 0 0 0 #9a6a43;
  color: #fff;
}

:deep(.el-radio-button__inner:hover) {
  color: #8a5a38;
}

// 移动端适配
@media (max-width: 768px) {
  .appointment-container {
    padding: 16px;
  }
  
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
    
    .header-content {
      .header-icon {
        font-size: 24px;
        padding: 10px;
      }
      
      .title-group {
        h1 { font-size: 18px; }
        p { font-size: 12px; }
      }
    }
    
    .create-btn {
      width: 100%;
      height: 42px;
    }
  }
  
  .stat-row {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
    
    .stat-card {
      padding: 16px;
      
      .stat-icon {
        width: 40px;
        height: 40px;
        font-size: 16px;
      }
      
      .stat-info {
        .stat-value { font-size: 18px; }
        .stat-label { font-size: 11px; }
      }
    }
  }
  
  .main-content {
    padding: 16px;
    border-radius: 12px;
    
    // 隐藏表格，使用移动端卡片布局
    .table-container {
      overflow-x: auto;
      
      :deep(.el-table) {
        min-width: 600px;
      }
    }
  }
  
  .schedule-view {
    .filter-bar {
      overflow-x: auto;
      white-space: nowrap;
      padding-bottom: 12px;
      
      :deep(.el-radio-button__inner) {
        padding: 8px 12px;
        font-size: 12px;
      }
    }
  }
  
  .doctor-cards-grid {
    grid-template-columns: 1fr;
    gap: 12px;
    
    .doctor-card {
      padding: 16px;
      
      .doc-card-header {
        gap: 12px;
        
        .doc-main-avatar {
          width: 40px !important;
          height: 40px !important;
        }
        
        .doc-title-info {
          h3 { font-size: 16px; }
          span { font-size: 12px; }
        }
      }
      
      .doc-specialty {
        font-size: 12px;
        height: 36px;
      }
      
      .doc-footer {
        .fee { font-size: 16px; }
      }
    }
  }
  
  // 弹窗移动端适配
  :deep(.premium-dialog) {
    width: 95% !important;
    max-width: 95% !important;
    margin: 0 auto;
    
    .el-dialog__body {
      padding: 16px;
    }
  }
  
  .booking-dialog-content {
    .form-grid {
      grid-template-columns: 1fr;
      gap: 12px;
    }
  }
  
  .date-strip {
    gap: 8px;
    
    .date-item {
      flex: 0 0 50px;
      height: 68px;
      border-radius: 10px;
      
      .day-name { font-size: 10px; }
      .day-num { font-size: 16px; }
    }
  }
  
  .period-selector {
    grid-template-columns: 1fr;
    gap: 10px;
    
    .period-item {
      padding: 14px;
    }
  }
  
  .dialog-footer {
    flex-direction: column;
    gap: 12px;
    
    .fee-preview {
      text-align: center;
    }
  }
}
</style>
