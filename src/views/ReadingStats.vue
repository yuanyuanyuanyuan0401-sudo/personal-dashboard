<template>
  <div class="stats-page">
    <div class="sub-header">
      <router-link to="/reading" class="back-btn">←</router-link>
      <span class="sub-title">📊 阅读统计</span>
      <div class="mode-toggle">
        <button :class="['mode-btn', { active: viewMode === 'cover' }]" @click="viewMode = 'cover'">封面图</button>
        <button :class="['mode-btn', { active: viewMode === 'time' }]" @click="viewMode = 'time'">时间</button>
      </div>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 月度统计 -->
    <div class="card">
      <div class="card-title">📅 {{ year }}年{{ month }}月</div>
      <div class="month-nav">
        <button class="month-btn" @click="changeMonth(-1)">‹</button>
        <span class="month-title">{{ year }}年{{ month }}月</span>
        <button class="month-btn" @click="changeMonth(1)">›</button>
      </div>

      <div class="weekday-header">
        <span v-for="d in ['一','二','三','四','五','六','日']" :key="d" class="weekday-label">{{ d }}</span>
      </div>

      <div class="month-grid">
        <div
          v-for="(day, idx) in calendarDays"
          :key="idx"
          :class="['day-cell', {
            empty: !day,
            today: day && isToday(day),
          }]"
          @click="day && showDay(day)"
        >
          <template v-if="day">
            <!-- 封面图模式 -->
            <div v-if="viewMode === 'cover' && day.data && day.data.books && day.data.books.length > 0" class="cover-mode">
              <img :src="day.data.books[0].cover" class="day-cover" :alt="day.data.books[0].title" />
              <span class="day-num-on-cover">{{ day.date.getDate() }}</span>
              <span v-if="day.data.total_minutes" class="day-minutes-on-cover">{{ formatMinutes(day.data.total_minutes) }}</span>
            </div>
            <!-- 时间模式 -->
            <div v-else-if="viewMode === 'time' && day.data && day.data.total_minutes > 0" class="time-mode">
              <span class="day-num">{{ day.date.getDate() }}</span>
              <span class="day-minutes">{{ formatMinutes(day.data.total_minutes) }}</span>
            </div>
            <!-- 普通模式 -->
            <div v-else class="normal-mode">
              <span class="day-num">{{ day.date.getDate() }}</span>
              <span v-if="day.data && day.data.total_minutes" class="day-mark">●</span>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- 月度统计 -->
    <div class="card">
      <div class="card-title">📈 本月统计</div>
      <div class="stat-grid">
        <div class="stat-card">
          <div class="stat-value">{{ monthTotalMinutes }}<span class="stat-unit">m</span></div>
          <div class="stat-label">总时长</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ monthDaysCount }}</div>
          <div class="stat-label">阅读天数</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ monthBooksCount }}</div>
          <div class="stat-label">涉及书数</div>
        </div>
      </div>
    </div>

    <!-- 当日详情 -->
    <div v-if="selectedDay" class="card">
      <div class="card-title">📖 {{ selectedDay.dateStr }}</div>

      <div v-if="dayThoughts.length > 0" class="day-section">
        <div class="day-section-title">💭 今日思考</div>
        <div v-for="t in dayThoughts" :key="t.id" class="day-thought">
          <div class="day-thought-time">{{ formatTime(t.created_at) }}</div>
          <div v-if="thoughtBook(t.book_id)" class="day-thought-book">📖 {{ thoughtBook(t.book_id) }}</div>
          <div class="day-thought-content">{{ t.content }}</div>
        </div>
      </div>

      <div v-if="daySessions.length > 0" class="day-section">
        <div class="day-section-title">📚 阅读时段</div>
        <div v-for="s in daySessions" :key="s.id" class="day-session">
          <div class="day-session-time">{{ formatTime(s.created_at) }}</div>
          <div class="day-session-content">
            <span v-if="thoughtBook(s.book_id)">📖 {{ thoughtBook(s.book_id) }} · </span>
            <span>{{ Math.round(s.duration / 60) }} 分钟</span>
          </div>
        </div>
      </div>

      <div v-if="dayThoughts.length === 0 && daySessions.length === 0" class="empty-state">
        <div class="text">这天没有记录</div>
      </div>
    </div>

    <div v-else class="empty-state">
      <div class="text">点击日期查看当天的阅读记录</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const today = new Date()
const year = ref(today.getFullYear())
const month = ref(today.getMonth() + 1)
const viewMode = ref('time')  // 'cover' | 'time'
const dailyStats = ref([])
const allThoughts = ref([])
const allSessions = ref([])
const allBooks = ref([])
const selectedDay = ref(null)

const touchMoments = [
  '坚持阅读，让每一天都充实。',
  '时间的痕迹，藏在每一页里。',
  '读懂一本书，需要时间的耐心。',
  '让阅读成为习惯。',
  '书页里，藏着和未来的自己。',
]
const touchMomentText = ref(touchMoments[0])

const calendarDays = computed(() => {
  const firstDay = new Date(year.value, month.value - 1, 1)
  const lastDay = new Date(year.value, month.value, 0)
  const startWeekday = firstDay.getDay() || 7
  const days = []
  for (let i = 1; i < startWeekday; i++) days.push(null)
  for (let i = 1; i <= lastDay.getDate(); i++) {
    const date = new Date(year.value, month.value - 1, i)
    const dateStr = dateStr0(date)
    const data = dailyStats.value.find(s => s.date === dateStr)
    days.push({ date, dateStr, data })
  }
  return days
})

const monthTotalMinutes = computed(() => {
  return dailyStats.value.reduce((sum, s) => sum + (s.total_minutes || 0), 0)
})

const monthDaysCount = computed(() => dailyStats.value.filter(s => s.total_minutes > 0).length)

const monthBooksCount = computed(() => {
  const bookIds = new Set()
  dailyStats.value.forEach(s => {
    if (s.books && Array.isArray(s.books)) {
      s.books.forEach(b => bookIds.add(b.bookId))
    }
  })
  return bookIds.size
})

const dayThoughts = computed(() => {
  if (!selectedDay.value) return []
  return allThoughts.value.filter(t => t.date === selectedDay.value.dateStr)
})

const daySessions = computed(() => {
  if (!selectedDay.value) return []
  return allSessions.value.filter(s => s.created_at.startsWith(selectedDay.value.dateStr))
})

function dateStr0(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function isToday(day) {
  return dateStr0(day.date) === dateStr0(today)
}

function formatTime(dateStr) {
  const d = new Date(dateStr)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

function formatMinutes(m) {
  if (m < 60) return `${m}m`
  const h = Math.floor(m / 60)
  const min = m % 60
  return min > 0 ? `${h}h${min}m` : `${h}h`
}

function thoughtBook(id) {
  if (!id) return ''
  const b = allBooks.value.find(x => x.id === id)
  return b ? b.title : ''
}

function showDay(day) {
  selectedDay.value = day
}

function changeMonth(delta) {
  let m = month.value + delta
  let y = year.value
  if (m > 12) { m = 1; y++ }
  if (m < 1) { m = 12; y-- }
  month.value = m
  year.value = y
  loadData()
}

async function loadData() {
  try {
    const monthStart = `${year.value}-${String(month.value).padStart(2, '0')}-01`
    const nextMonth = month.value === 12 ? 1 : month.value + 1
    const nextYear = month.value === 12 ? year.value + 1 : year.value
    const monthEnd = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01`

    const { data: stats } = await supabase
      .from(TABLES.READING_DAILY_STATS)
      .select('*')
      .gte('date', monthStart)
      .lt('date', monthEnd)
    dailyStats.value = stats || []

    const { data: thoughts } = await supabase
      .from(TABLES.READING_DAILY_THOUGHTS)
      .select('*')
      .gte('date', monthStart)
      .lt('date', monthEnd)
      .order('created_at', { ascending: false })
    allThoughts.value = thoughts || []

    const { data: sessions } = await supabase
      .from(TABLES.READING_SESSIONS)
      .select('*')
      .gte('created_at', monthStart)
      .lt('created_at', monthEnd)
      .order('created_at', { ascending: false })
    allSessions.value = sessions || []

    const { data: books } = await supabase.from(TABLES.READING_BOOKS).select('id, title')
    allBooks.value = books || []

    selectedDay.value = null
  } catch (e) { console.warn(e) }
}

onMounted(() => {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]
  loadData()
})
</script>

<style scoped>
.sub-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: var(--card-bg);
  border-bottom: 1px solid var(--border-soft);
}

.sub-title {
  font-size: 18px;
  font-weight: 600;
  flex: 1;
}

.mode-toggle {
  display: flex;
  gap: 4px;
  background: var(--bg-warm);
  border-radius: 20px;
  padding: 3px;
}

.mode-btn {
  padding: 4px 12px;
  border: none;
  border-radius: 16px;
  background: transparent;
  font-size: 12px;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.2s;
}

.mode-btn.active {
  background: var(--card-bg);
  color: var(--primary-dark);
  box-shadow: var(--shadow-sm);
}

.month-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-bottom: 12px;
}

.month-btn {
  width: 30px;
  height: 30px;
  border: 1px solid var(--border-color);
  border-radius: 50%;
  background: transparent;
  font-size: 16px;
  color: var(--text-secondary);
  cursor: pointer;
}

.month-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  min-width: 100px;
  text-align: center;
}

.weekday-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  margin-bottom: 6px;
}

.weekday-label {
  text-align: center;
  font-size: 11px;
  color: var(--text-muted);
  padding: 4px 0;
}

.month-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}

.day-cell {
  aspect-ratio: 1;
  border-radius: 8px;
  border: 1px solid var(--border-soft);
  background: var(--card-bg);
  cursor: pointer;
  position: relative;
  transition: all 0.15s;
  overflow: hidden;
}

.day-cell.empty {
  background: transparent;
  border: none;
  cursor: default;
}

.day-cell:not(.empty):active {
  transform: scale(0.92);
}

.day-cell.today {
  border-color: var(--primary-color);
  box-shadow: 0 0 0 2px var(--primary-bg);
}

/* 普通模式 */
.normal-mode {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  color: var(--text-primary);
}

.day-num {
  font-size: 13px;
  color: var(--text-primary);
  font-variant-numeric: tabular-nums;
}

.day-mark {
  font-size: 8px;
  color: var(--primary-color);
  line-height: 1;
  margin-top: 2px;
}

/* 时间模式 */
.time-mode {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: rgba(122, 148, 118, 0.15);
  border-radius: 8px;
}

.day-minutes {
  font-size: 9px;
  color: var(--primary-dark);
  font-weight: 600;
  margin-top: 2px;
}

/* 封面图模式 */
.cover-mode {
  width: 100%;
  height: 100%;
  position: relative;
  background: var(--bg-warm);
  border-radius: 8px;
  overflow: hidden;
}

.day-cover {
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.85;
}

.day-num-on-cover {
  position: absolute;
  top: 2px;
  left: 4px;
  font-size: 11px;
  font-weight: 700;
  color: white;
  text-shadow: 0 1px 2px rgba(0,0,0,0.7);
}

.day-minutes-on-cover {
  position: absolute;
  bottom: 2px;
  right: 4px;
  font-size: 9px;
  font-weight: 600;
  color: white;
  background: rgba(122, 148, 118, 0.8);
  padding: 1px 4px;
  border-radius: 4px;
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.stat-card {
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  padding: 12px;
  text-align: center;
}

.stat-value {
  font-size: 22px;
  font-weight: 700;
  color: var(--primary-dark);
}

.stat-unit {
  font-size: 11px;
  font-weight: 400;
  color: var(--text-muted);
  margin-left: 2px;
}

.stat-label {
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 2px;
}

/* 当日详情 */
.day-section {
  margin-bottom: 16px;
}

.day-section:last-child {
  margin-bottom: 0;
}

.day-section-title {
  font-size: 13px;
  font-weight: 500;
  color: var(--primary-dark);
  margin-bottom: 8px;
}

.day-thought, .day-session {
  padding: 8px 10px;
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  margin-bottom: 6px;
  border-left: 3px solid var(--accent-yellow);
}

.day-session {
  border-left-color: var(--primary-light);
}

.day-thought-time, .day-session-time {
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.day-thought-book {
  font-size: 11px;
  color: var(--accent-blue);
  margin-bottom: 4px;
}

.day-thought-content, .day-session-content {
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.6;
}
</style>
