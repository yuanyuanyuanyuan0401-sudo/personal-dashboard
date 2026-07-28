<template>
  <div class="heatmap-container">
    <div class="heatmap-row">
      <span class="month-label">最近 12 周</span>
    </div>
    <div class="heatmap-grid">
      <div v-for="(week, wi) in weeks" :key="wi" class="heatmap-week">
        <div
          v-for="(day, di) in week"
          :key="di"
          :class="['heat-cell', day ? levelClass(day.level) : '']"
          :title="day ? `${day.date}: ${day.value} 次完成` : ''"
        >
          <span v-if="day && day.isToday" class="today-dot"></span>
        </div>
      </div>
    </div>
    <div class="heatmap-legend">
      <span>少</span>
      <div class="legend-cell lv1"></div>
      <div class="legend-cell lv2"></div>
      <div class="legend-cell lv3"></div>
      <div class="legend-cell lv4"></div>
      <span>多</span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  data: { type: Object, default: () => ({}) },  // { '2026-07-27': 3, ... }
  weeks: { type: Number, default: 12 },
})

const weeks = computed(() => {
  const today = new Date()
  const allDays = []
  const startDate = new Date(today)
  startDate.setDate(startDate.getDate() - (props.weeks * 7) + 1)

  // 调整到周一开始
  const day = startDate.getDay()
  const diff = (day === 0 ? -6 : 1) - day
  startDate.setDate(startDate.getDate() + diff)

  for (let i = 0; i < props.weeks * 7; i++) {
    const d = new Date(startDate)
    d.setDate(startDate.getDate() + i)
    if (d > today) {
      allDays.push(null)
    } else {
      const dateStr = d.toISOString().split('T')[0]
      const value = props.data[dateStr] || 0
      allDays.push({
        date: dateStr,
        value,
        level: getLevel(value),
        isToday: dateStr === today.toISOString().split('T')[0],
      })
    }
  }

  const result = []
  for (let i = 0; i < props.weeks; i++) {
    result.push(allDays.slice(i * 7, (i + 1) * 7))
  }
  return result
})

function getLevel(value) {
  if (value === 0) return 0
  if (value <= 2) return 1
  if (value <= 4) return 2
  if (value <= 6) return 3
  return 4
}

function levelClass(level) {
  return level > 0 ? `lv${level}` : ''
}
</script>

<style scoped>
.heatmap-container {
  padding: 4px 0;
}

.heatmap-row {
  margin-bottom: 6px;
}

.month-label {
  font-size: 11px;
  color: var(--text-muted);
}

.heatmap-grid {
  display: flex;
  gap: 4px;
  overflow-x: auto;
  padding: 4px 0;
}

.heatmap-week {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.heat-cell {
  width: 16px;
  height: 16px;
  border-radius: 3px;
  background: var(--card-alt);
  border: 1px solid var(--border-soft);
  position: relative;
  cursor: pointer;
  transition: transform 0.15s;
}

.heat-cell:active {
  transform: scale(1.15);
}

.heat-cell.lv1 { background: #D8E5D5; border-color: #C8D9C4; }
.heat-cell.lv2 { background: #B5C4A8; border-color: #A2B594; }
.heat-cell.lv3 { background: #8FA887; border-color: #7C9474; }
.heat-cell.lv4 { background: var(--primary-color); border-color: var(--primary-dark); }

.today-dot {
  position: absolute;
  inset: -2px;
  border-radius: 4px;
  border: 1.5px solid var(--accent-rose);
  pointer-events: none;
}

.heatmap-legend {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 8px;
  font-size: 11px;
  color: var(--text-muted);
}

.legend-cell {
  width: 12px;
  height: 12px;
  border-radius: 3px;
  background: var(--card-alt);
}

.legend-cell.lv1 { background: #D8E5D5; }
.legend-cell.lv2 { background: #B5C4A8; }
.legend-cell.lv3 { background: #8FA887; }
.legend-cell.lv4 { background: var(--primary-color); }
</style>
