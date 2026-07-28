<template>
  <div class="settings-page">
    <div class="page-header">
      <h1 class="page-title">设置</h1>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">一切为你，让你的工作台更贴心。</div>
    </div>

    <!-- 微信读书 -->
    <div class="card">
      <div class="card-title">📖 微信读书</div>
      <div class="setting-item">
        <label class="setting-label">API Key</label>
        <div class="input-group">
          <input v-model="wereadKey" class="input" :type="showKey ? 'text' : 'password'" placeholder="粘贴你的微信读书 API Key" />
          <button class="btn btn-secondary btn-sm" @click="showKey = !showKey">{{ showKey ? '隐藏' : '显示' }}</button>
        </div>
        <p class="setting-hint">
          在微信读书 App → 我 → 设置 → 微信读书 Skill，复制 API Key 粘贴到此处
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
            <span class="dc-label">工作</span>
            <span class="dc-value">{{ counts.work }}</span>
          </div>
          <div class="data-count-item">
            <span class="dc-label">运动</span>
            <span class="dc-value">{{ counts.sports }}</span>
          </div>
          <div class="data-count-item">
            <span class="dc-label">阅读</span>
            <span class="dc-value">{{ counts.books }}</span>
          </div>
          <div class="data-count-item">
            <span class="dc-label">碎碎念</span>
            <span class="dc-value">{{ counts.snippets }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 位置/天气 -->
    <div class="card">
      <div class="card-title">📍 位置与天气</div>
      <div class="setting-item">
        <p class="setting-hint">
          开启后，碎碎念会自动填充当前位置和天气
        </p>
        <button class="btn btn-secondary btn-block" @click="requestLocation">
          {{ locationGranted ? '✓ 已开启自动定位' : '开启定位' }}
        </button>
      </div>
    </div>

    <!-- 关于 -->
    <div class="card">
      <div class="card-title">🌱 关于 luna</div>
      <div class="about-info">
        <p class="about-version">luna v1.0</p>
        <p class="about-slogan">春日复古的个人效率工作台</p>
        <p class="about-tech">Vue 3 · Supabase · PWA</p>
        <p class="about-quote">— 在春日里，向内生长 —</p>
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
const locationGranted = ref(false)
const counts = ref({ todos: 0, work: 0, sports: 0, books: 0, snippets: 0 })

async function loadSettings() {
  try {
    const { data } = await supabase.from(TABLES.SETTINGS).select('*').eq('key', 'weread_api_key').single()
    if (data) wereadKey.value = data.value
  } catch (e) { /* not set */ }
}

async function loadCounts() {
  try {
    const queries = [
      { key: 'todos', table: TABLES.TODOS },
      { key: 'work', table: TABLES.WORK_FILES },
      { key: 'sports', table: TABLES.SPORTS },
      { key: 'books', table: TABLES.READING_BOOKS },
      { key: 'snippets', table: TABLES.SNIPPETS },
    ]
    for (const q of queries) {
      const { count } = await supabase.from(q.table).select('*', { count: 'exact', head: true })
      counts.value[q.key] = count || 0
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
      connectionStatus.value = '❌ 连接失败，请检查 API Key'
    }
  } catch (e) {
    connectionStatus.value = '❌ 连接失败：' + e.message
  }
}

function requestLocation() {
  if (!navigator.geolocation) {
    alert('浏览器不支持定位')
    return
  }
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      localStorage.setItem('luna_lat', pos.coords.latitude)
      localStorage.setItem('luna_lng', pos.coords.longitude)
      locationGranted.value = true
    },
    (err) => {
      alert('获取位置失败：' + err.message)
    }
  )
}

onMounted(() => {
  loadSettings()
  loadCounts()
  if (localStorage.getItem('luna_lat')) locationGranted.value = true
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
  background: var(--primary-bg);
  color: var(--primary-dark);
}

.connection-status.error {
  background: #F5E6E1;
  color: var(--danger-color);
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
  background: var(--primary-bg);
  color: var(--primary-dark);
}

.status-badge.disconnected {
  background: var(--bg-warm);
  color: var(--text-muted);
}

.data-counts {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 6px;
}

.data-count-item {
  text-align: center;
  padding: 8px 4px;
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
}

.dc-label {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
}

.dc-value {
  display: block;
  font-size: 18px;
  font-weight: 700;
  color: var(--primary-dark);
}

.about-info {
  text-align: center;
  padding: 8px 0;
}

.about-version {
  font-size: 18px;
  font-weight: 700;
  color: var(--primary-dark);
  font-family: var(--font-serif);
  letter-spacing: 2px;
}

.about-slogan {
  font-size: 13px;
  color: var(--text-secondary);
  margin: 4px 0 8px;
}

.about-tech {
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 12px;
}

.about-quote {
  font-size: 13px;
  color: var(--accent-brown);
  font-family: var(--font-serif);
  font-style: italic;
}
</style>
