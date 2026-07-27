<template>
  <div class="settings-page">
    <div class="page-header">
      <h1 class="page-title">设置</h1>
    </div>

    <!-- 微信读书 -->
    <div class="card">
      <div class="card-title">📖 微信读书</div>
      <div class="setting-item">
        <label class="setting-label">API Key</label>
        <div class="input-group">
          <input v-model="wereadKey" class="input" type="password" placeholder="粘贴你的微信读书 API Key" @focus="showKey = true" />
          <button class="btn btn-secondary" @click="showKey = !showKey">{{ showKey ? '隐藏' : '显示' }}</button>
        </div>
        <p class="setting-hint">
          在微信读书 App → 我 → 设置 → 微信读书 Skill，复制 API Key 粘贴到这里
        </p>
        <div class="setting-actions">
          <button class="btn btn-primary" @click="saveWeReadKey" :disabled="!wereadKey.trim()">保存</button>
          <button v-if="wereadKey" class="btn btn-secondary" @click="testConnection">测试连接</button>
        </div>
        <div v-if="connectionStatus" class="connection-status" :class="connectionOk ? 'success' : 'error'">
          {{ connectionStatus }}
        </div>
      </div>
    </div>

    <!-- 数据管理 -->
    <div class="card">
      <div class="card-title">💾 数据管理</div>
      <div class="setting-item">
        <div class="setting-info">
          <span class="setting-label">数据库状态</span>
          <span :class="['status-badge', dbConnected ? 'connected' : 'disconnected']">
            {{ dbConnected ? '已连接' : '未连接' }}
          </span>
        </div>
        <div class="data-counts" v-if="dbConnected">
          <div class="data-count-item">
            <span class="dc-label">待办</span>
            <span class="dc-value">{{ counts.todos }}</span>
          </div>
          <div class="data-count-item">
            <span class="dc-label">日记</span>
            <span class="dc-value">{{ counts.diaries }}</span>
          </div>
          <div class="data-count-item">
            <span class="dc-label">阅读</span>
            <span class="dc-value">{{ counts.books }}</span>
          </div>
          <div class="data-count-item">
            <span class="dc-label">运动</span>
            <span class="dc-value">{{ counts.sports }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 关于 -->
    <div class="card">
      <div class="card-title">ℹ️ 关于</div>
      <div class="about-info">
        <p>个人效率工作台 v1.0</p>
        <p>技术栈：Vue 3 + Supabase + Vite PWA</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'
import { validateApiKey } from '../utils/weread.js'

const wereadKey = ref('')
const showKey = ref(false)
const connectionStatus = ref('')
const connectionOk = ref(false)
const dbConnected = ref(false)
const counts = ref({ todos: 0, diaries: 0, books: 0, sports: 0 })

async function loadSettings() {
  try {
    const { data } = await supabase.from(TABLES.SETTINGS).select('*').eq('key', 'weread_api_key').single()
    if (data) {
      wereadKey.value = data.value
      dbConnected.value = true
    }
  } catch (e) {
    // 可能还没数据
  }
}

async function loadCounts() {
  try {
    const tables = [
      { key: 'todos', table: TABLES.TODOS },
      { key: 'diaries', table: TABLES.DIARY },
      { key: 'books', table: TABLES.READING_BOOKS },
      { key: 'sports', table: TABLES.SPORTS },
    ]
    for (const t of tables) {
      const { count } = await supabase.from(t.table).select('*', { count: 'exact', head: true })
      counts.value[t.key] = count || 0
    }
    dbConnected.value = true
  } catch (e) {
    dbConnected.value = false
  }
}

async function saveWeReadKey() {
  try {
    const { data: existing } = await supabase.from(TABLES.SETTINGS).select('*').eq('key', 'weread_api_key')
    if (existing && existing.length > 0) {
      await supabase.from(TABLES.SETTINGS).update({ value: wereadKey.value }).eq('key', 'weread_api_key')
    } else {
      await supabase.from(TABLES.SETTINGS).insert({ key: 'weread_api_key', value: wereadKey.value })
    }
    alert('保存成功！')
    connectionStatus.value = ''
  } catch (e) {
    alert('保存失败：' + e.message)
  }
}

async function testConnection() {
  connectionStatus.value = '正在测试...'
  connectionOk.value = false
  try {
    const valid = await validateApiKey(wereadKey.value)
    if (valid) {
      connectionStatus.value = '✅ 连接成功！微信读书数据可以正常同步'
      connectionOk.value = true
    } else {
      connectionStatus.value = '❌ 连接失败，请检查 API Key 是否正确'
    }
  } catch (e) {
    connectionStatus.value = '❌ 连接失败：' + e.message
  }
}

onMounted(() => {
  loadSettings()
  loadCounts()
})
</script>

<style scoped>
.setting-item {
  padding: 4px 0;
}
.setting-label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 8px;
}
.input-group {
  display: flex;
  gap: 8px;
}
.input-group .input {
  flex: 1;
}
.setting-hint {
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 6px;
  line-height: 1.5;
}
.setting-actions {
  display: flex;
  gap: 8px;
  margin-top: 10px;
}
.connection-status {
  margin-top: 8px;
  padding: 8px 12px;
  border-radius: var(--radius-sm);
  font-size: 13px;
}
.connection-status.success {
  background: #D1FAE5;
  color: #065F46;
}
.connection-status.error {
  background: #FEE2E2;
  color: #991B1B;
}

.setting-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}
.status-badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}
.status-badge.connected {
  background: #D1FAE5;
  color: #065F46;
}
.status-badge.disconnected {
  background: var(--bg-color);
  color: var(--text-muted);
}

.data-counts {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}
.data-count-item {
  text-align: center;
  padding: 8px;
  background: var(--bg-color);
  border-radius: var(--radius-sm);
}
.dc-label {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
}
.dc-value {
  display: block;
  font-size: 20px;
  font-weight: 700;
  color: var(--primary-color);
}

.about-info {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.8;
}
</style>
