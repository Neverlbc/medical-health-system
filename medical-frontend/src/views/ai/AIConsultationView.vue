<template>
  <div class="ai-consultation-container">
    <div class="ai-chat-card">
      <!-- 聊天头部 -->
      <header class="chat-header">
        <div class="bot-info">
          <div class="bot-avatar-ring">
            <div class="bot-avatar">
              <svg viewBox="0 0 128 128" class="med-bot-svg">
                <rect x="24" y="32" width="80" height="72" rx="20" fill="#fbf4ec" stroke="#9a6a43" stroke-width="4" />
                <rect x="36" y="48" width="56" height="30" rx="8" fill="#fffaf5" stroke="#9a6a43" stroke-width="2" />
                <ellipse cx="50" cy="63" rx="4" ry="6" fill="#9a6a43"><animate attributeName="ry" values="6;1;6" dur="3s" repeatCount="indefinite" /></ellipse>
                <ellipse cx="78" cy="63" rx="4" ry="6" fill="#9a6a43"><animate attributeName="ry" values="6;1;6" dur="3s" repeatCount="indefinite" /></ellipse>
                <path d="M48 88 L55 88 L58 82 L63 94 L66 88 L75 88" fill="none" stroke="#6f8263" stroke-width="2.5" stroke-linecap="round" />
                <rect x="58" y="38" width="12" height="4" rx="1.5" fill="#c87868" /><rect x="62" y="34" width="4" height="12" rx="1.5" fill="#c87868" />
              </svg>
            </div>
            <div class="online-status"></div>
          </div>
          <div class="bot-meta">
            <h3>智能医疗助手</h3>
            <p>全域医学知识库 · 辅助诊疗专家</p>
          </div>
        </div>
        <div class="header-actions">
          <el-button link :icon="Delete" @click="clearHistory" class="action-btn">清空对话记录</el-button>
        </div>
      </header>
      
      <!-- AI 免责声明横幅 -->
      <div class="ai-disclaimer-banner">
        <el-icon><Warning /></el-icon>
        <div class="disclaimer-text">
          <strong>重要声明：</strong>AI 建议仅供健康参考，不能替代专业医生的诊断和治疗。如有紧急症状，请立即拨打 <strong>120</strong> 或前往医院就诊。
        </div>
      </div>
      
      <!-- 聊天主体 -->
      <div class="chat-main" ref="scrollContainer">
        <div v-for="item in messages" :key="item.id" :class="['msg-row', item.role]">
          <div class="msg-avatar">
            <el-avatar v-if="item.role === 'user'" :size="40" class="u-avatar">
              {{ (authStore.userInfo?.nickname || 'U').charAt(0) }}
            </el-avatar>
            <div v-else class="a-avatar">
              <svg viewBox="0 0 128 128" class="med-bot-svg">
                <rect x="24" y="32" width="80" height="72" rx="20" fill="#fffaf5" stroke="#9a6a43" stroke-width="5" />
                <rect x="36" y="48" width="56" height="30" rx="8" fill="#fbf4ec" />
                <circle cx="50" cy="63" r="4" fill="#9a6a43" /><circle cx="78" cy="63" r="4" fill="#9a6a43" />
                <rect x="58" y="38" width="12" height="4" rx="1.5" fill="#c87868" /><rect x="62" y="34" width="4" height="12" rx="1.5" fill="#c87868" />
              </svg>
            </div>
          </div>
          <div class="msg-bubble" :class="{ 'is-streaming': item.isStreaming }">
            <div class="bubble-content">
              <div v-if="item.content" class="formatted-content" v-html="formatContent(item.content)"></div>
              <span v-else-if="item.isStreaming" class="typing-dots inline-typing">
                <span></span><span></span><span></span>
              </span>
              <span v-if="item.isStreaming" class="typing-cursor">|</span>
            </div>
            <div class="bubble-footer">
              <span class="msg-time">{{ formatTime(item.id) }}</span>
              <span v-if="item.isStreaming" class="streaming-tag">AI 正在输入...</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 输入区域 -->
      <footer class="chat-footer">
        <div class="input-wrapper">
          <el-input
            v-model="question"
            type="textarea"
            :rows="2"
            placeholder="请详细描述您的症状，例如：'头痛持续了两天，伴有恶心'..."
            @keydown="onKeydown"
            resize="none"
            class="chat-input"
          />
          <div class="footer-bottom">
            <div class="safety-tip">
              <el-icon><ShieldCheck /></el-icon>
              <span>AI 建议基于大数据模型，急重症请务必拨打 120 或立刻前往门诊</span>
            </div>
            <button class="send-btn" :disabled="loading || !question.trim()" @click="handleAsk">
              <el-icon v-if="!loading"><Position /></el-icon>
              <el-icon v-else class="is-loading"><Loading /></el-icon>
              <span>发送指令</span>
            </button>
          </div>
        </div>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { useAuthStore } from '@/store/modules/auth';
import { Delete, Position, Loading, Warning } from '@element-plus/icons-vue';

// AI 回复免责尾注
const AI_DISCLAIMER = '\n\n提示：以上内容由 AI 自动生成，仅供健康参考，不构成医疗诊断。如有疑问请咨询专业医生。';

// API 基础路径
const API_BASE = import.meta.env.VITE_API_BASE_URL || '/api/v1';

interface MessageItem {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  isStreaming?: boolean;
}

const loading = ref(false);
const question = ref('');
const messages = ref<MessageItem[]>([]);
const scrollContainer = ref<HTMLDivElement>();
const authStore = useAuthStore();
const storageKey = ref<string>('ai-history-' + (authStore.userInfo?.username || 'guest'));

const appendMessage = (message: MessageItem) => {
  messages.value.push(message);
  if (!message.isStreaming) {
    saveHistory();
  }
  scrollToBottom();
};

const updateLastMessage = (content: string, isStreaming: boolean = true) => {
  const lastMsg = messages.value[messages.value.length - 1];
  if (lastMsg && lastMsg.role === 'assistant') {
    lastMsg.content = content;
    lastMsg.isStreaming = isStreaming;
    if (!isStreaming) {
      saveHistory();
    }
  }
  scrollToBottom();
};

const scrollToBottom = () => {
  nextTick(() => {
    const el = scrollContainer.value;
    if (el) el.scrollTo({ top: el.scrollHeight, behavior: 'smooth' });
  });
};

const saveHistory = () => {
  try {
    // Don't save streaming messages
    const historyToSave = messages.value.filter(m => !m.isStreaming).slice(-100);
    localStorage.setItem(storageKey.value, JSON.stringify(historyToSave));
  } catch {}
};

const loadHistory = () => {
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
  messages.value = [{ id: Date.now(), role: 'assistant', content: '您好，我是您的专属医疗 AI 助手。我可以为您解释化验单、分析常规症状或提供日常健康建议。请问有什么我可以帮您的？' }];
};

const handleAsk = async () => {
  if (!question.value.trim() || loading.value) return;
  const content = question.value.trim();
  appendMessage({ id: Date.now(), role: 'user', content });
  question.value = '';
  loading.value = true;
  
  // Add placeholder for streaming response
  const streamMsgId = Date.now() + 1;
  appendMessage({ id: streamMsgId, role: 'assistant', content: '', isStreaming: true });
  
  let fullContent = '';
  
  try {
    const token = authStore.token;
    const response = await fetch(`${API_BASE}/ai/chat/stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ message: content })
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const reader = response.body?.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    if (reader) {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        // Keep the last incomplete line in buffer
        buffer = lines.pop() || '';
        
        for (const line of lines) {
          if (line.startsWith('data:')) {
            const rawData = line.substring(5);
            // Don't trim - preserve spaces, but check for [DONE] after trimming for comparison
            if (rawData.trim() === '[DONE]') {
              // Stream complete, add disclaimer
              fullContent += AI_DISCLAIMER;
              updateLastMessage(fullContent, false);
            } else if (rawData.trim()) {
              try {
                // Parse JSON to restore newlines and special characters
                const chunk = JSON.parse(rawData.trim());
                fullContent += chunk;
              } catch {
                // Fallback: use raw data if not valid JSON
                fullContent += rawData;
              }
              updateLastMessage(fullContent, true);
            }
          }
        }
      }
    }
    
    // Ensure final update if stream ended without [DONE]
    if (fullContent && messages.value[messages.value.length - 1]?.isStreaming) {
      fullContent += AI_DISCLAIMER;
      updateLastMessage(fullContent, false);
    }
    
  } catch (error) {
    console.error('SSE Error:', error);
    // Fallback to non-streaming API
    try {
      const { aiApi } = await import('@/api/modules/ai');
      const reply = await aiApi.chat({ message: content });
      const replyContent = reply ? String(reply).trim() + AI_DISCLAIMER : '目前无法获取 AI 回复，请稍后再次尝试。';
      updateLastMessage(replyContent, false);
    } catch (fallbackError) {
      updateLastMessage('网络通讯异常，请检查接口服务。', false);
      ElMessage.error('AI 服务暂时不可用');
    }
  } finally {
    loading.value = false;
  }
};

const onKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    handleAsk();
  }
};

const clearHistory = () => {
  messages.value = [{ id: Date.now(), role: 'assistant', content: '对话已重置。您可以开始新的问询。' }];
  saveHistory();
};

const formatTime = (ts: number) => new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

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
    .replace(/^[-*_]{3,}\s*$/gm, '')
    .replace(/^\*?⚠️?\s*(以上内容由 AI 自动生成，仅供健康参考，不构成医疗诊断。如有疑问请咨询专业医生。)\*?$/gm, '提示：$1')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
};

const formatContent = (content: string) => {
  return escapeHtml(normalizeContent(content))
    .replace(/^###\s+(.+)$/gm, '<h3>$1</h3>')
    .replace(/^##\s+(.+)$/gm, '<h2>$1</h2>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/^\s*[-*]\s+(.+)$/gm, '<div class="ai-list-item">$1</div>')
    .replace(/^(提示：以上内容由 AI 自动生成，仅供健康参考，不构成医疗诊断。如有疑问请咨询专业医生。)$/gm, '<span class="ai-note">$1</span>')
    .replace(/\n/g, '<br>');
};

onMounted(loadHistory);
</script>

<style scoped lang="scss">
.ai-consultation-container {
  width: calc(100% + 80px);
  height: calc(100vh - 76px);
  min-height: 720px;
  margin: -36px -40px;
  display: flex;
  justify-content: stretch;
  align-items: stretch;
}

.ai-chat-card {
  width: 100%;
  max-width: none;
  height: 100%;
  min-height: 0;
  background: #fffaf5;
  border-radius: 0;
  box-shadow: none;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: none;
}

// 头部
.chat-header {
  padding: 22px 48px;
  background: rgba(255, 250, 245, 0.96);
  border-bottom: 1px solid #eadbca;
  display: flex;
  justify-content: space-between;
  align-items: center;

  .bot-info {
    display: flex; align-items: center; gap: 15px;
    .bot-avatar-ring {
      position: relative;
      .bot-avatar { width: 44px; height: 44px; background: #fbf4ec; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 24px; border: 1px solid #eadbca; }
      .online-status { position: absolute; bottom: -2px; right: -2px; width: 12px; height: 12px; background: #6f8263; border: 2px solid #fffaf5; border-radius: 50%; }
    }
    .bot-meta {
      h3 { margin: 0; font-size: 17px; font-weight: 800; color: #2f2923; }
      p { margin: 0; font-size: 12px; color: #9a8a7a; font-weight: 600; }
    }
  }

  .action-btn { color: #9a8a7a; font-weight: 600; font-size: 13px; &:hover { color: #c87868; } }
}

// 免责声明横幅
.ai-disclaimer-banner {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  border-bottom: 1px solid #f59e0b;
  padding: 12px 48px;
  display: flex;
  align-items: center;
  gap: 12px;
  
  .el-icon {
    font-size: 20px;
    color: #b45309;
    flex-shrink: 0;
  }
  
  .disclaimer-text {
    font-size: 13px;
    color: #78350f;
    
    strong {
      color: #b45309;
    }
  }
}

// 对话区
.chat-main {
  flex: 1; overflow-y: auto; padding: 34px 52px; background:
    radial-gradient(circle at 10% 5%, rgba(214, 168, 92, 0.09), transparent 28%),
    #f6efe6;
  display: flex; flex-direction: column; gap: 24px;
}

.msg-row {
  display: flex; gap: 16px; max-width: 92%;
  &.user { align-self: flex-end; flex-direction: row-reverse;
    .msg-bubble { background: linear-gradient(135deg, #9a6a43, #c9895d); color: #fffaf5; border-radius: 20px 20px 4px 20px; box-shadow: 0 8px 20px rgba(154,106,67,0.18); }
    .msg-time { color: rgba(255,255,255,0.6); }
  }
  &.assistant { align-self: flex-start;
    .msg-bubble { background: #fffaf5; color: #66584b; border-radius: 20px 20px 20px 4px; box-shadow: 0 4px 15px rgba(77,54,36,0.04); border: 1px solid #eadbca; }
  }
}

.msg-avatar {
  flex-shrink: 0;
  .u-avatar { background: linear-gradient(135deg, #9a6a43, #d6a85c); font-weight: 800; }
  .a-avatar { width: 40px; height: 40px; background: #fffaf5; border-radius: 12px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 8px rgba(77,54,36,0.06); border: 1px solid #eadbca; overflow: hidden;
    .med-bot-svg { width: 85%; height: 85%; }
  }
}

.msg-bubble {
  padding: 20px 24px; position: relative;
  .bubble-content { font-size: 16px; line-height: 1.85; word-break: break-word;
    :deep(h3) { font-size: 16px; margin: 10px 0 5px; }
    :deep(strong) { color: #9a6a43; font-weight: 700; }
    :deep(.ai-note) {
      display: inline-block;
      margin-top: 8px;
      color: #9a8a7a;
      font-size: 13px;
      line-height: 1.6;
    }
    :deep(.ai-list-item) {
      position: relative;
      padding-left: 14px;
      margin: 2px 0;

      &::before {
        content: '';
        position: absolute;
        left: 0;
        top: 0.85em;
        width: 5px;
        height: 5px;
        border-radius: 50%;
        background: #b8a693;
      }
    }
  }
  .bubble-footer { margin-top: 8px; display: flex; align-items: center; gap: 10px; }
  .msg-time { font-size: 11px; font-weight: 600; opacity: 0.7; }
}

// 正在输入
.typing-dots {
  display: inline-flex;
  align-items: center;
  gap: 4px;

  span {
    width: 6px;
    height: 6px;
    background: #cdbba8;
    border-radius: 50%;
    animation: bounce 1.4s infinite;

    &:nth-child(2) { animation-delay: 0.2s; }
    &:nth-child(3) { animation-delay: 0.4s; }
  }
}

.inline-typing {
  min-width: 36px;
  margin-right: 6px;
}

@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-5px); } }

// 尾部输入区
.chat-footer {
  padding: 10px 40px 12px; background: rgba(255, 250, 245, 0.98); border-top: 1px solid #eadbca;
  
  .input-wrapper { position: relative; }
  .chat-input :deep(.el-textarea__inner) {
    min-height: 58px !important;
    background: #f6efe6; border-radius: 14px; border: 1px solid #eadbca; padding: 10px 16px; font-size: 14px; transition: 0.3s;
    &:focus { border-color: #9a6a43; background: #fffaf5; box-shadow: 0 0 0 4px rgba(154,106,67,0.08); }
  }

  .footer-bottom {
    margin-top: 8px; display: flex; justify-content: space-between; align-items: center;
    .safety-tip { display: flex; align-items: center; gap: 6px; font-size: 10.5px; color: #9a8a7a; font-weight: 600; }
    .send-btn {
      min-width: 116px;
      background: #9a6a43; color: #fffaf5; border: none; padding: 8px 18px; border-radius: 10px;
      font-weight: 700; display: flex; align-items: center; gap: 8px; cursor: pointer; transition: 0.3s;
      &:hover:not(:disabled) { background: #6f4b2f; transform: translateY(-2px); box-shadow: 0 8px 20px rgba(154,106,67,0.24); }
      &:disabled { background: #e7d9ca; color: #9a8a7a; cursor: not-allowed; }
    }
  }
}

// 打字机效果 - 闪烁光标
.typing-cursor {
  display: inline-block;
  color: #9a6a43;
  font-weight: 700;
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

// 流式消息样式
.msg-bubble.is-streaming {
  border: 1px solid #9a6a43 !important;
  box-shadow: 0 0 0 3px rgba(154, 106, 67, 0.1) !important;
}

.streaming-tag {
  font-size: 10px;
  color: #9a6a43;
  background: #e8f4ff;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 600;
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

@media (max-width: 1024px) and (min-width: 769px) {
  .ai-consultation-container {
    width: calc(100% + 40px);
    height: calc(100vh - 76px);
    margin: -20px;
  }

  .chat-header,
  .ai-disclaimer-banner,
  .chat-footer {
    padding-left: 28px;
    padding-right: 28px;
  }

  .chat-main {
    padding: 28px;
  }
}

// 移动端适配
@media (max-width: 768px) {
  .ai-consultation-container {
    width: calc(100% + 32px);
    height: calc(100vh - 64px);
    min-height: 0;
    margin: -16px;
    padding: 0;
  }
  
  .ai-chat-card {
    border-radius: 0;
    height: 100%;
    max-width: 100%;
  }
  
  .chat-header {
    padding: 12px 16px;
    
    .bot-info {
      gap: 10px;
      
      .bot-meta {
        h3 { font-size: 14px; }
        p { font-size: 10px; }
      }
    }
  }
  
  .ai-disclaimer-banner {
    margin: 0;
    padding: 10px 16px;
    border-radius: 0;
    font-size: 12px;
    
    .el-icon {
      font-size: 20px;
    }
  }
  
  .chat-main {
    padding: 16px;
    gap: 16px;
  }
  
  .msg-row {
    max-width: 95%;
    gap: 10px;
  }
  
  .msg-avatar {
    .u-avatar, .a-avatar {
      width: 32px !important;
      height: 32px !important;
    }
  }
  
  .msg-bubble {
    padding: 12px 14px;
    border-radius: 16px 16px 16px 4px;
    
    .bubble-content {
      font-size: 14px;
    }
    
    .bubble-footer {
      margin-top: 6px;
      gap: 6px;
    }
  }
  
  .msg-row.user .msg-bubble {
    border-radius: 16px 16px 4px 16px;
  }
  
  .chat-footer {
    padding: 10px 16px 12px;
    
    .chat-input :deep(.el-textarea__inner) {
      min-height: 56px !important;
      padding: 10px 12px;
      font-size: 14px;
      border-radius: 12px;
    }
    
    .footer-bottom {
      margin-top: 8px;
      
      .safety-tip {
        display: none;
      }
      
      .send-btn {
        padding: 8px 16px;
        border-radius: 10px;
        font-size: 13px;
      }
    }
  }
}
</style>
