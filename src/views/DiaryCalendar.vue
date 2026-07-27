<template>
  <div class="calendar-page">
    <div class="sub-header">
      <router-link to="/diary" class="back-btn">← 返回日记</router-link>
      <span class="sub-title">日历</span>
    </div>

    <!-- 月份切换 -->
    <div class="card">
      <div class="month-nav">
        <button class="btn-icon-small" @click="prevMonth">‹</button>
        <span class="month-label">{{ year }} 年 {{ month + 1 }} 月</span>
        <button class="btn-icon-small" @click="nextMonth">›</button>
      </div>

      <!-- 星期头 -->
      <div class="weekday-header">
        <span v-for="w in weekdays" :key="w">{{ w }}</span>
      </div>

      <!-- 日期网格 -->
      <div class="calendar-grid">
        <div v-for="day in days" :key="day.key" class="calendar-cell"
          :class="{
            'other-month': !day.isCurrentMonth,
            'today': day.isToday,
            'has-diary': day.hasDiary,
            'selected': selectedDate === day.dateStr,
          }"
          @click="selectDate(day)"
        >
          <span class="day-num">{{ day.day }}</span>
        </div>
      </div>
    </div>

    <!-- 选中日期的日记 -->
    <div v-if="selectedDate && selectedDiaries.length > 0">
      <div class="card-title" style="padding:0 16px 8px;font-size:15px;">
        {{ formatSelectedDate }} 的日记
      </div>
      <div v-for="entry in selectedDiaries" :key="entry.id" class="card diary-entry-card">
        <div class="diary-entry-content">{{ entry.content }}</div>
        <div v-if="entry.images && entry.images.length > 0" class="diary-entry-images">
          <img v-for="(img, idx) in entry.images" :key="idx" :src="img" class="diary-thumb" @click="previewImage = img" />
        </div>
      </div>
    </div>
    <div v-else-if="selectedDate" class="empty-state">
      <div class="icon">📭</div>
      <div class="text">{{ formatSelectedDate }} 没有日记</div>
    </div>

    <!-- 图片预览 -->
    <div v-if="previewImage" class="image-overlay" @click="previewImage = null">
      <img :src="previewImage" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const weekdays = ['日', '一', '二', '三', '四', '五', '六']

const today = new Date()
const year = ref(today.getFullYear())
const month = ref(today.getMonth())
const selectedDate = ref(today.toISOString().split('T')[0])

const diaryDates = ref(new Set())
const diaryMap = ref({})
const previewImage = ref(null)

const days = computed(() => {
  const firstDay = new Date(year.value, month.value, 1)
  const lastDay = new Date(year.value, month.value + 1, 0)
  const startDayOfWeek = firstDay.getDay()

  const result = []
  // 上个月填充
  const prevMonthLastDay = new Date(year.value, month.value, 0).getDate()
  for (let i = startDayOfWeek - 1; i >= 0; i--) {
    const d = prevMonthLastDay - i
    const date = new Date(year.value, month.value - 1, d)
    result.push({
      key: `prev-${d}`,
      day: d,
      isCurrentMonth: false,
      isToday: false,
      hasDiary: diaryDates.value.has(formatDateStr(date)),
      dateStr: formatDateStr(date),
    })
  }

  // 本月
  for (let d = 1; d <= lastDay.getDate(); d++) {
    const date = new Date(year.value, month.value, d)
    result.push({
      key: `curr-${d}`,
      day: d,
      isCurrentMonth: true,
      isToday: isSameDay(date, today),
      hasDiary: diaryDates.value.has(formatDateStr(date)),
      dateStr: formatDateStr(date),
    })
  }

  // 下个月填充（保持6行）
  const remaining = 42 - result.length
  for (let d = 1; d <= remaining; d++) {
    const date = new Date(year.value, month.value + 1, d)
    result.push({
      key: `next-${d}`,
      day: d,
      isCurrentMonth: false,
      isToday: false,
      hasDiary: diaryDates.value.has(formatDateStr(date)),
      dateStr: formatDateStr(date),
    })
  }

  return result
})

const formatSelectedDate = computed(() => {
  if (!selectedDate.value) return ''
  const d = new Date(selectedDate.value)
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
})

const selectedDiaries = computed(() => {
  return diaryMap.value[selectedDate.value] || []
})

function formatDateStr(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function isSameDay(d1, d2) {
  return d1.getFullYear() === d2.getFullYear()
    && d1.getMonth() === d2.getMonth()
    && d1.getDate() === d2.getDate()
}

function prevMonth() {
  if (month.value === 0) {
    month.value = 11
    year.value--
  } else {
    month.value--
  }
}

function nextMonth() {
  if (month.value === 11) {
    month.value = 0
    year.value++
  } else {
    month.value++
  }
}

function selectDate(day) {
  selectedDate.value = day.dateStr
}

async function loadDiaries() {
  try {
    const startDate = new Date(year.value, month.value - 1, 1)
    const endDate = new Date(year.value, month.value + 1, 0)
    const { data } = await supabase
      .from(TABLES.DIARY)
      .select('*')
      .gte('date', formatDateStr(startDate))
      .lte('date', formatDateStr(endDate))
      .order('created_at', { ascending: false })

    if (data) {
      diaryDates.value = new Set(data.map(d => d.date))
      diaryMap.value = {}
      data.forEach(d => {
        if (!diaryMap.value[d.date]) diaryMap.value[d.date] = []
        diaryMap.value[d.date].push({ ...d, images: d.images || [] })
      })
    }
  } catch (e) {
    console.warn('加载日记失败', e)
  }
}

onMounted(loadDiaries)
</script>

<style scoped>
.month-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-bottom: 12px;
}
.month-label {
  font-size: 16px;
  font-weight: 600;
  min-width: 120px;
  text-align: center;
}

.weekday-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  text-align: center;
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
}
.calendar-cell {
  aspect-ratio: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  position: relative;
  transition: background 0.15s;
}
.calendar-cell:active {
  background: var(--primary-bg);
}

.other-month {
  color: var(--text-muted);
}
.today {
  background: var(--primary-color);
  color: white;
  font-weight: 600;
}
.has-diary::after {
  content: '';
  position: absolute;
  bottom: 4px;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--primary-color);
}
.today.has-diary::after {
  background: white;
}
.selected {
  outline: 2px solid var(--primary-color);
  outline-offset: -2px;
}

.diary-entry-card {
  margin: 0 16px 12px;
  padding: 14px;
}
.diary-entry-content {
  font-size: 14px;
  line-height: 1.7;
  white-space: pre-wrap;
  word-break: break-word;
}
.diary-entry-images {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 8px;
}
.diary-thumb {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: var(--radius-sm);
  cursor: pointer;
}
</style>
