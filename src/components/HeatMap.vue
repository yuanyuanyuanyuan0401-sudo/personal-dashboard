<template>
  <div class="monthly-heatmap">
    <!-- 顶栏：月份切换 -->
    <div class="month-header">
      <button class="month-nav-btn" @click="changeMonth(-1)">‹</button>
      <span class="month-title">{{ year }}年{{ month }}月</span>
      <button class="month-nav-btn" @click="changeMonth(1)">›</button>
    </div>

    <!-- 星期表头 -->
    <div class="weekday-row">
      <span v-for="d in ['一','二','三','四','五','六','日']" :key="d" class="weekday-cell">{{ d }}</span>
    </div>

    <!-- 月历热力图 -->
    <div class="month-grid">
      <div
        v-for="(day, idx) in calendarDays"
        :key="idx"
        :class="['day-cell', {
          empty: !day,
          today: day && isToday(day),
          future: day && isFuture(day),
        }]"
        :style="day ? getCellStyle(day) : {}"
        @click="day && handleClick(day)"
      >
        <span v-if="day" class="day-num">{{ day.date.getDate() }}</span>
        <span v-if="day && dataForDate(day)" class="day-mark" :style="{ background: getMarkColor(day) }"></span>
      </div>
    </div>

    <!-- 图例 -->
    <div class="legend-row">
      <span class="legend-text">少</span>
      <div class="legend-cells">
        <div class="legend-cell lv0"></div>
        <div class="legend-cell lv1"></div>
        <div class="legend-cell lv2"></div>
        <div class="legend-cell lv3"></div>
        <div class="legend-cell lv4"></div>
      </div>
      <span class="legend-text">多</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  data: { type: Object, default: () => ({}) },  // { '2026-07-27': 3, ... }
  initialYear: { type: Number, default: null },
  initialMonth: { type: Number, default: null },
})

const emit = defineEmits(['dayClick'])

const today = new Date()
const year = ref(props.initialYear || today.getFullYear())
const month = ref(props.initialMonth || (today.getMonth() + 1))

const calendarDays = computed(() => {
  const firstDay = new Date(year.value, month.value - 1, 1)
  const lastDay = new Date(year.value, month.value, 0)
  const startWeekday = firstDay.getDay() || 7  // 周一开始 = 1
  const days = []

  // 前面留空
  for (let i = 1; i < startWeekday; i++) days.push(null)

  // 当月日期
  for (let i = 1; i <= lastDay.getDate(); i++) {
    days.push({ date: new Date(year.value, month.value - 1, i) })
  }

  // 补齐到 6 行（42 格）以填充
  while (days.length < 42) days.push(null)

  return days
})

function dateStr(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function isToday(day) {
  return dateStr(day.date) === dateStr(today)
}

function isFuture(day) {
  return day.date > today
}

function dataForDate(day) {
  return props.data[dateStr(day.date)] || 0
}

function getLevel(value) {
  if (value === 0) return 0
  if (value <= 1) return 1
  if (value <= 3) return 2
  if (value <= 5) return 3
  return 4
}

function getCellStyle(day) {
  const value = dataForDate(day)
  const level = getLevel(value)
  if (level === 0 || isFuture(day)) return {}
  // 根据数量设置绿色强度
  return {
    background: `rgba(122, 148, 118, ${0.15 + level * 0.2})`,
    borderColor: level >= 3 ? 'var(--primary-color)' : 'rgba(122, 148, 118, 0.3)',
  }
}

function getMarkColor(day) {
  const value = dataForDate(day)
  return value > 0 ? 'var(--primary-color)' : 'transparent'
}

function handleClick(day) {
  emit('dayClick', { date: dateStr(day.date), dateObj: day.date })
}

function changeMonth(delta) {
  let m = month.value + delta
  let y = year.value
  if (m > 12) { m = 1; y++ }
  if (m < 1) { m = 12; y-- }
  month.value = m
  year.value = y
}
</script>

<style scoped>
.monthly-heatmap {
  width: 100%;
  padding: 4px 0;
}

.month-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-bottom: 12px;
}

.month-nav-btn {
  width: 32px;
  height: 32px;
  border: 1px solid var(--border-color);
  border-radius: 50%;
  background: transparent;
  font-size: 18px;
  color: var(--text-secondary);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.month-nav-btn:active {
  background: var(--bg-warm);
}

.month-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  min-width: 100px;
  text-align: center;
}

.weekday-row {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  margin-bottom: 6px;
}

.weekday-cell {
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
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  cursor: pointer;
  position: relative;
  transition: transform 0.15s;
}

.day-cell.empty {
  background: transparent;
  border: none;
  cursor: default;
}

.day-cell:not(.empty):active {
  transform: scale(0.92);
}

.day-cell.future {
  opacity: 0.4;
}

.day-cell.today {
  background: var(--primary-color) !important;
  color: white;
  border-color: var(--primary-dark);
  font-weight: 700;
  box-shadow: 0 0 0 2px var(--primary-bg);
}

.day-cell.today .day-num {
  color: white;
}

.day-num {
  color: var(--text-primary);
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.day-mark {
  position: absolute;
  bottom: 4px;
  width: 4px;
  height: 4px;
  border-radius: 50%;
}

.day-cell.today .day-mark {
  background: white !important;
}

.legend-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-top: 10px;
  font-size: 11px;
  color: var(--text-muted);
}

.legend-cells {
  display: flex;
  gap: 3px;
}

.legend-cell {
  width: 14px;
  height: 14px;
  border-radius: 3px;
  border: 1px solid var(--border-soft);
}

.legend-cell.lv0 { background: var(--card-bg); }
.legend-cell.lv1 { background: rgba(122, 148, 118, 0.35); }
.legend-cell.lv2 { background: rgba(122, 148, 118, 0.55); }
.legend-cell.lv3 { background: rgba(122, 148, 118, 0.75); }
.legend-cell.lv4 { background: var(--primary-color); }
</style>
