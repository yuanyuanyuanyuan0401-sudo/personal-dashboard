<template>
  <div class="work-page">
    <div class="page-header">
      <h1 class="page-title">工作</h1>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 三个子模块入口 -->
    <div class="work-grid">
      <router-link to="/work/files" class="work-card">
        <div class="work-icon">📚</div>
        <div class="work-title">资料汇总</div>
        <div class="work-desc">上传工作资料<br/>随时查阅</div>
      </router-link>
      <router-link to="/work/reflect" class="work-card">
        <div class="work-icon">📝</div>
        <div class="work-title">教育反思</div>
        <div class="work-desc">记录事件与思考<br/>每日精进</div>
      </router-link>
      <router-link to="/work/communicate" class="work-card">
        <div class="work-icon">💬</div>
        <div class="work-title">家校沟通</div>
        <div class="work-desc">记录沟通内容<br/>跟进后续</div>
      </router-link>
    </div>

    <!-- 工作统计 -->
    <div class="card">
      <div class="card-title">📊 工作概览</div>
      <div class="stat-grid">
        <div class="stat-card">
          <div class="stat-value">{{ filesCount }}</div>
          <div class="stat-label">资料文件</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ reflectionsCount }}</div>
          <div class="stat-label">反思记录</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ commCount }}</div>
          <div class="stat-label">沟通记录</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ monthReflections }}</div>
          <div class="stat-label">本月反思</div>
        </div>
      </div>
    </div>

    <!-- 最近反思 -->
    <div class="card" v-if="recentReflections.length > 0">
      <div class="card-title">📝 最近反思</div>
      <div v-for="r in recentReflections" :key="r.id" class="recent-item">
        <div class="recent-meta">{{ r.date }} · {{ r.category }}</div>
        <div class="recent-title">{{ r.title || '反思' }}</div>
        <div class="recent-content">{{ r.reflection }}</div>
      </div>
    </div>

    <!-- 最近沟通 -->
    <div class="card" v-if="recentComm.length > 0">
      <div class="card-title">💬 最近沟通</div>
      <div v-for="c in recentComm" :key="c.id" class="recent-item">
        <div class="recent-meta">{{ c.date }} · {{ c.method }}</div>
        <div class="recent-title">{{ c.student_name || '沟通记录' }}</div>
        <div class="recent-content">{{ c.topic }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const filesCount = ref(0)
const reflectionsCount = ref(0)
const commCount = ref(0)
const monthReflections = ref(0)
const recentReflections = ref([])
const recentComm = ref([])

const touchMoments = [
  '教育的本质，是一棵树摇动另一棵树。',
  '每一天的反思，都是明天的阶梯。',
  '用心记录，让成长看得见。',
  '实践出真知，反思出智慧。',
  '教学相长，与学生共同进步。',
  '把每一件小事，都当作重要的事。',
]
const touchMomentText = ref(touchMoments[0])

async function loadData() {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]

  try {
    const { count: f } = await supabase.from(TABLES.WORK_FILES).select('*', { count: 'exact', head: true })
    filesCount.value = f || 0

    const { count: r } = await supabase.from(TABLES.WORK_REFLECTIONS).select('*', { count: 'exact', head: true })
    reflectionsCount.value = r || 0

    const { count: c } = await supabase.from(TABLES.WORK_COMMUNICATIONS).select('*', { count: 'exact', head: true })
    commCount.value = c || 0

    const monthStart = new Date()
    monthStart.setDate(1)
    monthStart.setHours(0, 0, 0, 0)
    const { count: mr } = await supabase
      .from(TABLES.WORK_REFLECTIONS)
      .select('*', { count: 'exact', head: true })
      .gte('date', monthStart.toISOString().split('T')[0])
    monthReflections.value = mr || 0

    const { data: refData } = await supabase
      .from(TABLES.WORK_REFLECTIONS)
      .select('*')
      .order('date', { ascending: false })
      .limit(3)
    recentReflections.value = refData || []

    const { data: commData } = await supabase
      .from(TABLES.WORK_COMMUNICATIONS)
      .select('*')
      .order('date', { ascending: false })
      .limit(3)
    recentComm.value = commData || []
  } catch (e) { console.warn(e) }
}

onMounted(loadData)
</script>

<style scoped>
.work-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  padding: 0 16px 12px;
}

.work-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 18px 8px;
  background: var(--card-bg);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  text-decoration: none;
  transition: transform 0.2s;
}

.work-card:active {
  transform: scale(0.97);
}

.work-icon {
  font-size: 32px;
  margin-bottom: 4px;
}

.work-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.work-desc {
  font-size: 11px;
  color: var(--text-muted);
  text-align: center;
  line-height: 1.4;
}

.recent-item {
  padding: 12px 0;
  border-bottom: 1px solid var(--border-soft);
}

.recent-item:last-child {
  border-bottom: none;
}

.recent-meta {
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.recent-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.recent-content {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}
</style>
