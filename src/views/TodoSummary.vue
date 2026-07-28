<template>
  <div class="summary-page">
    <div class="sub-header">
      <router-link to="/todo" class="back-btn">← 返回</router-link>
      <span class="sub-title">📊 今日完成汇总</span>
    </div>

    <!-- 圆环 -->
    <div class="card hero-card">
      <div class="hero-date">{{ today }}</div>
      <div class="ring-progress big">
        <svg width="180" height="180" viewBox="0 0 180 180">
          <circle cx="90" cy="90" r="75" fill="none" stroke="var(--primary-bg)" stroke-width="14" />
          <circle
            cx="90" cy="90" r="75" fill="none"
            stroke="var(--primary-color)" stroke-width="14"
            stroke-linecap="round"
            :stroke-dasharray="circumference"
            :stroke-dashoffset="dashoffset"
            class="ring-circle"
          />
        </svg>
        <div class="ring-progress-text">
          <div class="ring-progress-value">{{ completionRate }}%</div>
          <div class="ring-progress-label">完成率</div>
        </div>
      </div>
      <div class="hero-stats">
        <div class="hs-item">
          <span class="hs-value">{{ completedCount }}</span>
          <span class="hs-label">已完成</span>
        </div>
        <div class="hs-divider"></div>
        <div class="hs-item">
          <span class="hs-value">{{ totalCount }}</span>
          <span class="hs-label">总待办</span>
        </div>
        <div class="hs-divider"></div>
        <div class="hs-item">
          <span class="hs-value">{{ focusMinutes }}</span>
          <span class="hs-label">专注分钟</span>
        </div>
      </div>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ momentText }}</div>
    </div>

    <!-- 各模块完成情况 -->
    <div class="card">
      <div class="card-title">各模块完成情况</div>
      <div class="module-ring-row">
        <div class="module-item">
          <div class="module-ring">
            <svg width="80" height="80" viewBox="0 0 80 80">
              <circle cx="40" cy="40" r="32" fill="none" stroke="var(--primary-bg)" stroke-width="6" />
              <circle cx="40" cy="40" r="32" fill="none" stroke="var(--primary-color)" stroke-width="6"
                stroke-linecap="round"
                :stroke-dasharray="ringCircumference"
                :stroke-dashoffset="moduleRingOffset('todo')" />
            </svg>
            <div class="module-ring-text">{{ moduleRate('todo') }}%</div>
          </div>
          <span class="module-name">待办</span>
        </div>
        <div class="module-item">
          <div class="module-ring">
            <svg width="80" height="80" viewBox="0 0 80 80">
              <circle cx="40" cy="40" r="32" fill="none" stroke="var(--primary-bg)" stroke-width="6" />
              <circle cx="40" cy="40" r="32" fill="none" stroke="var(--accent-rose)" stroke-width="6"
                stroke-linecap="round"
                :stroke-dasharray="ringCircumference"
                :stroke-dashoffset="moduleRingOffset('sport')" />
            </svg>
            <div class="module-ring-text">{{ moduleRate('sport') }}%</div>
          </div>
          <span class="module-name">运动</span>
        </div>
        <div class="module-item">
          <div class="module-ring">
            <svg width="80" height="80" viewBox="0 0 80 80">
              <circle cx="40" cy="40" r="32" fill="none" stroke="var(--primary-bg)" stroke-width="6" />
              <circle cx="40" cy="40" r="32" fill="none" stroke="var(--accent-blue)" stroke-width="6"
                stroke-linecap="round"
                :stroke-dasharray="ringCircumference"
                :stroke-dashoffset="moduleRingOffset('read')" />
            </svg>
            <div class="module-ring-text">{{ moduleRate('read') }}%</div>
          </div>
          <span class="module-name">阅读</span>
        </div>
      </div>
    </div>

    <!-- 趋势 -->
    <div class="card">
      <div class="card-title">最近 7 天完成趋势</div>
      <div class="trend-bars">
        <div v-for="day in last7Days" :key="day.date" class="trend-bar-col">
          <div class="trend-bar-wrap">
            <div class="trend-bar" :style="{ height: day.percent + '%' }">
              <span class="trend-num">{{ day.value }}</span>
            </div>
          </div>
          <span class="trend-day">{{ day.label }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const today = ref('')
const completedCount = ref(0)
const totalCount = ref(0)
const focusMinutes = ref(0)
const todos = ref([])
const sports = ref([])
const readingSessions = ref([])
const ringCircumference = 2 * Math.PI * 32

const momentTexts = [
  '今天，也是踏踏实实的一天。',
  '你的每一步，都算数。',
  '慢一点没关系，重要的是不停下。',
  '今天的辛苦，是明天的礼物。',
  '所有的小坚持，都是大变化。',
  '你比昨天，又进步了一点。',
]
const momentText = ref(momentTexts[0])

const circumference = 2 * Math.PI * 75
const completionRate = computed(() => {
  if (totalCount.value === 0) return 0
  return Math.round((completedCount.value / totalCount.value) * 100)
})
const dashoffset = computed(() => circumference - (completionRate.value / 100) * circumference)

const last7Days = computed(() => {
  const result = []
  const max = Math.max(1, ...Object.values(completionByDay.value))
  for (let i = 6; i >= 0; i--) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    const dateStr = d.toISOString().split('T')[0]
    const value = completionByDay.value[dateStr] || 0
    const weekdays = ['日', '一', '二', '三', '四', '五', '六']
    result.push({
      date: dateStr,
      value,
      label: weekdays[d.getDay()],
      percent: (value / max) * 100,
    })
  }
  return result
})

const completionByDay = ref({})

function moduleRate(type) {
  if (type === 'todo') {
    return totalCount.value === 0 ? 0 : Math.round((completedCount.value / totalCount.value) * 100)
  }
  if (type === 'sport') {
    const todayStr = new Date().toISOString().split('T')[0]
    const todaySports = sports.value.filter(s => s.date === todayStr)
    return todaySports.length > 0 ? 100 : 0
  }
  if (type === 'read') {
    const todayStr = new Date().toISOString().split('T')[0]
    const todayReads = readingSessions.value.filter(r => r.created_at.startsWith(todayStr))
    return todayReads.length > 0 ? 100 : 0
  }
  return 0
}

function moduleRingOffset(type) {
  return ringCircumference - (moduleRate(type) / 100) * ringCircumference
}

function formatDate() {
  const d = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 星期${weekdays[d.getDay()]}`
}

async function loadData() {
  const d = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  today.value = `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 星期${weekdays[d.getDay()]}`
  momentText.value = momentTexts[Math.floor(Math.random() * momentTexts.length)]

  const todayStr = d.toISOString().split('T')[0]
  const weekStart = new Date(d)
  weekStart.setDate(d.getDate() - 6)
  weekStart.setHours(0, 0, 0, 0)

  try {
    // 待办
    const { data: todosData } = await supabase.from(TABLES.TODOS).select('*')
    todos.value = todosData || []
    const today_todos = todos.value.filter(t => t.due_date === todayStr)
    totalCount.value = today_todos.length
    completedCount.value = today_todos.filter(t => t.completed).length

    // 计算最近7天完成数
    const sevenDayAgo = new Date(d)
    sevenDayAgo.setDate(d.getDate() - 6)
    const map = {}
    todos.value.forEach(t => {
      if (t.completed && t.completed_at) {
        const date = t.completed_at.split('T')[0]
        if (new Date(date) >= sevenDayAgo) {
          map[date] = (map[date] || 0) + 1
        }
      }
    })
    completionByDay.value = map

    // 今日专注
    const { data: sessions } = await supabase
      .from(TABLES.TODO_SESSIONS)
      .select('*')
      .gte('created_at', new Date(d.setHours(0, 0, 0, 0)).toISOString())
    focusMinutes.value = Math.round((sessions || []).reduce((s, r) => s + (r.duration || 0), 0) / 60)

    // 运动
    const { data: sportsData } = await supabase.from(TABLES.SPORTS).select('*')
    sports.value = sportsData || []

    // 阅读
    const { data: reads } = await supabase.from(TABLES.READING_SESSIONS).select('*')
    readingSessions.value = reads || []
  } catch (e) { console.warn(e) }
}

onMounted(loadData)
</script>

<style scoped>
.hero-card {
  padding: 24px 16px;
  text-align: center;
}

.hero-date {
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 16px;
  letter-spacing: 0.5px;
}

.ring-progress.big {
  margin: 0 auto 20px;
}

.ring-circle {
  transition: stroke-dashoffset 0.6s ease;
}

.hero-stats {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 24px;
  padding-top: 8px;
}

.hs-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.hs-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--primary-dark);
}

.hs-label {
  font-size: 12px;
  color: var(--text-muted);
}

.hs-divider {
  width: 1px;
  height: 36px;
  background: var(--border-color);
}

.module-ring-row {
  display: flex;
  justify-content: space-around;
  padding: 8px 0;
}

.module-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.module-ring {
  position: relative;
  width: 80px;
  height: 80px;
}

.module-ring-text {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 700;
  color: var(--text-primary);
}

.module-name {
  font-size: 13px;
  color: var(--text-secondary);
}

.trend-bars {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  height: 130px;
  padding: 12px 0 0;
  gap: 4px;
}

.trend-bar-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.trend-bar-wrap {
  flex: 1;
  width: 100%;
  display: flex;
  align-items: flex-end;
}

.trend-bar {
  width: 100%;
  background: linear-gradient(180deg, var(--primary-light), var(--primary-color));
  border-radius: 4px 4px 0 0;
  position: relative;
  min-height: 4px;
  transition: height 0.5s ease;
}

.trend-num {
  position: absolute;
  top: -18px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 11px;
  color: var(--text-muted);
}

.trend-day {
  font-size: 11px;
  color: var(--text-muted);
}
</style>
