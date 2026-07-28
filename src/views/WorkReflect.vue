<template>
  <div class="reflect-page">
    <div class="sub-header">
      <router-link to="/work" class="back-btn">←</router-link>
      <span class="sub-title">📝 教育反思</span>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">每一天的反思，都是明天的阶梯。</div>
    </div>

    <!-- 新增反思 -->
    <div class="card">
      <div class="card-title">✍️ 记录反思</div>
      <input v-model="form.title" class="input" placeholder="标题（可选）" style="margin-bottom:8px;" />
      <div class="form-row">
        <select v-model="form.category" class="select">
          <option value="教学反思">教学反思</option>
          <option value="班级反思">班级反思</option>
          <option value="个人反思">个人反思</option>
        </select>
        <input type="date" v-model="form.date" class="input" style="flex:1;" />
      </div>
      <textarea v-model="form.event" class="textarea" placeholder="事件：发生了什么？" rows="2" style="margin-bottom:8px;"></textarea>
      <textarea v-model="form.reflection" class="textarea" placeholder="反思：你的思考、感受、改进方向..." rows="4" style="margin-bottom:8px;"></textarea>
      <div class="mood-row">
        <span class="mood-label">心情：</span>
        <button v-for="m in [1, 2, 3, 4, 5]" :key="m" :class="['mood-btn', { active: form.mood === m }]" @click="form.mood = m">{{ moodEmoji(m) }}</button>
      </div>
      <button class="btn btn-primary btn-block" @click="saveReflect" :disabled="!form.event">保存反思</button>
    </div>

    <!-- 历史反思 -->
    <div class="card" v-if="reflections.length > 0">
      <div class="card-title">📚 我的反思</div>

      <div class="filter-row">
        <button :class="['filter-btn', { active: filterCat === 'all' }]" @click="filterCat = 'all'">全部</button>
        <button v-for="c in ['教学反思', '班级反思', '个人反思']" :key="c" :class="['filter-btn', { active: filterCat === c }]" @click="filterCat = c">{{ c }}</button>
      </div>

      <div v-for="r in filteredReflections" :key="r.id" class="reflect-item">
        <div class="reflect-header">
          <span class="reflect-date">{{ r.date }}</span>
          <span class="tag tag-yellow">{{ r.category }}</span>
          <span class="mood-icon">{{ moodEmoji(r.mood) }}</span>
          <button class="btn-icon-small danger" @click="deleteReflect(r)">✕</button>
        </div>
        <div class="reflect-title">{{ r.title || '无标题' }}</div>
        <div class="reflect-section">
          <div class="section-label">📌 事件</div>
          <div class="section-content">{{ r.event }}</div>
        </div>
        <div class="reflect-section">
          <div class="section-label">💡 反思</div>
          <div class="section-content">{{ r.reflection }}</div>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <div class="icon">📝</div>
      <div class="text">开始记录你的第一篇反思</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const reflections = ref([])
const filterCat = ref('all')

const form = ref({
  title: '',
  category: '教学反思',
  date: new Date().toISOString().split('T')[0],
  event: '',
  reflection: '',
  mood: 3,
})

const filteredReflections = computed(() => {
  if (filterCat.value === 'all') return reflections.value
  return reflections.value.filter(r => r.category === filterCat.value)
})

function moodEmoji(m) {
  return ['', '😢', '😟', '😐', '😊', '🤩'][m] || '😐'
}

async function loadReflections() {
  try {
    const { data } = await supabase
      .from(TABLES.WORK_REFLECTIONS)
      .select('*')
      .order('date', { ascending: false })
    reflections.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveReflect() {
  if (!form.value.event) return
  try {
    const { data } = await supabase.from(TABLES.WORK_REFLECTIONS).insert({
      title: form.value.title,
      category: form.value.category,
      date: form.value.date,
      event: form.value.event,
      reflection: form.value.reflection,
      mood: form.value.mood,
    }).select()
    if (data) {
      reflections.value.unshift(data[0])
      form.value = { title: '', category: '教学反思', date: new Date().toISOString().split('T')[0], event: '', reflection: '', mood: 3 }
    }
  } catch (e) { console.error('保存失败', e) }
}

async function deleteReflect(r) {
  if (!confirm('确定删除这篇反思？')) return
  try {
    await supabase.from(TABLES.WORK_REFLECTIONS).delete().eq('id', r.id)
    reflections.value = reflections.value.filter(x => x.id !== r.id)
  } catch (e) { console.error(e) }
}

onMounted(loadReflections)
</script>

<style scoped>
.form-row {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.mood-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 10px;
}

.mood-label {
  font-size: 13px;
  color: var(--text-secondary);
}

.mood-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 18px;
  cursor: pointer;
  transition: all 0.2s;
}

.mood-btn.active {
  background: var(--primary-bg);
  border-color: var(--primary-light);
  transform: scale(1.1);
}

.filter-row {
  display: flex;
  gap: 6px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 4px 12px;
  border-radius: 14px;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 12px;
  color: var(--text-secondary);
  cursor: pointer;
}

.filter-btn.active {
  background: var(--primary-bg);
  border-color: var(--primary-light);
  color: var(--primary-dark);
}

.reflect-item {
  padding: 14px 0;
  border-bottom: 1px solid var(--border-soft);
}

.reflect-item:last-child {
  border-bottom: none;
}

.reflect-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.reflect-date {
  font-size: 12px;
  color: var(--text-muted);
}

.mood-icon {
  font-size: 16px;
  margin-left: auto;
}

.reflect-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.reflect-section {
  margin-bottom: 8px;
}

.reflect-section:last-child {
  margin-bottom: 0;
}

.section-label {
  font-size: 12px;
  color: var(--primary-dark);
  margin-bottom: 4px;
  font-weight: 500;
}

.section-content {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
  text-indent: 2em;
  white-space: pre-wrap;
}
</style>
