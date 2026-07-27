<template>
  <div class="dashboard">
    <div class="page-header">
      <h1 class="page-title">首页</h1>
      <span class="date-today">{{ today }}</span>
    </div>

    <!-- 快捷入口 -->
    <div class="quick-grid">
      <router-link to="/todo" class="quick-card">
        <span class="qc-icon">✅</span>
        <span class="qc-label">待办</span>
        <span class="qc-count">{{ todoCount }}</span>
      </router-link>
      <router-link to="/diary" class="quick-card">
        <span class="qc-icon">📝</span>
        <span class="qc-label">日记</span>
        <span class="qc-count">{{ diaryCount }}</span>
      </router-link>
      <router-link to="/reading" class="quick-card">
        <span class="qc-icon">📖</span>
        <span class="qc-label">阅读</span>
        <span class="qc-count">{{ readingCount }}</span>
      </router-link>
      <router-link to="/sports" class="quick-card">
        <span class="qc-icon">🏃</span>
        <span class="qc-label">运动</span>
        <span class="qc-count">{{ sportCount }}</span>
      </router-link>
    </div>

    <!-- 今日待办 -->
    <div class="card">
      <div class="card-title">今日待办</div>
      <div v-if="todayTodos.length === 0" class="empty-state">
        <div class="icon">🎉</div>
        <div class="text">今日待办已完成，真棒！</div>
      </div>
      <div v-else>
        <div v-for="todo in todayTodos" :key="todo.id" class="todo-item">
          <span :class="['todo-status', { completed: todo.completed }]">
            {{ todo.completed ? '✅' : '⬜' }}
          </span>
          <span :class="{ 'todo-text-done': todo.completed }">{{ todo.title }}</span>
        </div>
      </div>
    </div>

    <!-- 阅读统计概览 -->
    <div class="card" v-if="weeklyReadMinutes > 0">
      <div class="card-title">本周阅读</div>
      <div class="stat-row">
        <div class="stat-item">
          <div class="stat-value">{{ weeklyReadMinutes }}<span class="stat-unit">分钟</span></div>
          <div class="stat-label">本周累计</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ booksReading }}</div>
          <div class="stat-label">在读</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ booksFinished }}</div>
          <div class="stat-label">已读完</div>
        </div>
      </div>
    </div>

    <!-- 运动概览 -->
    <div class="card" v-if="weeklySportMinutes > 0">
      <div class="card-title">本周运动</div>
      <div class="stat-row">
        <div class="stat-item">
          <div class="stat-value">{{ weeklySportMinutes }}<span class="stat-unit">分钟</span></div>
          <div class="stat-label">本周累计</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ weeklySportCount }}</div>
          <div class="stat-label">运动次数</div>
        </div>
      </div>
    </div>

    <!-- 快捷操作 -->
    <div class="card">
      <div class="card-title">快捷操作</div>
      <div class="quick-actions">
        <router-link to="/diary" class="action-btn">📝 写日记</router-link>
        <router-link to="/reading" class="action-btn">📖 记阅读</router-link>
        <router-link to="/sports" class="action-btn">🏃 记运动</router-link>
        <router-link to="/settings" class="action-btn">⚙️ 设置</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const today = ref('')
const todoCount = ref(0)
const diaryCount = ref(0)
const readingCount = ref(0)
const sportCount = ref(0)
const todayTodos = ref([])
const weeklyReadMinutes = ref(0)
const weeklySportMinutes = ref(0)
const weeklySportCount = ref(0)
const booksReading = ref(0)
const booksFinished = ref(0)

function formatDate() {
  const d = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 星期${weekdays[d.getDay()]}`
}

async function loadData() {
  today.value = formatDate()

  try {
    // 待办
    const { count: tCount } = await supabase.from(TABLES.TODOS).select('*', { count: 'exact', head: true })
    todoCount.value = tCount || 0

    const { data: todos } = await supabase
      .from(TABLES.TODOS)
      .select('*')
      .eq('completed', false)
      .order('created_at', { ascending: false })
      .limit(5)
    todayTodos.value = todos || []

    // 日记
    const { count: dCount } = await supabase.from(TABLES.DIARY).select('*', { count: 'exact', head: true })
    diaryCount.value = dCount || 0

    // 阅读书目
    const { count: rCount } = await supabase.from(TABLES.READING_BOOKS).select('*', { count: 'exact', head: true })
    readingCount.value = rCount || 0

    const { data: books } = await supabase.from(TABLES.READING_BOOKS).select('status')
    if (books) {
      booksReading.value = books.filter(b => b.status === 'reading').length
      booksFinished.value = books.filter(b => b.status === 'finished').length
    }

    // 本周阅读时长
    const weekStart = getWeekStart()
    const { data: readSessions } = await supabase
      .from(TABLES.READING_SESSIONS)
      .select('duration')
      .gte('created_at', weekStart)
    if (readSessions) {
      weeklyReadMinutes.value = Math.round(readSessions.reduce((s, r) => s + (r.duration || 0), 0) / 60)
    }

    // 运动
    const { count: sCount } = await supabase.from(TABLES.SPORTS).select('*', { count: 'exact', head: true })
    sportCount.value = sCount || 0

    const { data: sports } = await supabase
      .from(TABLES.SPORTS)
      .select('duration')
      .gte('date', weekStart)
    if (sports) {
      weeklySportMinutes.value = sports.reduce((s, r) => s + (r.duration || 0), 0)
      weeklySportCount.value = sports.length
    }
  } catch (e) {
    console.warn('数据加载失败，请确认数据库已经建表', e)
  }
}

function getWeekStart() {
  const now = new Date()
  const day = now.getDay()
  const diff = now.getDate() - day + (day === 0 ? -6 : 1)
  const monday = new Date(now.setDate(diff))
  monday.setHours(0, 0, 0, 0)
  return monday.toISOString()
}

onMounted(loadData)
</script>

<style scoped>
.date-today {
  font-size: 13px;
  color: var(--text-secondary);
}

.quick-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  padding: 0 16px 12px;
}

.quick-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 20px 12px;
  background: var(--card-bg);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
  text-decoration: none;
  transition: transform 0.15s;
}

.quick-card:active {
  transform: scale(0.97);
}

.qc-icon {
  font-size: 28px;
}
.qc-label {
  font-size: 13px;
  color: var(--text-secondary);
  font-weight: 500;
}
.qc-count {
  font-size: 20px;
  font-weight: 700;
  color: var(--primary-color);
}

.todo-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
  font-size: 14px;
}
.todo-item + .todo-item {
  border-top: 1px solid var(--border-color);
}
.todo-status { font-size: 16px; }
.todo-text-done {
  text-decoration: line-through;
  color: var(--text-muted);
}

.stat-row {
  display: flex;
  justify-content: space-around;
  text-align: center;
}
.stat-item { flex: 1; }
.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: var(--primary-color);
}
.stat-unit {
  font-size: 12px;
  font-weight: 400;
  color: var(--text-muted);
}
.stat-label {
  font-size: 12px;
  color: var(--text-secondary);
  margin-top: 2px;
}

.quick-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 12px;
  background: var(--primary-bg);
  color: var(--primary-color);
  border-radius: var(--radius-sm);
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
  transition: background 0.2s;
}
.action-btn:active {
  background: #DDE3FF;
}
</style>
