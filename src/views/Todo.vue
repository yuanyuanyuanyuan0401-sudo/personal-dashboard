<template>
  <div class="todo-page">
    <div class="page-header">
      <h1 class="page-title">待办事项</h1>
    </div>

    <!-- 番茄钟 -->
    <div class="card pomodoro-card">
      <div class="card-title">🍅 番茄钟</div>
      <div class="pomodoro-timer">{{ formattedTime }}</div>
      <div class="pomodoro-status">{{ pomodoroStatus }}</div>
      <div class="pomodoro-actions">
        <button v-if="!isRunning && !isPaused" class="btn btn-primary" @click="startTimer">开始专注</button>
        <button v-if="isRunning" class="btn btn-danger" @click="pauseTimer">暂停</button>
        <button v-if="isPaused" class="btn btn-primary" @click="resumeTimer">继续</button>
        <button v-if="isRunning || isPaused" class="btn btn-secondary" @click="stopTimer">停止</button>
      </div>
      <div class="pomodoro-select">
        <label>专注时长：</label>
        <select v-model="focusMinutes" :disabled="isRunning || isPaused" class="input" style="width:auto;display:inline-block;padding:4px 8px;">
          <option :value="15">15分钟</option>
          <option :value="25">25分钟</option>
          <option :value="30">30分钟</option>
          <option :value="45">45分钟</option>
          <option :value="60">60分钟</option>
        </select>
      </div>
    </div>

    <!-- 关联待办 -->
    <div class="card">
      <div class="card-title">关联待办（可选）</div>
      <select v-model="selectedTodoId" class="input">
        <option :value="null">不关联，自由专注</option>
        <option v-for="t in todos" :key="t.id" :value="t.id" :disabled="t.completed">
          {{ t.title }}
        </option>
      </select>
    </div>

    <!-- 添加待办 -->
    <div class="card">
      <div class="todo-add-row">
        <input v-model="newTodo" class="input" placeholder="添加新待办..." @keyup.enter="addTodo" />
        <button class="btn btn-primary" @click="addTodo" style="white-space:nowrap;">添加</button>
      </div>
    </div>

    <!-- 进行中 -->
    <div class="card" v-if="activeTodos.length > 0">
      <div class="card-title">进行中</div>
      <div v-for="todo in activeTodos" :key="todo.id" class="todo-row">
        <label class="todo-checkbox">
          <input type="checkbox" :checked="todo.completed" @change="toggleTodo(todo)" />
          <span>{{ todo.title }}</span>
        </label>
        <div class="todo-actions">
          <button class="btn-icon-small" @click="startTodoTimer(todo)" title="开始专注">🍅</button>
          <button class="btn-icon-small danger" @click="deleteTodo(todo)" title="删除">✕</button>
        </div>
      </div>
    </div>

    <!-- 已完成 -->
    <div class="card" v-if="completedTodos.length > 0">
      <div class="card-title">
        已完成
        <span class="badge">{{ completedTodos.length }}</span>
      </div>
      <div v-for="todo in completedTodos" :key="todo.id" class="todo-row done">
        <label class="todo-checkbox">
          <input type="checkbox" checked @change="toggleTodo(todo)" />
          <span class="done-text">{{ todo.title }}</span>
        </label>
        <div class="todo-actions">
          <button class="btn-icon-small danger" @click="deleteTodo(todo)" title="删除">✕</button>
        </div>
      </div>
    </div>

    <!-- 今日专注统计 -->
    <div class="card" v-if="todaySessions.length > 0">
      <div class="card-title">今日专注</div>
      <div class="session-stats">
        <span>完成 <strong>{{ todaySessions.length }}</strong> 个番茄</span>
        <span>共 <strong>{{ todayFocusMinutes }}</strong> 分钟</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const newTodo = ref('')
const todos = ref([])
const selectedTodoId = ref(null)

// 番茄钟
const focusMinutes = ref(25)
const remainingSeconds = ref(25 * 60)
const isRunning = ref(false)
const isPaused = ref(false)
let timer = null
let sessionStart = null

const startTime = ref(null)
const pauseStartTime = ref(null)
const totalPausedSeconds = ref(0)

const todaySessions = ref([])

const activeTodos = computed(() => todos.value.filter(t => !t.completed))
const completedTodos = computed(() => todos.value.filter(t => t.completed))

const formattedTime = computed(() => {
  const m = Math.floor(remainingSeconds.value / 60)
  const s = remainingSeconds.value % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
})

const pomodoroStatus = computed(() => {
  if (!isRunning.value && !isPaused.value) return '点击"开始专注"进入番茄钟'
  if (isRunning.value) return '⏳ 专注中...'
  if (isPaused.value) return '⏸️ 已暂停'
  return ''
})

const todayFocusMinutes = computed(() => {
  return Math.round(todaySessions.value.reduce((s, r) => s + (r.duration || 0), 0) / 60)
})

async function loadTodos() {
  try {
    const { data } = await supabase
      .from(TABLES.TODOS)
      .select('*')
      .order('created_at', { ascending: false })
    todos.value = data || []
  } catch (e) {
    console.warn('数据加载失败', e)
  }
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
  } catch (e) {
    console.warn(e)
  }
}

async function addTodo() {
  const title = newTodo.value.trim()
  if (!title) return
  try {
    const { data } = await supabase.from(TABLES.TODOS).insert({ title }).select()
    if (data) todos.value.unshift(data[0])
    newTodo.value = ''
  } catch (e) {
    console.error('添加失败', e)
  }
}

async function toggleTodo(todo) {
  try {
    await supabase.from(TABLES.TODOS).update({ completed: !todo.completed }).eq('id', todo.id)
    todo.completed = !todo.completed
  } catch (e) {
    console.error('更新失败', e)
  }
}

async function deleteTodo(todo) {
  try {
    await supabase.from(TABLES.TODOS).delete().eq('id', todo.id)
    todos.value = todos.value.filter(t => t.id !== todo.id)
  } catch (e) {
    console.error('删除失败', e)
  }
}

function startTodoTimer(todo) {
  selectedTodoId.value = todo.id
  focusMinutes.value = 25
  startTimer()
}

function startTimer() {
  remainingSeconds.value = focusMinutes.value * 60
  isRunning.value = true
  isPaused.value = false
  sessionStart = Date.now()
  startTime.value = Date.now()
  totalPausedSeconds.value = 0

  timer = setInterval(() => {
    if (remainingSeconds.value > 0) {
      remainingSeconds.value--
    } else {
      finishTimer()
    }
  }, 1000)
}

function pauseTimer() {
  isRunning.value = false
  isPaused.value = true
  pauseStartTime.value = Date.now()
  clearInterval(timer)
}

function resumeTimer() {
  if (pauseStartTime.value) {
    totalPausedSeconds.value += (Date.now() - pauseStartTime.value) / 1000
    pauseStartTime.value = null
  }
  isRunning.value = true
  isPaused.value = false
  timer = setInterval(() => {
    if (remainingSeconds.value > 0) {
      remainingSeconds.value--
    } else {
      finishTimer()
    }
  }, 1000)
}

function stopTimer() {
  clearInterval(timer)
  timer = null
  isRunning.value = false
  isPaused.value = false
  remainingSeconds.value = focusMinutes.value * 60
  selectedTodoId.value = null
}

async function finishTimer() {
  clearInterval(timer)
  timer = null
  isRunning.value = false
  isPaused.value = false

  const elapsed = focusMinutes.value * 60
  const sessionData = {
    duration: elapsed,
    todo_id: selectedTodoId.value,
    completed_at: new Date().toISOString(),
  }

  try {
    await supabase.from(TABLES.TODO_SESSIONS).insert(sessionData)
  } catch (e) {
    console.error('保存专注记录失败', e)
  }

  remainingSeconds.value = focusMinutes.value * 60
  selectedTodoId.value = null
  loadTodaySessions()

  // 手机震动反馈
  if (navigator.vibrate) navigator.vibrate([200, 100, 200])
}

onMounted(() => {
  loadTodos()
  loadTodaySessions()
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.pomodoro-card {
  text-align: center;
}
.pomodoro-timer {
  font-size: 56px;
  font-weight: 700;
  color: var(--primary-color);
  font-variant-numeric: tabular-nums;
  letter-spacing: 4px;
  margin: 8px 0;
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

.todo-add-row {
  display: flex;
  gap: 8px;
}
.todo-add-row .input {
  flex: 1;
}

.todo-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
}
.todo-row + .todo-row {
  border-top: 1px solid var(--border-color);
}
.todo-row.done .done-text {
  text-decoration: line-through;
  color: var(--text-muted);
}

.todo-checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 14px;
  flex: 1;
}
.todo-checkbox input[type="checkbox"] {
  width: 18px;
  height: 18px;
  accent-color: var(--primary-color);
}

.todo-actions {
  display: flex;
  gap: 4px;
}

.btn-icon-small {
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 50%;
  background: transparent;
  font-size: 14px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}
.btn-icon-small:hover {
  background: var(--bg-color);
}
.btn-icon-small.danger {
  color: var(--danger-color);
}

.badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--primary-bg);
  color: var(--primary-color);
  font-size: 12px;
  font-weight: 600;
  margin-left: 6px;
}

.session-stats {
  display: flex;
  gap: 24px;
  font-size: 14px;
  color: var(--text-secondary);
}
.session-stats strong {
  color: var(--text-primary);
}
</style>
