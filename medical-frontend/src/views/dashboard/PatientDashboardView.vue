<template>
  <div class="dashboard-container">
    <!-- 欢迎横幅 (升级版) -->
    <div class="welcome-banner">
      <div class="banner-grid-overlay"></div>
      <div class="banner-content">
        <div class="user-greeting">
          <span class="greeting-tag">HEALTH MONITOR</span>
          <h2>欢迎回来，{{ authStore.userInfo?.nickname || authStore.userInfo?.username }} 👋</h2>
          <p>今天是 {{ currentTimestamp }}，祝您身体健康，心情愉快！</p>
        </div>
        <div class="banner-stats">
          <div class="mini-stat">
            <div class="stat-value">36.5℃</div>
            <div class="stat-label">最新体温</div>
          </div>
          <div class="divider"></div>
          <div class="mini-stat">
            <div class="stat-value">72</div>
            <div class="stat-label">静息心率</div>
          </div>
        </div>
      </div>
      <div class="banner-deco">
        <div class="floating-cell"></div>
      </div>
    </div>

    <!-- 核心功能卡片 -->
    <div class="section-header">
      <h3 class="title">快捷服务中心</h3>
      <span class="subtitle">Quick Access Services</span>
    </div>
    <div class="service-grid">
      <div class="service-card blue" @click="$router.push({ name: 'HealthData' })">
        <div class="card-icon"><el-icon><DataLine /></el-icon></div>
        <div class="card-info">
          <h4>健康自主监测</h4>
          <p>多维数据图表分析</p>
        </div>
        <el-icon class="arrow-icon"><ArrowRight /></el-icon>
      </div>
      
      <div class="service-card green" @click="$router.push({ name: 'AIConsultation' })">
        <div class="card-icon"><el-icon><ChatDotRound /></el-icon></div>
        <div class="card-info">
          <h4>AI 智能助手</h4>
          <p>24小时全天候问询</p>
        </div>
        <el-icon class="arrow-icon"><ArrowRight /></el-icon>
      </div>

      <div class="service-card orange" @click="$router.push({ name: 'Appointments' })">
        <div class="card-icon"><el-icon><Calendar /></el-icon></div>
        <div class="card-info">
          <h4>专家预约挂号</h4>
          <p>精准选取门诊号源</p>
        </div>
        <el-icon class="arrow-icon"><ArrowRight /></el-icon>
      </div>

      <div class="service-card purple" @click="$router.push({ name: 'FullRecordDetail', params: { patientId: authStore.userInfo?.id } })">
        <div class="card-icon"><el-icon><Document /></el-icon></div>
        <div class="card-info">
          <h4>全时健康档案</h4>
          <p>终身医疗记录管理</p>
        </div>
        <el-icon class="arrow-icon"><ArrowRight /></el-icon>
      </div>
    </div>

    <!-- 二级卡片区 -->
    <el-row :gutter="24" class="content-row">
      <!-- 健康预警 -->
      <el-col :span="24">
        <div class="med-panel">
          <div class="panel-header">
            <div class="p-title">
              <el-icon><WarningFilled /></el-icon>
              <span>健康预警提醒</span>
            </div>
            <el-button type="primary" link :icon="Refresh" @click="fetchHealthAlerts">动态更新</el-button>
          </div>
          
          <div class="panel-body" v-loading="alertLoading">
            <div v-if="abnormalRecords.length === 0" class="empty-state">
              <div class="check-circle"><el-icon><Check /></el-icon></div>
              <p>指标状况良好，暂无警报</p>
            </div>
            <div v-else class="alert-modern-list">
              <div v-for="record in abnormalRecords" :key="record.id" class="alert-item" :class="getAlertType(record.status)">
                <div class="item-icon">!</div>
                <div class="item-content">
                  <div class="item-top">
                    <span class="item-label">{{ getAlertTitle(record) }}</span>
                    <span class="item-time">{{ formatMeasureTime(record.measureTime) }}</span>
                  </div>
                  <div class="item-val">{{ getAlertDescription(record) }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-col>

    </el-row>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/store/modules/auth';
import {
  DataLine, ChatDotRound, Calendar, Document, Refresh,
  WarningFilled, Check, ArrowRight
} from '@element-plus/icons-vue';
import { ref, onMounted, computed } from 'vue';
import { getHealthDataPage, type HealthData } from '@/api/modules/health';

const authStore = useAuthStore();
const alertLoading = ref(false);
const abnormalRecords = ref<HealthData[]>([]);

const currentTimestamp = computed(() => {
  const now = new Date();
  return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日`;
});

const fetchHealthAlerts = async () => {
  alertLoading.value = true;
  try {
    const res = await getHealthDataPage({ current: 1, size: 20 });
    if (res && res.records) {
      abnormalRecords.value = res.records
        .filter(record => record.status && record.status > 0)
        .sort((a, b) => (b.status || 0) - (a.status || 0))
        .slice(0, 4);
    }
  } catch (error) {
    console.error(error);
  } finally {
    alertLoading.value = false;
  }
};

const getAlertType = (status?: number) => {
  if (!status) return 'low';
  if (status >= 4) return 'danger';
  if (status >= 2) return 'warning';
  return 'low';
};

const getAlertTitle = (record: HealthData) => {
  const typeNames: Record<string, string> = {
    'BLOOD_PRESSURE': '血压指标',
    'BLOOD_SUGAR': '血糖指数',
    'HEART_RATE': '静息心率',
    'TEMPERATURE': '日常体温',
    'WEIGHT': '体重监测'
  };
  return typeNames[record.dataType] || '健康数据';
};

const getAlertDescription = (record: HealthData) => {
  let value = '';
  switch (record.dataType) {
    case 'BLOOD_PRESSURE': value = `${record.systolicPressure}/${record.diastolicPressure} mmHg`; break;
    case 'BLOOD_SUGAR': value = `${record.bloodSugar} mmol/L`; break;
    case 'HEART_RATE': value = `${record.heartRate} bpm`; break;
    case 'TEMPERATURE': value = `${record.temperature} ℃`; break;
    case 'WEIGHT': value = `${record.weight} kg`; break;
  }
  return `实测值 ${value}，建议咨询医师`;
};

const formatMeasureTime = (time: string) => {
  const date = new Date(time);
  return `${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${String(date.getMinutes()).padStart(2, '0')}`;
};

onMounted(() => {
  fetchHealthAlerts();
});
</script>

<style scoped lang="scss">
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
}

// 欢迎横幅
.welcome-banner {
  height: 200px;
  background: linear-gradient(135deg, #8a5a38 0%, #c9895d 100%);
  border-radius: 24px;
  position: relative;
  overflow: hidden;
  padding: 40px;
  display: flex;
  align-items: center;
  color: #fff;
  margin-bottom: 40px;
  box-shadow: 0 20px 40px rgba(77, 54, 36, 0.13);

  .banner-grid-overlay {
    position: absolute;
    inset: 0;
    background-image: radial-gradient(circle at 2px 2px, rgba(255,255,255,0.1) 1px, transparent 0);
    background-size: 24px 24px;
  }

  .banner-content {
    position: relative;
    z-index: 1;
    display: flex;
    justify-content: space-between;
    width: 100%;
    align-items: center;
  }

  .user-greeting {
    .greeting-tag {
      background: rgba(255, 255, 255, 0.2);
      padding: 4px 12px;
      border-radius: 50px;
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 1px;
      margin-bottom: 12px;
      display: inline-block;
    }
    h2 { margin: 0 0 8px; font-size: 28px; font-weight: 800; }
    p { margin: 0; opacity: 0.85; font-size: 15px; }
  }

  .banner-stats {
    display: flex;
    align-items: center;
    gap: 30px;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    padding: 15px 30px;
    border-radius: 20px;
    border: 1px solid rgba(255, 255, 255, 0.2);

    .mini-stat {
      text-align: center;
      .stat-value { font-size: 24px; font-weight: 800; }
      .stat-label { font-size: 12px; opacity: 0.8; margin-top: 2px; }
    }
    .divider { width: 1px; height: 30px; background: rgba(255, 255, 255, 0.2); }
  }
}

// 标题
.section-header {
  margin-bottom: 24px;
  .title { font-size: 20px; font-weight: 800; color: #1a1a1a; margin: 0; display: inline-block; }
  .subtitle { font-size: 12px; color: #bfbfbf; font-weight: 700; margin-left: 12px; text-transform: uppercase; letter-spacing: 1px; }
}

// 快捷卡片
.service-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
  margin-bottom: 40px;
}

.service-card {
  background: #fff;
  border-radius: 20px;
  padding: 24px;
  display: flex;
  align-items: center;
  position: relative;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid #f0f0f0;

  &:hover {
    transform: translateY(-8px);
    box-shadow: 0 15px 30px rgba(0, 0, 0, 0.05);
    border-color: var(--theme-color);
    
    .arrow-icon { opacity: 1; transform: translateX(0); }
  }

  &.blue { --theme-color: #9a6a43; .card-icon { background: #fbf4ec; color: #9a6a43; } }
  &.green { --theme-color: #52c41a; .card-icon { background: #f6ffed; color: #52c41a; } }
  &.orange { --theme-color: #fa8c16; .card-icon { background: #fff7e6; color: #fa8c16; } }
  &.purple { --theme-color: #722ed1; .card-icon { background: #f9f0ff; color: #722ed1; } }

  .card-icon {
    width: 52px; height: 52px; border-radius: 16px; 
    display: flex; align-items: center; justify-content: center;
    font-size: 24px; margin-right: 16px;
  }

  .card-info {
    h4 { margin: 0 0 4px; font-size: 16px; color: #1a1a1a; }
    p { margin: 0; font-size: 13px; color: #8c8c8c; }
  }

  .arrow-icon {
    position: absolute; right: 20px; opacity: 0; 
    transform: translateX(-10px); transition: 0.3s;
    color: var(--theme-color); font-size: 18px;
  }
}

// 通用面板
.med-panel {
  background: #fff; border-radius: 24px; border: 1px solid #f0f0f0; height: 400px;
  display: flex; flex-direction: column; overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.02);

  .panel-header {
    padding: 24px 24px 0; display: flex; justify-content: space-between; align-items: center;
    .p-title {
      display: flex; align-items: center; gap: 10px; font-weight: 800; font-size: 17px; color: #1a1a1a;
      .el-icon { color: #9a6a43; font-size: 20px; }
    }
  }

  .panel-body { flex: 1; padding: 24px; overflow-y: auto; }
}

// 警报列表
.alert-modern-list {
  display: flex; flex-direction: column; gap: 12px;
}
.alert-item {
  display: flex; padding: 16px; border-radius: 16px; gap: 16px;
  &.danger { background: #fff1f0; border-left: 5px solid #ff4d4f; .item-icon { color: #ff4d4f; } }
  &.warning { background: #fff7e6; border-left: 5px solid #faad14; .item-icon { color: #faad14; } }
  &.low { background: #fbf4ec; border-left: 5px solid #9a6a43; .item-icon { color: #9a6a43; } }

  .item-icon { font-weight: 900; font-size: 20px; }
  .item-content { flex: 1; }
  .item-top { display: flex; justify-content: space-between; margin-bottom: 4px; }
  .item-label { font-weight: 700; color: #1a1a1a; font-size: 14px; }
  .item-time { font-size: 12px; color: #8c8c8c; }
  .item-val { font-size: 13px; color: #595959; }
}

.empty-state {
  height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #bfbfbf;
  .check-circle { width: 60px; height: 60px; border-radius: 50%; background: #f6ffed; color: #52c41a; display: flex; align-items: center; justify-content: center; font-size: 30px; margin-bottom: 16px; }
}

@media (max-width: 1100px) {
  .service-grid { grid-template-columns: repeat(2, 1fr); }
}

// 移动端适配
@media (max-width: 768px) {
  .dashboard-container {
    padding: 0;
  }
  
  .welcome-banner {
    border-radius: 16px;
    padding: 20px;
    margin: 0 0 20px;
    min-height: auto;
    
    .banner-content {
      flex-direction: column;
      gap: 20px;
    }
    
    .user-greeting {
      text-align: center;
      
      h2 { font-size: 18px; }
      p { font-size: 12px; }
      
      .greeting-tag {
        font-size: 10px;
        padding: 4px 10px;
      }
    }
    
    .banner-stats {
      justify-content: center;
      gap: 24px;
      
      .mini-stat {
        text-align: center;
        
        .stat-value { font-size: 22px; }
        .stat-label { font-size: 11px; }
      }
      
      .divider {
        height: 30px;
      }
    }
    
    .banner-deco {
      display: none;
    }
  }
  
  .section-header {
    padding: 0 16px;
    
    .title { font-size: 18px; }
    .subtitle { font-size: 11px; }
  }
  
  .service-grid {
    grid-template-columns: 1fr !important;
    gap: 12px;
    padding: 0 16px;
  }
  
  .service-card {
    padding: 16px;
    border-radius: 16px;
    
    .card-icon {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      font-size: 22px;
    }
    
    .card-info {
      h4 { font-size: 15px; }
      p { font-size: 12px; }
    }
  }
  
  .health-panels {
    flex-direction: column;
    gap: 16px;
    padding: 0 16px;
  }
  
  .health-panel {
    border-radius: 16px;
    
    .panel-header {
      padding: 16px;
      
      h3 { font-size: 15px; }
    }
    
    .panel-body {
      padding: 16px;
    }
  }
  
  .alert-item {
    padding: 12px;
    border-radius: 12px;
    gap: 12px;
    
    .item-label { font-size: 13px; }
    .item-val { font-size: 12px; }
  }
  
}

/* 简约高级版患者首页覆盖 */
.dashboard-container {
  max-width: 1480px;
}

.welcome-banner {
  min-height: 210px;
  height: auto;
  margin-bottom: 36px;
  padding: 38px 44px;
  border: 1px solid #e5e7eb;
  border-radius: 28px;
  background:
    radial-gradient(circle at 88% 18%, rgba(111, 130, 99, 0.12), transparent 28%),
    radial-gradient(circle at 16% 20%, rgba(154, 106, 67, 0.07), transparent 34%),
    linear-gradient(135deg, #ffffff, #f8fafc);
  color: #2f2923;
  box-shadow: 0 24px 70px rgba(15, 23, 42, 0.06);

  .banner-grid-overlay {
    opacity: 0.5;
    background-image: radial-gradient(circle at 2px 2px, rgba(100, 116, 139, 0.08) 1px, transparent 0);
    background-size: 28px 28px;
  }

  .user-greeting {
    .greeting-tag {
      padding: 6px 12px;
      background: #f7f3ef;
      color: #8a5a38;
      border: 1px solid rgba(154, 106, 67, 0.13);
      border-radius: 999px;
      letter-spacing: 1.4px;
    }

    h2 {
      margin-top: 14px;
      color: #2f2923;
      font-size: 32px;
      letter-spacing: -0.8px;
    }

    p {
      color: #7b6b5c;
      opacity: 1;
      font-size: 15px;
    }
  }

  .banner-stats {
    min-width: 280px;
    gap: 24px;
    padding: 18px 28px;
    border: 1px solid #e5e7eb;
    border-radius: 22px;
    background: #fff;
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.9), 0 18px 36px rgba(15, 23, 42, 0.06);

    .mini-stat {
      .stat-value {
        color: #2f2923;
        font-size: 28px;
      }

      .stat-label {
        color: #7b6b5c;
        opacity: 1;
      }
    }

    .divider {
      background: #e5e7eb;
    }
  }
}

.section-header {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 18px;

  .title {
    color: #2f2923;
    font-size: 22px;
    letter-spacing: -0.3px;
  }

  .subtitle {
    color: #9a8a7a;
    font-size: 11px;
    letter-spacing: 1.4px;
  }
}

.service-grid {
  gap: 20px;
  margin-bottom: 36px;
}

.service-card {
  min-height: 112px;
  padding: 24px 26px;
  border: 1px solid #e5e7eb;
  border-radius: 22px;
  background: #fff;
  box-shadow: 0 16px 40px rgba(15, 23, 42, 0.045);
  backdrop-filter: blur(14px);

  &:hover {
    transform: translateY(-4px);
    border-color: rgba(154, 106, 67, 0.24);
    box-shadow: 0 22px 52px rgba(15, 23, 42, 0.08);
  }

  &.blue { --theme-color: #9a6a43; .card-icon { background: #f7f3ef; color: #9a6a43; } }
  &.green { --theme-color: #6f8263; .card-icon { background: #eef4ea; color: #6f8263; } }
  &.orange { --theme-color: #c9895d; .card-icon { background: #fff4ea; color: #c9895d; } }
  &.purple { --theme-color: #9b6a68; .card-icon { background: #fbefed; color: #9b6a68; } }

  .card-icon {
    width: 56px;
    height: 56px;
    border-radius: 18px;
    margin-right: 18px;
  }

  .card-info {
    h4 {
      color: #2f2923;
      font-size: 17px;
      letter-spacing: -0.2px;
    }

    p {
      color: #7b6b5c;
      font-size: 13px;
    }
  }
}

.content-row {
  :deep(.el-col) {
    margin-bottom: 24px;
  }
}

.med-panel {
  height: 390px;
  border: 1px solid #e5e7eb;
  border-radius: 24px;
  background: #fff;
  box-shadow: 0 18px 46px rgba(15, 23, 42, 0.05);
  backdrop-filter: blur(14px);

  .panel-header {
    padding: 26px 28px 0;

    .p-title {
      color: #2f2923;
      font-size: 18px;
      letter-spacing: -0.2px;

      .el-icon {
        color: #9a6a43;
      }
    }
  }

  .panel-body {
    padding: 24px 28px 28px;
  }
}

.alert-modern-list {
  gap: 14px;
}

.alert-item {
  padding: 18px 20px;
  border-left: 0;
  border-radius: 18px;

  &.danger {
    background: #fff5f5;
    box-shadow: inset 4px 0 0 #ef4444;
  }

  &.warning {
    background: #fffbeb;
    box-shadow: inset 4px 0 0 #f59e0b;
  }

  &.low {
    background: #f8fafc;
    box-shadow: inset 4px 0 0 #9a6a43;

    .item-icon {
      color: #9a6a43;
    }
  }

  .item-label {
    color: #2f2923;
  }

  .item-val {
    color: #66584b;
  }
}

.empty-state {
  color: #9a8a7a;

  .check-circle {
    background: #f0fdf4;
    color: #16a34a;
  }
}

@media (max-width: 1100px) {
  .content-row {
    :deep(.el-col) {
      max-width: 100%;
      flex: 0 0 100%;
    }
  }

  .med-panel {
    height: auto;
    min-height: 320px;
  }
}

@media (max-width: 768px) {
  .welcome-banner {
    padding: 24px;
    border-radius: 22px;

    .user-greeting {
      text-align: left;

      h2 {
        font-size: 24px;
      }
    }

    .banner-stats {
      width: 100%;
      min-width: 0;
    }
  }

  .section-header,
  .service-grid {
    padding: 0;
  }

  .service-card {
    min-height: 96px;
    padding: 18px;
  }

  .med-panel {
    border-radius: 20px;

    .panel-header {
      padding: 20px 20px 0;
    }

    .panel-body {
      padding: 20px;
    }
  }
}
</style>
