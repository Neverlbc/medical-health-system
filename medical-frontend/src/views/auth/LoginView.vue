<template>
  <div class="med-login-root" @mousemove="handleMouseMove">
    <!-- 背景 Canvas 神经元层 -->
    <canvas ref="particleCanvas" class="bg-canvas"></canvas>

    <!-- 有机生物细胞背景 (Bio-Cells) -->
    <div class="bio-cells">
      <div class="cell cell--1"></div>
      <div class="cell cell--2"></div>
      <div class="cell cell--3"></div>
    </div>

    <!-- 医疗辅助视觉层 -->
    <div class="med-visual-layer">
      <!-- 坐标网格 -->
      <div class="med-grid"></div>
      
      <!-- 心电图波形 -->
      <div class="med-ecg-container">
        <svg class="med-ecg-svg" viewBox="0 0 1200 200" preserveAspectRatio="none">
          <path class="med-ecg-line" d="M0,100 L150,100 L170,80 L190,120 L210,100 L350,100 L370,40 L390,160 L410,100 L550,100 L570,85 L590,115 L610,100 L750,100 L770,20 L790,180 L810,100 L950,100 L970,80 L990,120 L1010,100 L1200,100" />
        </svg>
      </div>

      <!-- DNA 双螺旋装饰 (左右对称) -->
      <div class="dna-aside dna-aside--left">
        <div class="dna-double-helix">
          <div v-for="i in 18" :key="i" class="dna-segment" :style="`--off: ${i*0.2}s; --top: ${i*5}%;` ">
            <div class="dot dot--a"></div>
            <div class="line"></div>
            <div class="dot dot--b"></div>
          </div>
        </div>
      </div>

      <div class="dna-aside dna-aside--right">
        <div class="dna-double-helix">
          <div v-for="i in 18" :key="i" class="dna-segment" :style="`--off: ${i*0.2}s; --top: ${i*5}%;` ">
            <div class="dot dot--a"></div>
            <div class="line"></div>
            <div class="dot dot--b"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- 登录面板 -->
    <main class="login-panel">
      <div class="card-container" v-show="isMounted">
        <div class="card-glass-effect"></div>
        
        <header class="panel-header">
          <div class="brand-logo">
            <svg viewBox="0 0 100 100" class="hospital-cross hospital-cross--pulse">
              <rect x="40" y="20" width="20" height="60" rx="4" fill="#c87868" />
              <rect x="20" y="40" width="60" height="20" rx="4" fill="#c87868" />
              <circle cx="50" cy="50" r="45" fill="none" stroke="rgba(200, 120, 104, 0.22)" stroke-width="2" />
            </svg>
          </div>
          <h1 class="title">智慧医疗健康管理系统</h1>
          <p class="tagline">SMART MEDICAL HEALTH</p>
        </header>

        <el-form :model="form" :rules="rules" ref="formRef" class="login-form" label-position="left" label-width="70px" hide-required-asterisk>
          <el-form-item prop="username">
            <template #label><span class="form-label">账号</span></template>
            <el-input v-model="form.username" placeholder="请输入手机号/工号" class="med-input">
              <template #prefix><el-icon><User /></el-icon></template>
            </el-input>
          </el-form-item>

          <el-form-item prop="password">
            <template #label><span class="form-label">密码</span></template>
            <el-input v-model="form.password" type="password" placeholder="请输入登录密码" show-password class="med-input" @keyup.enter="handleLogin">
              <template #prefix><el-icon><Lock /></el-icon></template>
            </el-input>
          </el-form-item>

          <div class="form-actions">
            <el-checkbox v-model="rememberMe">保持登录状态</el-checkbox>
          </div>

          <button type="button" class="btn-submit" :disabled="loading" @click="handleLogin">
            <span v-if="!loading">授 权 登 录</span>
            <span v-else><el-icon class="is-loading"><Loading /></el-icon> 数据核验中...</span>
          </button>

          <footer class="panel-footer">
            <span>暂无系统访问权限？</span>
            <span class="link-action" @click="goRegister">立即注册申请</span>
          </footer>
        </el-form>
      </div>
    </main>

    <!-- 底部版权声明 -->
    <div class="page-info-deco">
       Copyright © 2024 智慧医疗健康管理系统 · 让医疗更智能，让健康更触手可及
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted, onUnmounted } from 'vue';
import type { FormInstance, FormRules } from 'element-plus';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '@/store/modules/auth';
import { User, Lock, Loading } from '@element-plus/icons-vue';

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();

const isMounted = ref(false);
const loading = ref(false);
const rememberMe = ref(true);
const formRef = ref<FormInstance>();
const particleCanvas = ref<HTMLCanvasElement | null>(null);

const form = reactive({
  username: 'patient1',
  password: 'test123'
});

const rules: FormRules<typeof form> = {
  username: [{ required: true, message: '请提供认证号', trigger: 'blur' }],
  password: [{ required: true, message: '请提供安全码', trigger: 'blur' }]
};

// 交互粒子与神经连接逻辑
let rafId: number;
const mousePos = { x: -1000, y: -1000 };

const handleMouseMove = (e: MouseEvent) => {
  mousePos.x = e.clientX;
  mousePos.y = e.clientY;
};

const drawNodes = () => {
  const canvas = particleCanvas.value;
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const updateSize = () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  };
  window.addEventListener('resize', updateSize);
  updateSize();

  const nodes: any[] = [];
  const nodeCount = 70;

  for (let i = 0; i < nodeCount; i++) {
    nodes.push({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      vx: (Math.random() - 0.5) * 0.4,
      vy: (Math.random() - 0.5) * 0.4,
      r: Math.random() * 1.5 + 0.5,
      pulse: Math.random() * 10
    });
  }

  const render = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    nodes.forEach((node, i) => {
      node.x += node.vx;
      node.y += node.vy;
      node.pulse += 0.05;

      if (node.x < 0 || node.x > canvas.width) node.vx *= -1;
      if (node.y < 0 || node.y > canvas.height) node.vy *= -1;

      // 鼠标吸引
      const dx = mousePos.x - node.x;
      const dy = mousePos.y - node.y;
      const d = Math.sqrt(dx*dx + dy*dy);
      if (d < 200) {
        node.x += dx * 0.015;
        node.y += dy * 0.015;
      }

      // 绘制连线 (神经纤桥)
      for (let j = i + 1; j < nodes.length; j++) {
        const target = nodes[j];
        const ndx = node.x - target.x;
        const ndy = node.y - target.y;
        const dist = Math.sqrt(ndx*ndx + ndy*ndy);
        
        if (dist < 120) {
          ctx.beginPath();
          ctx.lineWidth = 0.5;
          ctx.strokeStyle = `rgba(112, 132, 101, ${0.1 * (1 - dist/120)})`;
          ctx.moveTo(node.x, node.y);
          ctx.lineTo(target.x, target.y);
          ctx.stroke();

          // 随机脉冲光点
          if (Math.sin(node.pulse) > 0.98) {
            const ratio = (Math.sin(node.pulse * 2) + 1) / 2;
            const px = node.x + (target.x - node.x) * ratio;
            const py = node.y + (target.y - node.y) * ratio;
            ctx.beginPath();
            ctx.fillStyle = 'rgba(214, 168, 92, 0.34)';
            ctx.arc(px, py, 1.2, 0, Math.PI * 2);
            ctx.fill();
          }
        }
      }

      // 绘制核心点
      ctx.beginPath();
      ctx.fillStyle = `rgba(154, 106, 67, ${0.15 + Math.sin(node.pulse)*0.05})`;
      ctx.arc(node.x, node.y, node.r, 0, Math.PI * 2);
      ctx.fill();
    });

    rafId = requestAnimationFrame(render);
  };
  render();
};

onMounted(() => {
  isMounted.value = true;
  drawNodes();
});

onUnmounted(() => {
  cancelAnimationFrame(rafId);
});

const handleLogin = async () => {
  if (!formRef.value) return;
  await formRef.value.validate(async (valid) => {
    if (!valid) return;
    loading.value = true;
    try {
      await authStore.loginAction({ ...form });
      const redirect = (route.query.redirect as string) || '';
      if (redirect) {
        router.replace(redirect);
      } else {
        const role = authStore.userInfo?.role;
        if (role === 'PATIENT') {
          router.replace({ name: 'PatientDashboard' });
        } else {
          router.replace({ name: 'DoctorDashboard' });
        }
      }
    } finally {
      loading.value = false;
    }
  });
};

const goRegister = () => {
  const redirect = (route.query.redirect as string) || undefined;
  router.push({ name: 'Register', query: redirect ? { redirect } : undefined });
};
</script>

<style scoped lang="scss">
.med-login-root {
  min-height: 100vh;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  font-family: 'PingFang SC', 'Source Han Sans CN', 'Microsoft YaHei', sans-serif;
  color: #2f2923;
}

.med-login-root::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: 1;
  pointer-events: none;
  background:
    linear-gradient(90deg, rgba(170, 147, 122, 0.035) 0 1px, transparent 1px 100%),
    linear-gradient(0deg, rgba(170, 147, 122, 0.035) 0 1px, transparent 1px 100%),
    radial-gradient(circle at 50% 50%, transparent 0 36%, rgba(255, 255, 255, 0.74) 72%);
  background-size: 92px 92px, 92px 92px, 100% 100%;
  mask-image: linear-gradient(90deg, transparent, #000 16%, #000 84%, transparent);
}

.med-login-root::after {
  content: '';
  position: absolute;
  inset: 0;
  z-index: 3;
  pointer-events: none;
  background: none;
}

.bg-canvas {
  position: absolute;
  inset: 0;
  z-index: 2;
  pointer-events: none;
  opacity: 0.18;
}

.bio-cells {
  display: none;

  .cell {
    position: absolute;
    border-radius: 50%;
    filter: blur(96px);
    opacity: 0.12;
    animation: cell-float 28s ease-in-out infinite alternate;

    &--1 {
      width: 460px;
      height: 460px;
      background: linear-gradient(135deg, #d6a85c, #f4dac0);
      top: -18%;
      left: -9%;
    }

    &--2 {
      width: 420px;
      height: 420px;
      background: linear-gradient(135deg, #6f8263, #d9e4cf);
      right: -10%;
      bottom: -12%;
      animation-duration: 38s;
    }

    &--3 {
      width: 240px;
      height: 240px;
      background: linear-gradient(135deg, #c9895d, #fffaf5);
      top: 27%;
      right: 22%;
      animation-duration: 24s;
    }
  }
}

@keyframes cell-float {
  from { transform: translate3d(0, 0, 0) scale(1); }
  to { transform: translate3d(56px, 36px, 0) scale(1.12); }
}

.med-visual-layer {
  position: absolute;
  inset: 0;
  z-index: 4;
  pointer-events: none;

  .med-grid {
    position: absolute;
    inset: 0;
    background-image:
      linear-gradient(rgba(154, 106, 67, 0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(154, 106, 67, 0.03) 1px, transparent 1px);
    background-size: 96px 96px;
    opacity: 0.34;
  }

  .med-ecg-container {
    position: absolute;
    bottom: -18px;
    left: -10%;
    width: 220%;
    height: 330px;
    opacity: 0.055;
    animation: ecg-container-pulse 4.5s ease-in-out infinite;

    .med-ecg-svg {
      width: 100%;
      height: 100%;
    }

    .med-ecg-line {
      fill: none;
      stroke: #9a6a43;
      stroke-width: 1.4;
      stroke-dasharray: 2000;
      stroke-dashoffset: 2000;
      filter: drop-shadow(0 0 10px rgba(154, 106, 67, 0.36));
      animation: svg-scan 7s linear infinite;
    }
  }

  .dna-aside {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 52px;
    height: 68%;
    opacity: 0.08;

    &--left { left: 6.5%; }
    &--right { right: 6.5%; }

    .dna-segment {
      position: absolute;
      top: var(--top);
      width: 100%;
      height: 10px;
      display: flex;
      align-items: center;
      justify-content: center;

      .dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #9a6a43;
        box-shadow: 0 0 14px rgba(154, 106, 67, 0.44);
        animation: helix-dot 3s ease-in-out infinite alternate;
        animation-delay: var(--off);

        &--b {
          background: #6f8263;
          animation-delay: calc(var(--off) - 1.5s);
        }
      }

      .line {
        flex: 1;
        height: 1.5px;
        margin: 0 -4px;
        background: linear-gradient(90deg, rgba(154, 106, 67, 0.12), rgba(154, 106, 67, 0.38), rgba(111, 130, 99, 0.16));
        animation: helix-line 3s ease-in-out infinite alternate;
        animation-delay: var(--off);
      }
    }
  }
}

@keyframes svg-scan {
  0% { stroke-dashoffset: 2000; }
  100% { stroke-dashoffset: 0; }
}

@keyframes ecg-container-pulse {
  0%, 100% { opacity: 0.12; transform: scaleY(1); }
  50% { opacity: 0.24; transform: scaleY(1.05); }
}

@keyframes helix-dot {
  0% { transform: translateX(-27px) scale(0.82); opacity: 0.42; }
  100% { transform: translateX(27px) scale(1.18); opacity: 1; box-shadow: 0 0 18px rgba(154, 106, 67, 0.58); }
}

@keyframes helix-line {
  0%, 100% { transform: scaleX(1); opacity: 0.22; }
  50% { transform: scaleX(0.12); opacity: 0.76; }
}

.login-panel {
  position: relative;
  z-index: 10;
  width: 100%;
  max-width: 500px;
  padding: 28px;
  perspective: 1200px;
}

.card-container {
  position: relative;
  overflow: hidden;
  padding: 52px 48px 40px;
  border: 1px solid rgba(231, 217, 202, 0.92);
  border-radius: 32px;
  background:
    linear-gradient(180deg, rgba(255, 250, 245, 0.98), rgba(247, 241, 234, 0.92)),
    radial-gradient(circle at 50% 0%, rgba(214, 168, 92, 0.12), transparent 44%);
  backdrop-filter: blur(28px) saturate(170%);
  box-shadow:
    0 28px 70px rgba(77, 54, 36, 0.12),
    0 10px 24px rgba(77, 54, 36, 0.06),
    inset 0 1px 0 rgba(255, 255, 255, 0.95),
    inset 0 -1px 0 rgba(154, 106, 67, 0.08);
  animation: panel-enter 0.8s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.card-container::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background: linear-gradient(180deg, rgba(214, 168, 92, 0.08), transparent 34%);
  transform: translateX(-62%);
}

.card-container::after {
  content: '';
  position: absolute;
  inset: 12px;
  z-index: 0;
  pointer-events: none;
  border: 1px solid rgba(255, 255, 255, 0.78);
  border-radius: 24px;
}

.card-glass-effect,
.panel-header,
.login-form {
  position: relative;
  z-index: 1;
}

.card-glass-effect {
  position: absolute;
  inset: -1px;
  z-index: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at 50% 0%, rgba(255, 255, 255, 0.88), transparent 44%),
    radial-gradient(circle at 100% 100%, rgba(111, 130, 99, 0.08), transparent 38%);
}

@keyframes panel-enter {
  from { opacity: 0; transform: translateY(22px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

@keyframes card-sheen {
  0%, 62% { transform: translateX(-68%); opacity: 0; }
  70% { opacity: 0.82; }
  100% { transform: translateX(68%); opacity: 0; }
}

.panel-header {
  margin-bottom: 42px;
  text-align: center;

  .brand-logo {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 72px;
    height: 72px;
    margin-bottom: 22px;
    border: 1px solid rgba(200, 120, 104, 0.16);
    border-radius: 24px;
    background:
      linear-gradient(145deg, rgba(255, 250, 245, 0.96), rgba(252, 238, 232, 0.82)),
      radial-gradient(circle at 50% 18%, rgba(200, 120, 104, 0.2), transparent 58%);
    box-shadow:
      0 16px 34px rgba(154, 106, 67, 0.11),
      inset 0 1px 0 rgba(255, 255, 255, 0.96);
  }

  .hospital-cross {
    width: 50px;
    height: 50px;

    &--pulse {
      animation: cross-heartbeat 2.6s ease-in-out infinite;
    }
  }

  .title {
    margin: 0;
    color: #2f2923;
    font-size: 28px;
    font-weight: 900;
    letter-spacing: -0.8px;
    line-height: 1.18;
    text-shadow: 0 1px 0 rgba(255, 255, 255, 0.9);
  }

  .tagline {
    margin: 12px 0 0;
    color: #8a7a6c;
    font-size: 12px;
    font-weight: 800;
    letter-spacing: 2.4px;
  }
}

@keyframes cross-heartbeat {
  0%, 100% { transform: scale(1); filter: drop-shadow(0 0 6px rgba(200, 120, 104, 0.18)); }
  50% { transform: scale(1.06); filter: drop-shadow(0 0 20px rgba(200, 120, 104, 0.34)); }
}

.form-label {
  display: inline-block;
  color: #4a3a2e;
  font-size: 14px;
  font-weight: 800;
  letter-spacing: 1px;
  vertical-align: middle;
}

:deep(.el-form-item) {
  display: flex;
  align-items: center;
  margin-bottom: 24px;
}

:deep(.el-form-item__label) {
  color: #4a3a2e;
}

:deep(.med-input) {
  .el-input__wrapper {
    min-height: 56px;
    padding: 0 18px;
    border: 1px solid rgba(178, 156, 132, 0.38) !important;
    border-radius: 16px;
    background:
      linear-gradient(180deg, rgba(255, 250, 245, 0.98), rgba(248, 241, 234, 0.96)) !important;
    box-shadow:
      0 10px 22px rgba(77, 54, 36, 0.045),
      inset 0 1px 0 rgba(255, 255, 255, 0.92) !important;
    transition: border-color 0.25s ease, box-shadow 0.25s ease, transform 0.25s ease;

    &:hover {
      border-color: rgba(154, 106, 67, 0.28) !important;
    }

    &.is-focus {
      border-color: rgba(154, 106, 67, 0.72) !important;
      background: rgba(255, 250, 245, 0.98) !important;
      box-shadow:
        0 0 0 4px rgba(214, 168, 92, 0.13),
        0 16px 30px rgba(154, 106, 67, 0.12) !important;
    }
  }

  .el-input__inner {
    color: #2f2923;
    font-size: 15px;
    font-weight: 600;
  }

  .el-input__prefix,
  .el-input__suffix {
    color: #8a7a6c;
  }
}

.form-actions {
  display: flex;
  justify-content: space-between;
  margin: 8px 4px 34px;
  font-size: 14px;
}

:deep(.el-checkbox) {
  height: auto;
  color: #8a5a38;
  font-weight: 700;

  .el-checkbox__input.is-checked .el-checkbox__inner {
    border-color: #9a6a43;
    background: linear-gradient(135deg, #d6a85c, #9a6a43);
  }

  .el-checkbox__label {
    color: #8a5a38;
    font-weight: 700;
  }
}

.btn-submit {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  width: 100%;
  height: 58px;
  overflow: hidden;
  border: 0;
  border-radius: 16px;
  background:
    linear-gradient(135deg, #9a6a43 0%, #c9895d 52%, #6f4b2f 100%);
  box-shadow:
    0 18px 34px -16px rgba(154, 106, 67, 0.58),
    inset 0 1px 0 rgba(255, 255, 255, 0.34),
    inset 0 -1px 0 rgba(61, 39, 24, 0.24);
  color: #fff;
  cursor: pointer;
  font-size: 17px;
  font-weight: 900;
  letter-spacing: 3px;
  transition: transform 0.28s ease, box-shadow 0.28s ease, filter 0.28s ease;

  &::before {
    content: '';
    position: absolute;
    inset: 1px;
    border-radius: 15px;
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.22), transparent 54%);
    pointer-events: none;
  }

  &::after {
    content: '';
    position: absolute;
    top: -40%;
    left: -22%;
    width: 26%;
    height: 180%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.65), transparent);
    transform: rotate(18deg);
    transition: left 0.55s ease;
  }

  span {
    position: relative;
    z-index: 1;
  }

  &:hover {
    transform: translateY(-3px);
    box-shadow:
      0 24px 42px -18px rgba(154, 106, 67, 0.64),
      inset 0 1px 0 rgba(255, 255, 255, 0.38);
    filter: saturate(1.08) brightness(1.03);

    &::after {
      left: 104%;
    }
  }

  &:active {
    transform: translateY(-1px);
  }

  &:disabled {
    cursor: not-allowed;
    opacity: 0.82;
  }
}

.panel-footer {
  margin-top: 34px;
  color: #9a8a7a;
  font-size: 14px;
  text-align: center;

  .link-action {
    position: relative;
    margin-left: 8px;
    color: #8a5a38;
    cursor: pointer;
    font-weight: 900;
    transition: color 0.2s ease;

    &::after {
      content: '';
      position: absolute;
      left: 0;
      right: 0;
      bottom: -4px;
      height: 2px;
      border-radius: 999px;
      background: currentColor;
      transform: scaleX(0);
      transform-origin: right;
      transition: transform 0.2s ease;
    }

    &:hover {
      color: #6f4b2f;

      &::after {
        transform: scaleX(1);
        transform-origin: left;
      }
    }
  }
}

.page-info-deco {
  display: none;
}

@media (max-width: 768px) {
  .login-panel {
    max-width: 100%;
    padding: 18px;
  }

  .card-container {
    padding: 34px 22px 30px;
    border-radius: 28px;
  }

  .card-container::after {
    inset: 10px;
    border-radius: 22px;
  }

  .panel-header {
    margin-bottom: 28px;

    .brand-logo {
      width: 68px;
      height: 68px;
      margin-bottom: 16px;
      border-radius: 22px;
    }

    .hospital-cross {
      width: 54px;
      height: 54px;
    }

    .title {
      font-size: 23px;
      letter-spacing: -0.4px;
    }

    .tagline {
      font-size: 10px;
      letter-spacing: 1.1px;
    }
  }

  .dna-aside {
    display: none !important;
  }

  .med-ecg-container {
    height: 190px !important;
  }

  :deep(.el-form-item) {
    flex-direction: column;
    align-items: flex-start;
    margin-bottom: 18px;

    .el-form-item__label {
      margin-bottom: 8px;
      padding: 0 !important;
    }

    .el-form-item__content {
      width: 100%;
    }
  }

  :deep(.med-input) {
    .el-input__wrapper {
      min-height: 54px;
      border-radius: 16px;
    }
  }

  .form-actions {
    margin: 8px 0 26px;
  }

  .btn-submit {
    height: 56px;
    border-radius: 16px;
    font-size: 15px;
    letter-spacing: 3px;
  }

  .panel-footer {
    margin-top: 26px;
  }

  .page-info-deco { display: none; }
}

@media (max-width: 380px) {
  .card-container {
    padding-inline: 18px;
  }

  .panel-header .title {
    font-size: 21px;
  }
}
</style>






