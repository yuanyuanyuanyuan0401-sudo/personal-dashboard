<template>
  <div class="dashboard">
    <!-- 顶部欢迎区 -->
    <div class="dashboard-header">
      <div class="header-greeting">
        <span class="greeting-date">{{ today }}</span>
        <h1 class="greeting-text">{{ greeting }},
          <span class="greeting-name">luna</span>
        </h1>
      </div>
      <div class="header-tags">
        <span class="header-tag">📚 教学 1 天</span>
        <span class="header-tag">💪 运动 0 天</span>
      </div>
    </div>

    <!-- 今日完成情况 -->
    <div class="completion-card">
      <div class="completion-text">
        <span class="completion-label">今日完成率</span>
        <span class="completion-value">{{ completionRate }}%</span>
      </div>
      <div class="completion-bar">
        <div class="completion-bar-fill" :style="{ width: completionRate + '%' }"></div>
      </div>
    </div>

    <!-- 圆环展示 -->
    <div class="card ring-summary-card">
      <div class="card-title">📊 今日完成情况</div>
      <div class="ring-content">
        <div class="ring-progress">
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="50" fill="none" stroke="var(--primary-bg)" stroke-width="10" />
            <circle
              cx="60" cy="60" r="50" fill="none"
              stroke="var(--primary-color)" stroke-width="10"
              stroke-linecap="round"
              :stroke-dasharray="circumference"
              :stroke-dashoffset="dashoffset"
              class="ring-circle"
            />
          </svg>
          <div class="ring-progress-text">
            <div class="ring-progress-value">{{ completionRate }}%</div>
            <div class="ring-progress-label">已完成</div>
          </div>
        </div>
        <div class="ring-stats">
          <div class="rs-item">
            <span class="rs-value">{{ todayCompleted }}</span>
            <span class="rs-label">已完成</span>
          </div>
          <div class="rs-item">
            <span class="rs-value">{{ todayTodos - todayCompleted }}</span>
            <span class="rs-label">待办</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 快捷入口 -->
    <div class="quick-grid">
      <router-link to="/todo" class="quick-card">
        <span class="qc-icon">✅</span>
        <span class="qc-label">待办</span>
        <span class="qc-count">{{ todayTodos }}</span>
      </router-link>
      <router-link to="/work" class="quick-card">
        <span class="qc-icon">📚</span>
        <span class="qc-label">工作</span>
        <span class="qc-count">{{ workCount }}</span>
      </router-link>
      <router-link to="/sports" class="quick-card">
        <span class="qc-icon">💪</span>
        <span class="qc-label">运动</span>
        <span class="qc-count">{{ sportCount }}</span>
      </router-link>
      <router-link to="/reading" class="quick-card">
        <span class="qc-icon">📖</span>
        <span class="qc-label">阅读</span>
        <span class="qc-count">{{ readingCount }}</span>
      </router-link>
      <router-link to="/snippets" class="quick-card wide">
        <span class="qc-icon">💭</span>
        <span class="qc-label">碎碎念</span>
        <span class="qc-count">{{ snippetCount }}</span>
      </router-link>
    </div>

    <!-- 今日待办 -->
    <div class="card" v-if="todayTodoList.length > 0">
      <div class="card-title">今日待办</div>
      <div v-for="todo in todayTodoList" :key="todo.id" class="todo-row">
        <span class="todo-mark" :class="{ done: todo.completed }">
          {{ todo.completed ? '✅' : '◻️' }}
        </span>
        <span class="todo-text" :class="{ done: todo.completed }">{{ todo.title }}</span>
      </div>
    </div>

    <!-- 三个感激小事 -->
    <div class="card" v-if="todayGratitudes.length > 0">
      <div class="card-title">💗 今日三件感恩小事</div>
      <div class="gratitude-list">
        <div v-for="(g, idx) in todayGratitudes" :key="idx" class="gratitude-item">
          <span class="gratitude-num">{{ idx + 1 }}</span>
          <span class="gratitude-text">{{ g }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const today = ref('')
const todayTodos = ref(0)
const todayCompleted = ref(0)
const todayTodoList = ref([])
const workCount = ref(0)
const sportCount = ref(0)
const readingCount = ref(0)
const snippetCount = ref(0)
const todayGratitudes = ref([])

const circumference = 2 * Math.PI * 50
const completionRate = computed(() => {
  if (todayTodos.value === 0) return 0
  return Math.round((todayCompleted.value / todayTodos.value) * 100)
})
const dashoffset = computed(() => circumference - (completionRate.value / 100) * circumference)

const greeting = computed(() => {
  const h = new Date().getHours()
  if (h < 6) return '夜深了'
  if (h < 11) return '早上好'
  if (h < 14) return '中午好'
  if (h < 18) return '下午好'
  return '晚上好'
})

const touchMoments = [
  '生活的每一刻，都值得被温柔以待。',
  '心怀春天，四季如春。',
  '用心记录，时光就有了温度。',
  '小小的进步，也是大大的成长。',
  '慢慢来，比较快。',
  '今天也是，被光照亮的一天。',
  '别忘了，给自己一个微笑。',
  '愿你眼里有光，心中有爱。',
  '所有的小事，都是大事。',
  '与时光同行，与自己对话。',
]

const touchMomentText = ref('')

function formatDate() {
  const d = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 星期${weekdays[d.getDay()]}`
}

function refreshTouchMoment() {
  const idx = Math.floor(Math.random() * touchMoments.length)
  touchMomentText.value = touchMoments[idx]
}

async function loadData() {
  today.value = formatDate()
  refreshTouchMoment()

  try {
    const todayStr = new Date().toISOString().split('T')[0]

    // 待办
    const { data: todos } = await supabase
      .from(TABLES.TODOS)
      .select('*')
      .eq('due_date', todayStr)
    const allTodos = todos || []
    todayTodos.value = allTodos.length
    todayCompleted.value = allTodos.filter(t => t.completed).length
    todayTodoList.value = allTodos.filter(t => !t.completed).slice(0, 5)

    // 工作
    const { count: w } = await supabase.from(TABLES.WORK_FILES).select('*', { count: 'exact', head: true })
    workCount.value = w || 0

    // 运动
    const { count: s } = await supabase.from(TABLES.SPORTS).select('*', { count: 'exact', head: true })
    sportCount.value = s || 0

    // 阅读
    const { count: r } = await supabase.from(TABLES.READING_BOOKS).select('*', { count: 'exact', head: true })
    readingCount.value = r || 0

    // 碎碎念
    const { count: sn } = await supabase.from(TABLES.SNIPPETS).select('*', { count: 'exact', head: true })
    snippetCount.value = sn || 0

    // 今日三件感恩
    const { data: gratitudes } = await supabase
      .from(TABLES.GRATITUDES)
      .select('*')
      .eq('date', todayStr)
      .single()
    if (gratitudes) {
      todayGratitudes.value = [
        gratitudes.item1,
        gratitudes.item2,
        gratitudes.item3,
      ].filter(Boolean)
    }
  } catch (e) {
    console.warn('数据加载失败', e)
  }
}

onMounted(loadData)
</script>

<style scoped>
.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 16px 8px;
  background: linear-gradient(180deg, var(--bg-warm) 0%, var(--bg-color) 100%);
}

.header-greeting {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.greeting-date {
  font-size: 12px;
  color: var(--text-secondary);
  letter-spacing: 0.5px;
}

.greeting-text {
  font-size: 22px;
  font-weight: 700;
  color: var(--text-primary);
}

.greeting-name {
  color: var(--primary-dark);
  font-family: var(--font-serif);
  font-weight: 600;
  letter-spacing: 2px;
}

.header-tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.header-tag {
  padding: 4px 10px;
  background: var(--card-bg);
  border: 1px solid var(--border-soft);
  border-radius: 20px;
  font-size: 11px;
  color: var(--text-secondary);
}

/* 完成率 */
.completion-card {
  margin: 0 16px 14px;
  padding: 14px 16px;
  background: var(--card-bg);
  border-radius: var(--radius-md);
  border: 1px solid var(--border-soft);
}

.completion-text {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 8px;
}

.completion-label {
  font-size: 13px;
  color: var(--text-secondary);
}

.completion-value {
  font-size: 20px;
  font-weight: 700;
  color: var(--primary-dark);
}

.completion-bar {
  height: 6px;
  background: var(--primary-bg);
  border-radius: 3px;
  overflow: hidden;
}

.completion-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary-light), var(--primary-color));
  border-radius: 3px;
  transition: width 0.6s ease;
}

/* 圆环 */
.ring-summary-card {
  padding: 18px;
}

.ring-content {
  display: flex;
  align-items: center;
  gap: 24px;
}

.ring-circle {
  transition: stroke-dashoffset 0.6s ease;
}

.ring-stats {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.rs-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.rs-value {
  font-size: 22px;
  font-weight: 700;
  color: var(--primary-dark);
}

.rs-label {
  font-size: 12px;
  color: var(--text-muted);
}

/* 快捷入口 */
.quick-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  padding: 0 16px 14px;
}

.quick-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 14px 6px;
  background: var(--card-bg);
  border-radius: var(--radius-md);
  border: 1px solid var(--border-soft);
  text-decoration: none;
  transition: transform 0.15s;
}

.quick-card.wide {
  grid-column: span 4;
  flex-direction: row;
  justify-content: flex-start;
  padding: 14px 18px;
  gap: 12px;
}

.quick-card.wide .qc-icon {
  font-size: 24px;
}

.quick-card.wide .qc-label {
  flex: 1;
  text-align: left;
}

.quick-card:active {
  transform: scale(0.97);
}

.qc-icon {
  font-size: 26px;
}

.qc-label {
  font-size: 12px;
  color: var(--text-secondary);
  font-weight: 500;
}

.qc-count {
  font-size: 16px;
  font-weight: 700;
  color: var(--primary-dark);
}

/* 今日待办 */
.todo-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
  font-size: 14px;
}

.todo-row + .todo-row {
  border-top: 1px solid var(--border-soft);
}

.todo-text {
  color: var(--text-primary);
}

.todo-text.done {
  text-decoration: line-through;
  color: var(--text-muted);
}

.todo-mark.done {
  opacity: 0.6;
}

/* 感恩 */
.gratitude-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.gratitude-item {
  display: flex;
  gap: 10px;
  align-items: flex-start;
}

.gratitude-num {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--accent-rose);
  color: white;
  font-size: 12px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 1px;
}

.gratitude-text {
  font-size: 14px;
  color: var(--text-primary);
  line-height: 1.6;
}
</style>
