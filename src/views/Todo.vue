<template>
  <div class="todo-page">
    <!-- 顶部 -->
    <div class="page-header">
      <h1 class="page-title">待办</h1>
      <router-link to="/todo/summary" class="btn btn-secondary btn-sm">📊 汇总</router-link>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 时间环状总结 + 已完成列表 -->
    <div class="card summary-card">
      <div class="card-title">⏱ 今日专注总结</div>
      <div class="ring-row">
        <div class="ring-progress">
          <svg width="140" height="140" viewBox="0 0 140 140">
            <circle cx="70" cy="70" r="58" fill="none" stroke="var(--primary-bg)" stroke-width="10" />
            <circle
              cx="70" cy="70" r="58" fill="none"
              stroke="var(--primary-color)" stroke-width="10"
              stroke-linecap="round"
              :stroke-dasharray="ringCircumference"
              :stroke-dashoffset="ringDashoffset"
              class="ring-circle"
            />
          </svg>
          <div class="ring-text">
            <div class="ring-value">{{ todayFocusMinutes }}</div>
            <div class="ring-unit">分钟</div>
            <div class="ring-label">今日专注</div>
          </div>
        </div>
        <div class="ring-stats">
          <div class="rs-item">
            <span class="rs-num">{{ todaySessionsCount }}</span>
            <span class="rs-label">番茄数</span>
          </div>
          <div class="rs-item">
            <span class="rs-num">{{ todayCompletedCount }}</span>
            <span class="rs-label">已完成</span>
          </div>
          <div class="rs-item">
            <span class="rs-num">{{ todayPendingCount }}</span>
            <span class="rs-label">待办</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 今日已完成 -->
    <div v-if="todayCompleted.length > 0" class="card completed-card">
      <div class="card-title">
        ✅ 今日已完成
        <span class="title-count">{{ todayCompleted.length }}</span>
      </div>
      <div v-for="todo in todayCompleted" :key="todo.id" class="completed-item">
        <div class="completed-check">✓</div>
        <div class="completed-info">
          <div class="completed-title">{{ todo.title }}</div>
          <div class="completed-time">{{ formatTime(todo.completed_at) }}</div>
        </div>
        <button class="btn-icon-small danger" @click="deleteTodo(todo)">✕</button>
      </div>
    </div>

    <!-- 番茄钟 -->
    <div class="card pomodoro-card">
      <div class="card-title">🍅 专注番茄钟</div>
      <div class="pomodoro-mode">
        <button :class="['mode-btn', { active: pomodoroMode === 'countdown' }]" @click="pomodoroMode = 'countdown'">倒计时</button>
        <button :class="['mode-btn', { active: pomodoroMode === 'countup' }]" @click="pomodoroMode = 'countup'">正计时</button>
      </div>
      <div class="pomodoro-timer">{{ formattedTime }}</div>
      <div class="pomodoro-status">{{ pomodoroStatus }}</div>
      <div class="pomodoro-actions">
        <button v-if="!isRunning && !isPaused" class="btn btn-primary" @click="startTimer">开始专注</button>
        <button v-if="isRunning" class="btn btn-danger" @click="pauseTimer">暂停</button>
        <button v-if="isPaused" class="btn btn-primary" @click="resumeTimer">继续</button>
        <button v-if="isRunning || isPaused" class="btn btn-secondary" @click="stopTimer">停止</button>
      </div>
      <div v-if="pomodoroMode === 'countdown'" class="pomodoro-select">
        <label>专注时长：</label>
        <select v-model="focusMinutes" :disabled="isRunning || isPaused" class="select" style="width:auto;display:inline-block;padding:4px 8px;">
          <option :value="15">15分钟</option>
          <option :value="25">25分钟</option>
          <option :value="30">30分钟</option>
          <option :value="45">45分钟</option>
          <option :value="60">60分钟</option>
        </select>
      </div>
    </div>

    <!-- 关联待办 -->
    <div class="card" v-if="!isRunning && !isPaused">
      <div class="card-title">关联待办（可选）</div>
      <select v-model="selectedTodoId" class="select">
        <option :value="null">不关联，自由专注</option>
        <option v-for="t in incompleteTodos" :key="t.id" :value="t.id">{{ t.title }}</option>
      </select>
    </div>

    <!-- Tab 切换 -->
    <div class="tab-bar">
      <button :class="['tab-item', { active: activeTab === 'today' }]" @click="activeTab = 'today'">今天待办</button>
      <button :class="['tab-item', { active: activeTab === 'week' }]" @click="activeTab = 'week'">本周待办</button>
      <button :class="['tab-item', { active: activeTab === 'none' }]" @click="activeTab = 'none'">无日期待办</button>
      <button :class="['tab-item', { active: activeTab === 'checkin' }]" @click="activeTab = 'checkin'">打卡</button>
    </div>

    <!-- 快速添加 -->
    <div class="card">
      <div class="add-todo-row">
        <input v-model="newTodoTitle" class="input" placeholder="添加新待办..." @keyup.enter="addTodo" />
        <button class="btn btn-primary btn-sm" @click="addTodo">+</button>
      </div>
    </div>

    <!-- 今天待办 -->
    <div v-show="activeTab === 'today'">
      <div v-if="todayTodos.length === 0" class="empty-state">
        <div class="icon">🎉</div>
        <div class="text">今天待办已完成，真棒！</div>
      </div>
      <div v-for="todo in todayTodos" :key="todo.id" class="card todo-card">
        <div class="todo-row">
          <input type="checkbox" :checked="todo.completed" @change="toggleTodo(todo)" class="todo-checkbox" />
          <span class="todo-text" :class="{ done: todo.completed }">{{ todo.title }}</span>
          <button class="btn-icon-small danger" @click="deleteTodo(todo)">✕</button>
        </div>
      </div>
    </div>

    <!-- 本周待办 -->
    <div v-show="activeTab === 'week'">
      <div v-if="weekTodos.length === 0" class="empty-state">
        <div class="icon">📅</div>
        <div class="text">本周没有待办</div>
      </div>
      <div v-for="todo in weekTodos" :key="todo.id" class="card todo-card">
        <div class="todo-row">
          <input type="checkbox" :checked="todo.completed" @change="toggleTodo(todo)" class="todo-checkbox" />
          <span class="todo-text" :class="{ done: todo.completed }">{{ todo.title }}</span>
          <span class="todo-date">{{ formatDate(todo.due_date) }}</span>
          <button class="btn-icon-small danger" @click="deleteTodo(todo)">✕</button>
        </div>
      </div>
    </div>

    <!-- 无日期待办 -->
    <div v-show="activeTab === 'none'">
      <div v-if="noneTodos.length === 0" class="empty-state">
        <div class="icon">📝</div>
        <div class="text">没有无日期待办</div>
      </div>
      <div v-for="todo in noneTodos" :key="todo.id" class="card todo-card">
        <div class="todo-row">
          <input type="checkbox" :checked="todo.completed" @change="toggleTodo(todo)" class="todo-checkbox" />
          <span class="todo-text" :class="{ done: todo.completed }">{{ todo.title }}</span>
          <button class="btn-icon-small danger" @click="deleteTodo(todo)">✕</button>
        </div>
      </div>
    </div>

    <!-- 打卡 -->
    <div v-show="activeTab === 'checkin'">
      <div class="card">
        <div class="card-title">🎯 添加打卡项</div>
        <input v-model="checkinTitle" class="input" placeholder="打卡内容（如：阅读30分钟、运动）" />
        <div class="checkin-pattern-row">
          <span class="checkin-label">周期：</span>
          <button :class="['pattern-btn', { active: checkinPattern === 'daily' }]" @click="checkinPattern = 'daily'">每天</button>
          <button :class="['pattern-btn', { active: checkinPattern === 'weekly' }]" @click="checkinPattern = 'weekly'">每周</button>
          <button :class="['pattern-btn', { active: checkinPattern === 'specific' }]" @click="checkinPattern = 'specific'">指定日</button>
        </div>
        <div v-if="checkinPattern === 'specific'" class="weekday-row">
          <button
            v-for="(day, idx) in weekdayLabels"
            :key="idx"
            :class="['weekday-btn', { active: checkinDays.includes(idx + 1) }]"
            @click="toggleDay(idx + 1)"
          >{{ day }}</button>
        </div>
        <button class="btn btn-primary btn-block" @click="addCheckin" style="margin-top:10px;">添加打卡</button>
      </div>

      <div v-for="item in checkinTodos" :key="item.id" class="card todo-card">
        <div class="checkin-row">
          <div class="checkin-info">
            <span class="checkin-name">{{ item.title }}</span>
            <span class="checkin-meta">{{ getPatternLabel(item.checkin_pattern, item.checkin_days) }}</span>
          </div>
          <div class="checkin-actions">
            <button
              v-if="isCheckinToday(item)"
              :class="['checkin-btn', { done: isCheckedIn(item) }]"
              @click="toggleCheckin(item)"
            >{{ isCheckedIn(item) ? '✓' : '打卡' }}</button>
            <span v-else class="checkin-rest">📅 休</span>
            <button class="btn-icon-small danger" @click="deleteTodo(item)">✕</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 热力图 -->
    <div class="card">
      <div class="card-title">🔥 每日热力图</div>
      <HeatMap :data="heatMapData" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'
import HeatMap from '../components/HeatMap.vue'

const activeTab = ref('today')
const newTodoTitle = ref('')
const checkinTitle = ref('')
const checkinPattern = ref('daily')
const checkinDays = ref([])
const todos = ref([])
const todaySessions = ref([])

const touchMoments = [
  '完成一件小事，就是给生活种下一颗绿芽。',
  '今天的待办，明天会感谢现在的你。',
  '专注当下，把每个任务都精心完成。',
  '番茄钟里，藏着成长的秘密。',
  '一步一步，温柔但坚定。',
]
const touchMomentText = ref(touchMoments[0])
const refreshTouchMoment = () => {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]
}

const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日']

const incompleteTodos = computed(() => todos.value.filter(t => !t.completed))

const todayTodos = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return todos.value.filter(t => t.category === 'today' && t.due_date === today)
})

const todayCompleted = computed(() => {
  const todayStr = new Date().toISOString().split('T')[0]
  return todos.value
    .filter(t => t.completed && t.completed_at && t.completed_at.startsWith(todayStr))
    .sort((a, b) => (b.completed_at || '').localeCompare(a.completed_at || ''))
})

const weekTodos = computed(() => todos.value.filter(t => t.category === 'week'))

const noneTodos = computed(() => todos.value.filter(t => t.category === 'none'))

const checkinTodos = computed(() => todos.value.filter(t => t.category && t.category.startsWith('checkin-')))

const heatMapData = computed(() => {
  const completionMap = {}
  todos.value.filter(t => t.completed && t.completed_at).forEach(t => {
    const date = t.completed_at.split('T')[0]
    completionMap[date] = (completionMap[date] || 0) + 1
  })
  return completionMap
})

// 今日统计
const todayFocusMinutes = computed(() => {
  return Math.round(todaySessions.value.reduce((s, r) => s + (r.duration || 0), 0) / 60)
})

const todaySessionsCount = computed(() => todaySessions.value.length)

const todayCompletedCount = computed(() => todayCompleted.value.length)

const todayPendingCount = computed(() => {
  const todayStr = new Date().toISOString().split('T')[0]
  return todos.value.filter(t => !t.completed && t.category === 'today' && t.due_date === todayStr).length
})

// 圆环：以 60 分钟为 100%（可设定）
const ringCircumference = 2 * Math.PI * 58
const ringDashoffset = computed(() => {
  const progress = Math.min(todayFocusMinutes.value / 120, 1)  // 120分钟满
  return ringCircumference - progress * ringCircumference
})

// 番茄钟
const pomodoroMode = ref('countdown')
const focusMinutes = ref(25)
const remainingSeconds = ref(25 * 60)
const elapsedSeconds = ref(0)
const isRunning = ref(false)
const isPaused = ref(false)
const selectedTodoId = ref(null)
let timer = null

const formattedTime = computed(() => {
  const seconds = pomodoroMode.value === 'countdown' ? remainingSeconds.value : elapsedSeconds.value
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
})

const pomodoroStatus = computed(() => {
  if (!isRunning.value && !isPaused.value) return '点击开始进入专注状态'
  if (isRunning.value) return '⏳ 专注中...'
  if (isPaused.value) return '⏸️ 已暂停'
  return ''
})

function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return `${d.getMonth() + 1}/${d.getDate()}`
}

function formatTime(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const h = String(d.getHours()).padStart(2, '0')
  const m = String(d.getMinutes()).padStart(2, '0')
  return `${h}:${m}`
}

function getPatternLabel(pattern, days) {
  if (pattern === 'daily') return '每天'
  if (pattern === 'weekly') return '每周'
  if (pattern === 'specific' && days) {
    return days.map(d => `周${weekdayLabels[d - 1]}`).join('/')
  }
  return ''
}

function isCheckinToday(item) {
  if (item.checkin_pattern === 'daily') return true
  if (item.checkin_pattern === 'weekly') return true
  if (item.checkin_pattern === 'specific' && item.checkin_days) {
    const today = new Date().getDay() || 7
    return item.checkin_days.includes(today)
  }
  return false
}

function isCheckedIn(item) {
  const today = new Date().toISOString().split('T')[0]
  return item.completed && item.completed_at && item.completed_at.startsWith(today)
}

async function loadTodos() {
  try {
    const { data } = await supabase
      .from(TABLES.TODOS)
      .select('*')
      .order('created_at', { ascending: false })
    todos.value = (data || []).map(t => ({
      ...t,
      checkin_days: t.checkin_days || [],
    }))
  } catch (e) { console.warn(e) }
}

async function loadTodaySessions() {
  try {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const { data } = await supabase
      .from(TABLES.TODO_SESSIONS)
      .select('*')
      .gte('created_at', today.toISOString())
    todaySessions.value = data || []
  } catch (e) { console.warn(e) }
}

async function addTodo() {
  const title = newTodoTitle.value.trim()
  if (!title) return
  const today = new Date().toISOString().split('T')[0]
  try {
    const { data } = await supabase.from(TABLES.TODOS).insert({
      title,
      category: activeTab.value,
      due_date: activeTab.value === 'today' ? today : null,
    }).select()
    if (data) {
      todos.value.unshift(data[0])
    }
    newTodoTitle.value = ''
  } catch (e) { console.error('添加失败', e) }
}

async function addCheckin() {
  const title = checkinTitle.value.trim()
  if (!title) return
  try {
    const { data } = await supabase.from(TABLES.TODOS).insert({
      title,
      category: `checkin-${checkinPattern.value}`,
      checkin_pattern: checkinPattern.value,
      checkin_days: checkinPattern.value === 'specific' ? checkinDays.value : null,
    }).select()
    if (data) {
      todos.value.unshift({ ...data[0], checkin_days: data[0].checkin_days || [] })
    }
    checkinTitle.value = ''
    checkinDays.value = []
  } catch (e) { console.error('添加打卡失败', e) }
}

function toggleDay(day) {
  const idx = checkinDays.value.indexOf(day)
  if (idx >= 0) checkinDays.value.splice(idx, 1)
  else checkinDays.value.push(day)
}

async function toggleTodo(todo) {
  try {
    const completed = !todo.completed
    await supabase.from(TABLES.TODOS).update({
      completed,
      completed_at: completed ? new Date().toISOString() : null,
    }).eq('id', todo.id)
    todo.completed = completed
    todo.completed_at = completed ? new Date().toISOString() : null
  } catch (e) { console.error(e) }
}

async function toggleCheckin(item) {
  const checked = isCheckedIn(item)
  try {
    const completed = !checked
    await supabase.from(TABLES.TODOS).update({
      completed,
      completed_at: completed ? new Date().toISOString() : null,
    }).eq('id', item.id)
    item.completed = completed
    item.completed_at = completed ? new Date().toISOString() : null
  } catch (e) { console.error(e) }
}

async function deleteTodo(todo) {
  if (!confirm('确定删除？')) return
  try {
    await supabase.from(TABLES.TODOS).delete().eq('id', todo.id)
    todos.value = todos.value.filter(t => t.id !== todo.id)
  } catch (e) { console.error(e) }
}

function startTimer() {
  if (pomodoroMode.value === 'countdown') {
    remainingSeconds.value = focusMinutes.value * 60
  } else {
    elapsedSeconds.value = 0
  }
  isRunning.value = true
  isPaused.value = false
  timer = setInterval(() => {
    if (pomodoroMode.value === 'countdown') {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--
      } else {
        finishTimer()
      }
    } else {
      elapsedSeconds.value++
    }
  }, 1000)
}

function pauseTimer() {
  isRunning.value = false
  isPaused.value = true
  clearInterval(timer)
}

function resumeTimer() {
  isRunning.value = true
  isPaused.value = false
  timer = setInterval(() => {
    if (pomodoroMode.value === 'countdown') {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--
      } else {
        finishTimer()
      }
    } else {
      elapsedSeconds.value++
    }
  }, 1000)
}

function stopTimer() {
  clearInterval(timer)
  timer = null
  isRunning.value = false
  isPaused.value = false
  remainingSeconds.value = focusMinutes.value * 60
  elapsedSeconds.value = 0
  selectedTodoId.value = null
}

async function finishTimer() {
  clearInterval(timer)
  timer = null
  isRunning.value = false
  isPaused.value = false

  const elapsed = pomodoroMode.value === 'countdown'
    ? focusMinutes.value * 60
    : elapsedSeconds.value

  if (elapsed > 5) {
    try {
      await supabase.from(TABLES.TODO_SESSIONS).insert({
        todo_id: selectedTodoId.value,
        duration: elapsed,
        mode: pomodoroMode.value,
        planned_minutes: pomodoroMode.value === 'countdown' ? focusMinutes.value : null,
      })
    } catch (e) { console.error(e) }
  }

  remainingSeconds.value = focusMinutes.value * 60
  elapsedSeconds.value = 0
  selectedTodoId.value = null
  loadTodaySessions()

  if (navigator.vibrate) navigator.vibrate([200, 100, 200])
  if (Notification.permission === 'granted') {
    new Notification('🍅 番茄钟完成', { body: '该休息一下啦！' })
  }
}

onMounted(() => {
  refreshTouchMoment()
  loadTodos()
  loadTodaySessions()
  if (Notification.permission === 'default') {
    Notification.requestPermission()
  }
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.title-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--primary-bg);
  color: var(--primary-dark);
  font-size: 12px;
  font-weight: 600;
  margin-left: 6px;
}

/* 时间环状总结 */
.summary-card {
  background: linear-gradient(135deg, var(--card-bg) 0%, var(--bg-warm) 100%);
}

.ring-row {
  display: flex;
  align-items: center;
  gap: 24px;
}

.ring-progress {
  position: relative;
  width: 140px;
  height: 140px;
  flex-shrink: 0;
}

.ring-circle {
  transition: stroke-dashoffset 0.6s ease;
}

.ring-text {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.ring-value {
  font-size: 32px;
  font-weight: 700;
  color: var(--primary-dark);
  line-height: 1;
  font-variant-numeric: tabular-nums;
  font-family: var(--font-serif);
}

.ring-unit {
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 2px;
}

.ring-label {
  font-size: 11px;
  color: var(--text-secondary);
  margin-top: 6px;
  letter-spacing: 1px;
}

.ring-stats {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.rs-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.rs-num {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
}

.rs-label {
  font-size: 12px;
  color: var(--text-muted);
}

/* 完成列表 */
.completed-card {
  padding: 16px;
}

.completed-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
  border-bottom: 1px solid var(--border-soft);
}

.completed-item:last-child {
  border-bottom: none;
}

.completed-check {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--primary-color);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}

.completed-info {
  flex: 1;
  min-width: 0;
}

.completed-title {
  font-size: 14px;
  color: var(--text-primary);
  text-decoration: line-through;
  opacity: 0.7;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.completed-time {
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 2px;
}

/* 番茄钟 */
.pomodoro-card {
  text-align: center;
}

.pomodoro-mode {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-bottom: 12px;
}

.mode-btn {
  padding: 4px 14px;
  border-radius: 14px;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 12px;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.2s;
}

.mode-btn.active {
  background: var(--primary-bg);
  border-color: var(--primary-light);
  color: var(--primary-dark);
}

.pomodoro-timer {
  font-size: 56px;
  font-weight: 700;
  color: var(--primary-dark);
  font-variant-numeric: tabular-nums;
  letter-spacing: 4px;
  margin: 8px 0;
  font-family: var(--font-serif);
}

.pomodoro-status {
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 16px;
}

.pomodoro-actions {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-bottom: 12px;
}

.pomodoro-select {
  font-size: 13px;
  color: var(--text-secondary);
}

.add-todo-row {
  display: flex;
  gap: 8px;
}

.add-todo-row .input {
  flex: 1;
}

.todo-card {
  padding: 14px;
}

.todo-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.todo-checkbox {
  width: 18px;
  height: 18px;
  accent-color: var(--primary-color);
  cursor: pointer;
}

.todo-text {
  flex: 1;
  font-size: 14px;
}

.todo-text.done {
  text-decoration: line-through;
  color: var(--text-muted);
}

.todo-date {
  font-size: 12px;
  color: var(--text-muted);
}

/* 打卡 */
.checkin-pattern-row {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-top: 10px;
}

.checkin-label {
  font-size: 13px;
  color: var(--text-secondary);
}

.pattern-btn {
  padding: 5px 12px;
  border-radius: 14px;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 12px;
  color: var(--text-secondary);
  cursor: pointer;
}

.pattern-btn.active {
  background: var(--primary-bg);
  border-color: var(--primary-light);
  color: var(--primary-dark);
}

.weekday-row {
  display: flex;
  gap: 6px;
  margin-top: 10px;
}

.weekday-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 13px;
  color: var(--text-secondary);
  cursor: pointer;
}

.weekday-btn.active {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.checkin-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.checkin-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
}

.checkin-name {
  font-size: 14px;
  font-weight: 500;
}

.checkin-meta {
  font-size: 12px;
  color: var(--text-muted);
}

.checkin-actions {
  display: flex;
  gap: 6px;
  align-items: center;
}

.checkin-btn {
  padding: 6px 14px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--primary-light);
  background: var(--primary-bg);
  color: var(--primary-dark);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}

.checkin-btn.done {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.checkin-rest {
  font-size: 12px;
  color: var(--text-muted);
}

.btn-icon-small {
  width: 24px;
  height: 24px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
}

.btn-icon-small.danger {
  color: var(--danger-color);
}

@media (max-width: 480px) {
  .ring-row {
    flex-direction: column;
    gap: 16px;
  }

  .ring-stats {
    flex-direction: row;
    justify-content: space-around;
    width: 100%;
  }
}
</style>
