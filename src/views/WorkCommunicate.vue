<template>
  <div class="comm-page">
    <div class="sub-header">
      <router-link to="/work" class="back-btn">←</router-link>
      <span class="sub-title">💬 家校沟通</span>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">用心的沟通，是教育的桥梁。</div>
    </div>

    <!-- 新增沟通 -->
    <div class="card">
      <div class="card-title">📝 记录沟通</div>
      <div class="form-row">
        <input v-model="form.student_name" class="input" placeholder="学生姓名" />
        <input v-model="form.parent_name" class="input" placeholder="家长姓名" />
      </div>
      <div class="form-row">
        <select v-model="form.method" class="select">
          <option value="微信">微信</option>
          <option value="电话">电话</option>
          <option value="面谈">面谈</option>
          <option value="家访">家访</option>
        </select>
        <input type="date" v-model="form.date" class="input" style="flex:1;" />
      </div>
      <input v-model="form.topic" class="input" placeholder="沟通主题" style="margin-bottom:8px;" />
      <textarea v-model="form.summary" class="textarea" placeholder="沟通内容摘要..." rows="3" style="margin-bottom:8px;"></textarea>
      <textarea v-model="form.follow_up" class="textarea" placeholder="后续跟进事项..." rows="2" style="margin-bottom:8px;"></textarea>
      <button class="btn btn-primary btn-block" @click="saveComm" :disabled="!form.student_name">保存</button>
    </div>

    <!-- 历史沟通 -->
    <div class="card" v-if="comms.length > 0">
      <div class="card-title">📞 沟通记录</div>
      <div v-for="c in comms" :key="c.id" class="comm-item">
        <div class="comm-header">
          <span class="comm-name">{{ c.student_name }}</span>
          <span class="comm-tag">{{ c.method }}</span>
          <span class="comm-date">{{ c.date }}</span>
          <button class="btn-icon-small danger" @click="deleteComm(c)">✕</button>
        </div>
        <div v-if="c.parent_name" class="comm-parent">家长：{{ c.parent_name }}</div>
        <div v-if="c.topic" class="comm-topic">主题：{{ c.topic }}</div>
        <div v-if="c.summary" class="comm-section">
          <div class="section-label">📋 沟通内容</div>
          <div class="section-content">{{ c.summary }}</div>
        </div>
        <div v-if="c.follow_up" class="comm-section">
          <div class="section-label">➡️ 跟进事项</div>
          <div class="section-content">{{ c.follow_up }}</div>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <div class="icon">💬</div>
      <div class="text">还没有沟通记录</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const comms = ref([])
const form = ref({
  student_name: '',
  parent_name: '',
  method: '微信',
  date: new Date().toISOString().split('T')[0],
  topic: '',
  summary: '',
  follow_up: '',
})

async function loadComms() {
  try {
    const { data } = await supabase
      .from(TABLES.WORK_COMMUNICATIONS)
      .select('*')
      .order('date', { ascending: false })
    comms.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveComm() {
  if (!form.value.student_name) return
  try {
    const { data } = await supabase.from(TABLES.WORK_COMMUNICATIONS).insert(form.value).select()
    if (data) {
      comms.value.unshift(data[0])
      form.value = {
        student_name: '', parent_name: '', method: '微信',
        date: new Date().toISOString().split('T')[0], topic: '', summary: '', follow_up: '',
      }
    }
  } catch (e) { console.error('保存失败', e) }
}

async function deleteComm(c) {
  if (!confirm('确定删除？')) return
  try {
    await supabase.from(TABLES.WORK_COMMUNICATIONS).delete().eq('id', c.id)
    comms.value = comms.value.filter(x => x.id !== c.id)
  } catch (e) { console.error(e) }
}

onMounted(loadComms)
</script>

<style scoped>
.form-row {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.comm-item {
  padding: 14px 0;
  border-bottom: 1px solid var(--border-soft);
}

.comm-item:last-child {
  border-bottom: none;
}

.comm-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.comm-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.comm-tag {
  padding: 2px 8px;
  background: var(--primary-bg);
  color: var(--primary-dark);
  border-radius: 10px;
  font-size: 11px;
}

.comm-date {
  font-size: 12px;
  color: var(--text-muted);
  margin-left: auto;
}

.comm-parent {
  font-size: 12px;
  color: var(--text-secondary);
  margin-bottom: 4px;
}

.comm-topic {
  font-size: 13px;
  color: var(--text-primary);
  font-weight: 500;
  margin-bottom: 8px;
}

.comm-section {
  margin-bottom: 8px;
}

.comm-section:last-child {
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

.btn-icon-small {
  width: 26px;
  height: 26px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-icon-small.danger {
  color: var(--danger-color);
}
</style>
