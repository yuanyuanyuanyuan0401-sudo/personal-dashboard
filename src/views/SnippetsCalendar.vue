<template>
  <div class="snippets-calendar">
    <div class="sub-header">
      <router-link to="/snippets" class="back-btn">←</router-link>
      <span class="sub-title">📅 日历视图</span>
    </div>

    <div class="month-nav">
      <button class="month-btn" @click="changeMonth(-1)">‹</button>
      <span class="month-title">{{ year }}年{{ month }}月</span>
      <button class="month-btn" @click="changeMonth(1)">›</button>
    </div>

    <div class="calendar">
      <div class="weekday-header">
        <span v-for="d in ['一','二','三','四','五','六','日']" :key="d" class="weekday-label">{{ d }}</span>
      </div>
      <div class="day-grid">
        <div v-for="(day, i) in calendarDays" :key="i" :class="['day-cell', {
          empty: !day,
          today: day && isToday(day),
          hasData: day && hasData(day),
        }]" @click="day && showDay(day)">
          <span v-if="day" class="day-num">{{ day.date.getDate() }}</span>
          <div v-if="day && hasData(day)" class="dot-group">
            <span class="dot dot-snippet"></span>
            <span v-if="dayHasGratitude(day)" class="dot dot-gratitude"></span>
          </div>
        </div>
      </div>
    </div>

    <!-- 当日详情 -->
    <div v-if="selectedDay" class="card day-detail">
      <div class="card-title">📖 {{ selectedDay.dateStr }}</div>

      <div v-if="gratitudeForDay" class="day-section">
        <div class="day-section-title">💗 三件感恩小事</div>
        <div class="gratitude-list">
          <div v-if="gratitudeForDay.item1" class="gratitude-item">
            <span class="gratitude-num">1</span>
            <span class="gratitude-text">{{ gratitudeForDay.item1 }}</span>
          </div>
          <div v-if="gratitudeForDay.item2" class="gratitude-item">
            <span class="gratitude-num">2</span>
            <span class="gratitude-text">{{ gratitudeForDay.item2 }}</span>
          </div>
          <div v-if="gratitudeForDay.item3" class="gratitude-item">
            <span class="gratitude-num">3</span>
            <span class="gratitude-text">{{ gratitudeForDay.item3 }}</span>
          </div>
        </div>
      </div>

      <div v-if="snippetsForDay.length > 0" class="day-section">
        <div class="day-section-title">💭 碎碎念</div>
        <div v-for="s in snippetsForDay" :key="s.id" class="day-snippet">
          <div class="day-snippet-content">{{ s.content }}</div>
        </div>
      </div>

      <div v-if="!gratitudeForDay && snippetsForDay.length === 0" class="empty-state" style="padding:24px;">
        <div class="text">这天还没有记录</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const today = new Date()
const year = ref(today.getFullYear())
const month = ref(today.getMonth() + 1)
const allSnippets = ref([])
const allGratitudes = ref([])
const selectedDay = ref(null)

const calendarDays = computed(() => {
  const firstDay = new Date(year.value, month.value - 1, 1)
  const lastDay = new Date(year.value, month.value, 0)
  const startWeekday = firstDay.getDay() || 7  // 周一开始
  const days = []
  for (let i = 1; i < startWeekday; i++) days.push(null)
  for (let i = 1; i <= lastDay.getDate(); i++) {
    days.push({ date: new Date(year.value, month.value - 1, i) })
  }
  return days
})

function dateStr(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function isToday(day) {
  return dateStr(day.date) === dateStr(new Date())
}

function hasData(day) {
  const ds = dateStr(day.date)
  return allSnippets.value.some(s => s.created_at.startsWith(ds)) || allGratitudes.value.some(g => g.date === ds)
}

function dayHasGratitude(day) {
  const ds = dateStr(day.date)
  return allGratitudes.value.some(g => g.date === ds)
}

function showDay(day) {
  selectedDay.value = { date: day.date, dateStr: dateStr(day.date) }
}

const gratitudeForDay = computed(() => {
  if (!selectedDay.value) return null
  return allGratitudes.value.find(g => g.date === selectedDay.value.dateStr)
})

const snippetsForDay = computed(() => {
  if (!selectedDay.value) return []
  return allSnippets.value.filter(s => s.created_at.startsWith(selectedDay.value.dateStr))
})

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
    const start = `${year.value}-${String(month.value).padStart(2, '0')}-01`
    const endMonth = month.value === 12 ? 1 : month.value + 1
    const endYear = month.value === 12 ? year.value + 1 : year.value
    const end = `${endYear}-${String(endMonth).padStart(2, '0')}-01`

    const { data: snippets } = await supabase
      .from(TABLES.SNIPPETS)
      .select('*')
      .gte('created_at', start)
      .lt('created_at', end)
    allSnippets.value = snippets || []

    const { data: grats } = await supabase
      .from(TABLES.GRATITUDES)
      .select('*')
      .gte('date', start)
      .lt('date', end)
    allGratitudes.value = grats || []

    selectedDay.value = null
  } catch (e) { console.warn(e) }
}

// First load
loadData()
</script>

<style scoped>
.month-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 16px;
}

.month-btn {
  width: 36px;
  height: 36px;
  border: 1px solid var(--border-color);
  border-radius: 50%;
  background: transparent;
  font-size: 18px;
  color: var(--text-secondary);
  cursor: pointer;
}

.month-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
  min-width: 100px;
  text-align: center;
}

.calendar {
  padding: 0 16px;
}

.weekday-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  margin-bottom: 8px;
}

.weekday-label {
  text-align: center;
  font-size: 12px;
  color: var(--text-muted);
  padding: 4px 0;
}

.day-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}

.day-cell {
  aspect-ratio: 1;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  border: 1px solid var(--border-soft);
  background: var(--card-bg);
  cursor: pointer;
  transition: all 0.15s;
  position: relative;
}

.day-cell.empty {
  background: transparent;
  border: none;
  cursor: default;
}

.day-cell.today {
  background: var(--primary-bg);
  border-color: var(--primary-light);
}

.day-cell.hasData:not(.today) {
  background: var(--bg-warm);
}

.day-cell:not(.empty):active {
  transform: scale(0.95);
}

.day-num {
  font-size: 13px;
  color: var(--text-primary);
}

.day-cell.today .day-num {
  color: var(--primary-dark);
  font-weight: 600;
}

.dot-group {
  display: flex;
  gap: 2px;
}

.dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
}

.dot-snippet {
  background: var(--primary-color);
}

.dot-gratitude {
  background: var(--accent-rose);
}

.day-detail {
  padding: 18px;
}

.day-section {
  margin-bottom: 16px;
}

.day-section:last-child {
  margin-bottom: 0;
}

.day-section-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--primary-dark);
  margin-bottom: 8px;
}

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

.day-snippet {
  padding: 8px 0;
  border-bottom: 1px solid var(--border-soft);
}

.day-snippet:last-child {
  border-bottom: none;
}

.day-snippet-content {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
  text-indent: 2em;
}
</style>
