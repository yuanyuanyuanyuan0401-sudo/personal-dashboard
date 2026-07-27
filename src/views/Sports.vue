<template>
  <div class="sports-page">
    <div class="page-header">
      <h1 class="page-title">运动</h1>
    </div>

    <!-- 添加记录 -->
    <div class="card">
      <div class="card-title">🏃 记录运动</div>
      <div class="sport-form">
        <div class="form-row">
          <select v-model="form.type" class="input">
            <option value="">选择类型</option>
            <option v-for="t in sportTypes" :key="t.value" :value="t.value">{{ t.label }}</option>
          </select>
          <input type="date" v-model="form.date" class="input" style="flex:1;" />
        </div>
        <div class="form-row">
          <div class="form-field">
            <label class="field-label">时长（分钟）</label>
            <input type="number" v-model.number="form.duration" class="input" min="0" placeholder="0" />
          </div>
          <div class="form-field">
            <label class="field-label">距离（公里）</label>
            <input type="number" v-model.number="form.distance" class="input" min="0" step="0.01" placeholder="0" />
          </div>
          <div class="form-field">
            <label class="field-label">卡路里</label>
            <input type="number" v-model.number="form.calories" class="input" min="0" placeholder="0" />
          </div>
        </div>
        <input v-model="form.note" class="input" placeholder="备注（可选）" />
        <button class="btn btn-primary btn-block" @click="saveSport" style="margin-top:10px;" :disabled="!form.type || !form.duration">
          保存记录
        </button>
      </div>
    </div>

    <!-- 本周统计 -->
    <div class="card" v-if="weeklyStats.length > 0">
      <div class="card-title">本周统计</div>
      <div class="stat-row">
        <div class="stat-item">
          <div class="stat-value">{{ weekTotalDuration }}<span class="stat-unit">分钟</span></div>
          <div class="stat-label">总时长</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ weekTotalCount }}</div>
          <div class="stat-label">运动次数</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">{{ weekTotalCalories }}</div>
          <div class="stat-label">消耗(千卡)</div>
        </div>
      </div>
    </div>

    <!-- 类型分布 -->
    <div class="card" v-if="typeStats.length > 0">
      <div class="card-title">运动类型分布</div>
      <div class="type-chart">
        <div v-for="item in typeStats" :key="item.type" class="type-bar-row">
          <span class="type-label">{{ getTypeLabel(item.type) }}</span>
          <div class="type-bar-bg">
            <div class="type-bar-fill" :style="{ width: item.percent + '%' }"></div>
          </div>
          <span class="type-value">{{ item.minutes }}分钟</span>
        </div>
      </div>
    </div>

    <!-- 历史记录 -->
    <div v-if="sports.length > 0">
      <div class="card-title" style="padding:0 16px 8px;">历史记录</div>
      <div v-for="sport in sports" :key="sport.id" class="card sport-item">
        <div class="sport-header">
          <span class="sport-type">{{ getTypeLabel(sport.type) }}</span>
          <span class="sport-date">{{ sport.date }}</span>
          <button class="btn-icon-small danger" @click="deleteSport(sport)">✕</button>
        </div>
        <div class="sport-details">
          <span>⏱ {{ sport.duration }}分钟</span>
          <span v-if="sport.distance">📏 {{ sport.distance }}km</span>
          <span v-if="sport.calories">🔥 {{ sport.calories }}千卡</span>
        </div>
        <div v-if="sport.note" class="sport-note">{{ sport.note }}</div>
      </div>
    </div>
    <div v-else class="empty-state">
      <div class="icon">🏃</div>
      <div class="text">还没有运动记录，开始记录吧</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const sportTypes = [
  { value: 'running', label: '跑步' },
  { value: 'walking', label: '步行' },
  { value: 'cycling', label: '骑行' },
  { value: 'swimming', label: '游泳' },
  { value: 'fitness', label: '力量训练' },
  { value: 'yoga', label: '瑜伽' },
  { value: 'hiking', label: '徒步' },
  { value: 'badminton', label: '羽毛球' },
  { value: 'basketball', label: '篮球' },
  { value: 'football', label: '足球' },
  { value: 'table_tennis', label: '乒乓球' },
  { value: 'jump_rope', label: '跳绳' },
  { value: 'other', label: '其他' },
]

const form = ref({
  type: '',
  date: new Date().toISOString().split('T')[0],
  duration: null,
  distance: null,
  calories: null,
  note: '',
})

const sports = ref([])
const weeklyStats = ref([])

const weekTotalDuration = computed(() => weeklyStats.value.reduce((s, r) => s + (r.duration || 0), 0))
const weekTotalCount = computed(() => weeklyStats.value.length)
const weekTotalCalories = computed(() => weeklyStats.value.reduce((s, r) => s + (r.calories || 0), 0))

const typeStats = computed(() => {
  if (weeklyStats.value.length === 0) return []
  const map = {}
  weeklyStats.value.forEach(s => {
    if (!map[s.type]) map[s.type] = 0
    map[s.type] += s.duration || 0
  })
  const total = Object.values(map).reduce((a, b) => a + b, 0)
  return Object.entries(map)
    .map(([type, minutes]) => ({
      type,
      minutes,
      percent: Math.round((minutes / total) * 100),
    }))
    .sort((a, b) => b.minutes - a.minutes)
})

function getTypeLabel(type) {
  const found = sportTypes.find(t => t.value === type)
  return found ? found.label : type
}

function getWeekStart() {
  const now = new Date()
  const day = now.getDay()
  const diff = now.getDate() - day + (day === 0 ? -6 : 1)
  const monday = new Date(now.setDate(diff))
  monday.setHours(0, 0, 0, 0)
  return monday.toISOString().split('T')[0]
}

async function loadSports() {
  try {
    const { data } = await supabase
      .from(TABLES.SPORTS)
      .select('*')
      .order('date', { ascending: false })
      .limit(100)
    sports.value = data || []
  } catch (e) { console.warn('加载运动记录失败', e) }

  try {
    const weekStart = getWeekStart()
    const { data } = await supabase
      .from(TABLES.SPORTS)
      .select('*')
      .gte('date', weekStart)
      .order('date', { ascending: false })
    weeklyStats.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveSport() {
  if (!form.value.type || !form.value.duration) {
    alert('请选择运动类型并填写时长')
    return
  }
  try {
    const record = {
      type: form.value.type,
      date: form.value.date,
      duration: form.value.duration,
      distance: form.value.distance || null,
      calories: form.value.calories || null,
      note: form.value.note || null,
    }
    const { data } = await supabase.from(TABLES.SPORTS).insert(record).select()
    if (data) {
      sports.value.unshift(data[0])
      loadSports()
    }
    form.value = {
      type: '',
      date: new Date().toISOString().split('T')[0],
      duration: null,
      distance: null,
      calories: null,
      note: '',
    }
  } catch (e) {
    console.error('保存失败', e)
    alert('保存失败，请重试')
  }
}

async function deleteSport(sport) {
  if (!confirm('确定删除这条记录？')) return
  try {
    await supabase.from(TABLES.SPORTS).delete().eq('id', sport.id)
    sports.value = sports.value.filter(s => s.id !== sport.id)
    loadSports()
  } catch (e) { console.error('删除失败', e) }
}

onMounted(loadSports)
</script>

<style scoped>
.sport-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.form-row {
  display: flex;
  gap: 8px;
}
.form-field {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.field-label {
  font-size: 12px;
  color: var(--text-secondary);
}

.stat-row {
  display: flex;
  justify-content: space-around;
  text-align: center;
}
.stat-item { flex: 1; }
.stat-value {
  font-size: 22px;
  font-weight: 700;
  color: var(--primary-color);
}
.stat-unit {
  font-size: 11px;
  font-weight: 400;
  color: var(--text-muted);
}
.stat-label {
  font-size: 12px;
  color: var(--text-secondary);
  margin-top: 2px;
}

.type-chart {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.type-bar-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.type-label {
  width: 56px;
  font-size: 13px;
  color: var(--text-secondary);
  text-align: right;
}
.type-bar-bg {
  flex: 1;
  height: 14px;
  background: var(--bg-color);
  border-radius: 7px;
  overflow: hidden;
}
.type-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary-color), var(--primary-light));
  border-radius: 7px;
  transition: width 0.5s ease;
}
.type-value {
  width: 60px;
  font-size: 12px;
  color: var(--text-muted);
  text-align: right;
}

.sport-item {
  padding: 12px;
}
.sport-header {
  display: flex;
  align-items: center;
  gap: 8px;
}
.sport-type {
  font-size: 14px;
  font-weight: 600;
  color: var(--primary-color);
}
.sport-date {
  font-size: 12px;
  color: var(--text-muted);
  flex: 1;
}
.sport-details {
  display: flex;
  gap: 12px;
  margin-top: 6px;
  font-size: 13px;
  color: var(--text-secondary);
}
.sport-note {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 6px;
  padding-top: 6px;
  border-top: 1px solid var(--border-color);
}
</style>
