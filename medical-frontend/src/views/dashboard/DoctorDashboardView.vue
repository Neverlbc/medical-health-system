<template>
  <div class="doctor-dashboard">
    <!-- 核心统计图层 (升级版：清新医疗风) -->
    <div class="vital-overview-header">
      <div class="vital-banner">
        <div class="banner-grid-deco"></div>
        <div class="doctor-brief">
          <div class="brief-info">
            <el-avatar :size="64" class="doc-avatar">
              {{ (authStore.userInfo?.nickname || authStore.userInfo?.username || 'D').charAt(0) }}
            </el-avatar>
            <div class="text-group">
              <h2>{{ authStore.userInfo?.nickname || authStore.userInfo?.username }} 医生，下午好</h2>
              <p>愿您的每一次诊疗都能为患者带去希望与健康</p>
            </div>
          </div>
          <div class="live-pulse">
            <span class="pulse-dot"></span>
            <span class="status-text">系统实时在线</span>
          </div>
        </div>
        
        <div class="quick-stats-row">
          <div class="stat-capsule">
            <div class="val">{{ overview.todayAppointments }}</div>
            <div class="label">今日待诊预约</div>
            <div class="trend up">活跃较多</div>
          </div>
          <div class="stat-capsule">
            <div class="val">{{ overview.totalPatients }}</div>
            <div class="label">当前管理患者</div>
            <div class="trend">全量数据库</div>
          </div>
          <div class="stat-capsule">
            <div class="val">{{ overview.totalDiagnoses || 128 }}</div>
            <div class="label">本周门诊记录</div>
            <div class="trend up">↑ 稳步提升</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 工作台入口 -->
    <div class="workbench-section">
      <div class="section-title">
        <div class="t-line"></div>
        <h3>核心临床工作台</h3>
        <span>Clinical Workbench</span>
      </div>

      <div class="action-grid">
        <div class="action-item" @click="$router.push({ name: 'Appointments' })">
          <div class="i-circle blue"><el-icon><Calendar /></el-icon></div>
          <div class="i-info">
            <h4>就诊预约管理</h4>
            <p>规划今日诊程，处理挂号请求</p>
          </div>
        </div>

        <div class="action-item" @click="$router.push({ name: 'DoctorPatients' })">
          <div class="i-circle green"><el-icon><User /></el-icon></div>
          <div class="i-info">
            <h4>患者全量名单</h4>
            <p>查看患者分级、病历与监测状态</p>
          </div>
        </div>

        <div class="action-item" @click="$router.push({ name: 'Records' })">
          <div class="i-circle orange"><el-icon><Document /></el-icon></div>
          <div class="i-info">
            <h4>病历档案检索</h4>
            <p>调阅全生命周期电子病历档案</p>
          </div>
        </div>

        <div class="action-item" @click="$router.push({ name: 'DataAnalysis' })">
          <div class="i-circle purple"><el-icon><DataAnalysis /></el-icon></div>
          <div class="i-info">
            <h4>临床数据分析</h4>
            <p>多维趋势看板与统计决策支持</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部辅助区 -->
    <el-row :gutter="24" class="bottom-row">
      <el-col :span="16">
        <div class="notice-panel">
          <div class="panel-head">
            <span>📢 最近待办与公告</span>
            <el-button type="primary" link>查看全部</el-button>
          </div>
          <div class="todo-list">
            <div class="todo-item">
              <el-tag size="small" type="warning">紧急</el-tag>
              <span class="todo-text">患者 张三 的血压指标连续 3 天处于高位预警状态</span>
              <span class="todo-date">10:30</span>
            </div>
            <div class="todo-item">
              <el-tag size="small">提醒</el-tag>
              <span class="todo-text">新的临床随访指南已下发，请在下周一前查阅</span>
              <span class="todo-date">昨日</span>
            </div>
          </div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="quick-nav-panel">
          <div class="q-title">知识库入口</div>
          <div class="q-links">
            <div class="q-link" @click="openDoc('clinical_manual.pdf')">临床操作手册</div>
            <div class="q-link" @click="openDoc('medication_guide.pdf')">药物配伍禁忌表</div>
            <div class="q-link" @click="openDoc('imaging_guide.pdf')">医学影像调看指南</div>
          </div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/store/modules/auth';
import { Calendar, User, Document, DataAnalysis } from '@element-plus/icons-vue';
import { ref, onMounted } from 'vue';
import { getOverview, type OverviewVO } from '@/api/modules/statistics';

const authStore = useAuthStore();
const overview = ref<OverviewVO>({
  totalPatients: 0,
  todayAppointments: 0,
  totalDiagnoses: 0
});

onMounted(async () => {
  try {
    const res = await getOverview();
    overview.value = res;
  } catch (error) {
    console.error('Failed to fetch overview stats', error);
  }
});

const openDoc = (filename: string) => {
  const url = `/docs/${filename}`;
  window.open(url, '_blank');
};
</script>

<style scoped lang="scss">
.doctor-dashboard {
  max-width: 1300px;
  margin: 0 auto;
}

// 新版核心统计区
.vital-overview-header {
  margin-bottom: 80px; // 增加底部边距，给悬浮卡片留出呼吸空间
}

.vital-banner {
  background:
    radial-gradient(circle at 86% 18%, rgba(214, 168, 92, 0.2), transparent 28%),
    radial-gradient(circle at 18% 22%, rgba(111, 130, 99, 0.14), transparent 34%),
    linear-gradient(135deg, #8a5a38 0%, #c9895d 100%);
  border-radius: 28px;
  padding: 40px 48px 80px; // 底部增加留白
  position: relative;
  overflow: visible;
  color: #fff;
  box-shadow: 0 20px 40px rgba(77, 54, 36, 0.13);

  .banner-grid-deco {
    position: absolute; inset: 0; 
    background-image: radial-gradient(circle at 1.5px 1.5px, rgba(255,255,255,0.15) 1px, transparent 0);
    background-size: 24px 24px;
    z-index: 0;
  }
}

.doctor-brief {
  position: relative; z-index: 1;
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 30px;

  .brief-info {
    display: flex; align-items: center; gap: 24px;
    .doc-avatar { background: #fffaf5; color: #8a5a38; font-weight: 800; font-size: 24px; border: 4px solid rgba(255,250,245,0.35); box-shadow: 0 4px 12px rgba(77,54,36,0.14); }
    h2 { margin: 0 0 6px; font-size: 28px; font-weight: 800; color: #fff; letter-spacing: -0.5px; }
    p { margin: 0; opacity: 0.9; font-size: 16px; font-weight: 500; }
  }

  .live-pulse {
    background: rgba(255, 255, 255, 0.18); backdrop-filter: blur(12px);
    padding: 12px 20px; border-radius: 50px; display: flex; align-items: center; gap: 10px;
    border: 1px solid rgba(255,255,255,0.25);
    
    .pulse-dot {
      width: 10px; height: 10px; background: #fff; border-radius: 50%;
      box-shadow: 0 0 12px #fff; animation: pulse-white 2s infinite;
    }
    .status-text { font-size: 13px; font-weight: 700; color: #fff; letter-spacing: 0.5px; }
  }
}

.quick-stats-row {
  position: absolute; left: 48px; right: 48px; bottom: -45px; // 微调绝对定位
  display: grid; grid-template-columns: repeat(3, 1fr); gap: 32px; // 增加间距
}

.stat-capsule {
  background: #fffaf5; border-radius: 24px; padding: 28px;
  box-shadow: 0 12px 30px rgba(77,54,36,0.07); border: 1px solid #eadbca;
  display: flex; flex-direction: column; align-items: center; transition: 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  
  &:hover { transform: translateY(-8px); box-shadow: 0 20px 40px rgba(154, 106, 67, 0.14); }

  .val { font-size: 40px; font-weight: 1000; color: #2f2923; font-family: 'Inter', sans-serif; line-height: 1; margin-bottom: 10px; }
  .label { font-size: 13px; color: #9a8a7a; font-weight: 800; margin-bottom: 6px; text-transform: uppercase; letter-spacing: 1px; }
  .trend { font-size: 12px; font-weight: 700; color: #7b6b5c;
    &.up { color: #6f8263; }
  }
}

@keyframes pulse-white {
  0% { transform: scale(0.9); opacity: 0.6; }
  50% { transform: scale(1.1); opacity: 1; box-shadow: 0 0 15px #fff; }
  100% { transform: scale(0.9); opacity: 0.6; }
}

// 工作台
.workbench-section {
  margin-bottom: 40px;
}

.section-title {
  display: flex; align-items: center; gap: 12px; margin-bottom: 24px;
  .t-line { width: 4px; height: 20px; background: #9a6a43; border-radius: 4px; }
  h3 { margin: 0; font-size: 20px; font-weight: 800; color: #2f2923; }
  span { font-size: 12px; color: #9a8a7a; font-weight: 700; text-transform: uppercase; margin-top: 4px; }
}

.action-grid {
  display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px;
}

.action-item {
  background: #fffaf5; border-radius: 20px; padding: 28px; display: flex; align-items: center; gap: 24px;
  cursor: pointer; transition: 0.3s; border: 1px solid #eadbca;
  
  &:hover {
    transform: translateY(-5px); box-shadow: 0 15px 35px rgba(77,54,36,0.07); border-color: #c9895d;
    .i-circle { transform: scale(1.1); }
  }

  .i-circle {
    width: 64px; height: 64px; border-radius: 18px; display: flex; align-items: center; justify-content: center;
    font-size: 28px; transition: 0.3s;
    &.blue { background: #fbf4ec; color: #9a6a43; }
    &.green { background: #eef4ea; color: #6f8263; }
    &.orange { background: #fff4ea; color: #c9895d; }
    &.purple { background: #fbefed; color: #9b6a68; }
  }

  .i-info {
    h4 { margin: 0 0 6px; font-size: 17px; color: #2f2923; font-weight: 700; }
    p { margin: 0; font-size: 14px; color: #7b6b5c; }
  }
}

// 底部辅助
.notice-panel {
  background: #fffaf5; border-radius: 20px; border: 1px solid #eadbca; padding: 24px; height: 260px;
  .panel-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; font-weight: 800; color: #2f2923; }
}

.todo-list {
  display: flex; flex-direction: column; gap: 12px;
}
.todo-item {
  display: flex; align-items: center; gap: 12px; padding: 12px; border-radius: 12px; background: #f6efe6;
  .todo-text { flex: 1; font-size: 14px; color: #66584b; font-weight: 500; }
  .todo-date { font-size: 12px; color: #9a8a7a; }
}

.quick-nav-panel {
  background: linear-gradient(135deg, #7b5032, #c9895d); border-radius: 20px; padding: 24px; height: 260px; color: #fffaf5;
  .q-title { font-weight: 800; margin-bottom: 20px; font-size: 16px; }
}
.q-links {
  display: flex; flex-direction: column; gap: 10px;
}
.q-link {
  background: rgba(255,255,255,0.1); padding: 12px 16px; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; transition: 0.2s;
  &:hover { background: rgba(255,255,255,0.2); transform: translateX(5px); }
}

@media (max-width: 1000px) {
  .action-grid { grid-template-columns: 1fr; }
}

// 移动端适配
@media (max-width: 768px) {
  .doctor-dashboard {
    padding: 0 12px;
  }
  
  .vital-overview-header .vital-banner {
    padding: 20px 16px;
    border-radius: 16px;
    margin: 0;
  }
  
  .doctor-brief {
    flex-direction: column;
    gap: 16px;
    
    .brief-info {
      flex-direction: column;
      text-align: center;
      gap: 12px;
      
      .text-group {
        h2 { font-size: 16px; line-height: 1.4; }
        p { font-size: 11px; }
      }
    }
    
    .doc-avatar {
      width: 48px !important;
      height: 48px !important;
    }
    
    .live-pulse {
      justify-content: center;
    }
  }
  
  .quick-stats-row {
    flex-direction: row;
    flex-wrap: nowrap;
    gap: 8px;
    margin-top: 20px;
    overflow-x: auto;
    padding-bottom: 8px;
    
    .stat-capsule {
      padding: 12px 10px;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      text-align: center;
      min-width: 100px;
      flex: 1;
      
      .val {
        font-size: 24px;
        order: 1;
        margin-bottom: 4px;
      }
      
      .label {
        margin: 0;
        order: 2;
        font-size: 11px;
        white-space: nowrap;
      }
      
      .trend {
        order: 3;
        margin-left: 0;
        margin-top: 4px;
        font-size: 9px;
      }
    }
  }
  
  .workbench-section {
    padding: 0;
    margin-top: 20px;
    
    .section-title {
      flex-wrap: wrap;
      gap: 8px;
      padding: 0 4px;
      
      h3 { font-size: 16px; }
      span { font-size: 10px; }
    }
  }
  
  .action-grid {
    grid-template-columns: 1fr !important;
    gap: 10px;
    padding: 0 4px;
  }
  
  .action-item {
    padding: 16px;
    flex-direction: row;
    gap: 14px;
    border-radius: 14px;
    
    .i-circle {
      width: 44px;
      height: 44px;
      font-size: 20px;
      border-radius: 12px;
      flex-shrink: 0;
    }
    
    .i-info {
      text-align: left;
      flex: 1;
      
      h4 { font-size: 14px; margin-bottom: 4px; }
      p { font-size: 12px; line-height: 1.4; }
    }
  }
  
  .notice-panel,
  .quick-nav-panel {
    height: auto;
    min-height: 180px;
    margin: 12px 4px;
    border-radius: 14px;
    padding: 16px;
  }
}
</style>
