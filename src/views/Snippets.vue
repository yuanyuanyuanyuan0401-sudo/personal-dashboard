<template>
  <div class="snippets-page">
    <div class="page-header">
      <h1 class="page-title">碎碎念</h1>
      <router-link to="/snippets/calendar" class="btn btn-secondary btn-sm">📅</router-link>
      <router-link to="/snippets/gallery" class="btn btn-secondary btn-sm">🖼️</router-link>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 顶部 Tab -->
    <div class="tab-bar">
      <button :class="['tab-item', { active: activeTab === 'output' }]" @click="activeTab = 'output'">输出练习</button>
      <button :class="['tab-item', { active: activeTab === 'diary' }]" @click="activeTab = 'diary'">日记本</button>
      <button :class="['tab-item', { active: activeTab === 'inspiration' }]" @click="activeTab = 'inspiration'">灵感库</button>
      <button :class="['tab-item', { active: activeTab === 'report' }]" @click="activeTab = 'report'">成长报告</button>
    </div>

    <!-- 输出练习 -->
    <div v-if="activeTab === 'output'">
      <div class="card">
        <div class="card-title">✍️ 输出练习</div>
        <div class="card-subtitle">把学到的东西，讲出来写出来</div>
        <textarea v-model="outputContent" class="textarea" placeholder="今天练习输出了什么..." rows="5"></textarea>
        <input v-model="outputTags" class="input" placeholder="标签（逗号分隔）" style="margin-top:8px;" />
        <button class="btn btn-primary btn-block" @click="saveOutput" :disabled="!outputContent" style="margin-top:10px;">保存</button>
      </div>

      <div v-if="outputs.length > 0" class="card">
        <div class="card-title">📝 输出记录</div>
        <div v-for="o in outputs" :key="o.id" class="snippet-item">
          <div class="snippet-meta">
            <span class="snippet-date">{{ formatDate(o.created_at) }}</span>
            <button class="btn-icon-small danger" @click="deleteSnippet(o)">✕</button>
          </div>
          <div class="snippet-content">{{ o.content }}</div>
          <div v-if="o.tags && o.tags.length" class="snippet-tags">
            <span v-for="t in o.tags" :key="t" class="tag">#{{ t }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 日记本 -->
    <div v-if="activeTab === 'diary'">
      <div class="card">
        <div class="card-title">💗 每日三件感恩小事</div>
        <div class="card-subtitle">每晚9点引导，回顾今日的好事</div>
        <input type="date" v-model="gratitudeDate" class="input" style="margin-bottom:10px;" />
        <div class="gratitude-list">
          <div class="gratitude-item">
            <span class="gratitude-num">1</span>
            <input v-model="gratitude1" class="input" placeholder="第1件好事..." />
          </div>
          <div class="gratitude-item">
            <span class="gratitude-num">2</span>
            <input v-model="gratitude2" class="input" placeholder="第2件好事..." />
          </div>
          <div class="gratitude-item">
            <span class="gratitude-num">3</span>
            <input v-model="gratitude3" class="input" placeholder="第3件好事..." />
          </div>
        </div>
        <input v-model="emotions" class="input" placeholder="今日情绪关键词（逗号分隔，如：平静，充实，感恩）" style="margin-top:10px;" />
        <textarea v-model="gratitudeExtra" class="textarea" placeholder="想说的其他话（可选）" rows="3" style="margin-top:8px;"></textarea>
        <button class="btn btn-primary btn-block" @click="saveGratitude" :disabled="!gratitude1" style="margin-top:10px;">保存日记</button>
      </div>

      <div v-if="gratitudes.length > 0" class="card">
        <div class="card-title">📚 日记本</div>
        <div v-for="g in gratitudes" :key="g.date" class="diary-item">
          <div class="diary-header">
            <span class="diary-date">{{ g.date }}</span>
            <button class="btn-icon-small danger" @click="deleteGratitude(g)">✕</button>
          </div>
          <div class="gratitude-list">
            <div v-if="g.item1" class="gratitude-item">
              <span class="gratitude-num">1</span>
              <span class="gratitude-text">{{ g.item1 }}</span>
            </div>
            <div v-if="g.item2" class="gratitude-item">
              <span class="gratitude-num">2</span>
              <span class="gratitude-text">{{ g.item2 }}</span>
            </div>
            <div v-if="g.item3" class="gratitude-item">
              <span class="gratitude-num">3</span>
              <span class="gratitude-text">{{ g.item3 }}</span>
            </div>
          </div>
          <div v-if="g.emotions" class="emotions-row">
            <span class="er-label">情绪：</span>
            <span v-for="e in g.emotions.split(/[,，]/)" :key="e" class="tag tag-rose">{{ e.trim() }}</span>
          </div>
          <div v-if="g.extra" class="diary-extra">{{ g.extra }}</div>
        </div>
      </div>
    </div>

    <!-- 灵感库 -->
    <div v-if="activeTab === 'inspiration'">
      <div class="card">
        <div class="card-title">💡 灵感捕捉</div>
        <div class="card-subtitle">随时记录，3个延伸问题，按标签归档</div>
        <textarea v-model="inspirationContent" class="textarea" placeholder="突然冒出来的想法..." rows="4"></textarea>
        <input v-model="inspirationTags" class="input" placeholder="标签（逗号分隔，如：内容创作，自我提升）" style="margin-top:8px;" />
        <button class="btn btn-primary btn-block" @click="saveInspiration" :disabled="!inspirationContent" style="margin-top:10px;">记录并追问</button>
      </div>

      <div v-if="inspirations.length > 0" class="card">
        <div class="card-title">📌 灵感列表</div>
        <div v-for="i in inspirations" :key="i.id" class="inspiration-item">
          <div class="snippet-meta">
            <span class="snippet-date">{{ formatDate(i.created_at) }}</span>
            <button class="btn-icon-small danger" @click="deleteSnippet(i)">✕</button>
          </div>
          <div class="snippet-content">{{ i.content }}</div>
          <div v-if="i.tags && i.tags.length" class="snippet-tags">
            <span v-for="t in i.tags" :key="t" class="tag tag-yellow">#{{ t }}</span>
          </div>
          <!-- 3个延伸问题 -->
          <div class="follow-questions">
            <div class="fq-label">🔍 延伸思考</div>
            <div class="fq-item">① 为什么这个想法会冒出来？</div>
            <div class="fq-item">② 它和我过去的什么经历有关？</div>
            <div class="fq-item">③ 我可以怎么用它？</div>
          </div>
        </div>
      </div>
      <div v-else class="empty-state">
        <div class="icon">💡</div>
        <div class="text">还没有灵感，随时记录冒出来的想法</div>
      </div>
    </div>

    <!-- 成长报告 -->
    <div v-if="activeTab === 'report'">
      <div class="card">
        <div class="card-title">📈 成长报告</div>
        <div class="card-subtitle">查看你的成长轨迹</div>
        <div class="stat-grid">
          <div class="stat-card">
            <div class="stat-value">{{ totalOutputs }}</div>
            <div class="stat-label">输出次数</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ totalInspiration }}</div>
            <div class="stat-label">灵感记录</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ totalGratitudes }}</div>
            <div class="stat-label">感恩日记</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ streakDays }}</div>
            <div class="stat-label">连续天数</div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-title">🔥 碎碎念热力图</div>
        <HeatMap :data="snippetHeatData" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'
import HeatMap from '../components/HeatMap.vue'

const activeTab = ref('diary')

const touchMoments = [
  '记录，让时光有了形状。',
  '碎碎念，也是一种特别的珍藏。',
  '写下来的文字，会成为你最温柔的依靠。',
  '捕捉瞬间，让当下成为永恒。',
  '生活值得被记录。',
  '每一个小确幸，都值得纪念。',
]
const touchMomentText = ref(touchMoments[0])

// 输出练习
const outputContent = ref('')
const outputTags = ref('')
const outputs = ref([])

// 灵感库
const inspirationContent = ref('')
const inspirationTags = ref('')
const inspirations = ref([])

// 日记本
const gratitudeDate = ref(new Date().toISOString().split('T')[0])
const gratitude1 = ref('')
const gratitude2 = ref('')
const gratitude3 = ref('')
const emotions = ref('')
const gratitudeExtra = ref('')
const gratitudes = ref([])

const snippetHeatData = computed(() => {
  const map = {}
  outputs.value.forEach(o => {
    const date = o.created_at.split('T')[0]
    map[date] = (map[date] || 0) + 1
  })
  inspirations.value.forEach(i => {
    const date = i.created_at.split('T')[0]
    map[date] = (map[date] || 0) + 1
  })
  return map
})

const totalOutputs = computed(() => outputs.value.length)
const totalInspiration = computed(() => inspirations.value.length)
const totalGratitudes = computed(() => gratitudes.value.length)

const streakDays = computed(() => {
  const dates = new Set()
  outputs.value.forEach(o => dates.add(o.created_at.split('T')[0]))
  inspirations.value.forEach(i => dates.add(i.created_at.split('T')[0]))
  gratitudes.value.forEach(g => dates.add(g.date))
  const sorted = [...dates].sort().reverse()
  let streak = 0
  const today = new Date()
  for (let i = 0; i < sorted.length; i++) {
    const expected = new Date(today)
    expected.setDate(today.getDate() - i)
    if (sorted[i] === expected.toISOString().split('T')[0]) streak++
    else break
  }
  return streak
})

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getFullYear()}.${d.getMonth() + 1}.${d.getDate()}`
}

async function loadData() {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]
  try {
    const { data: allSnippets } = await supabase.from(TABLES.SNIPPETS).select('*').order('created_at', { ascending: false })
    const all = allSnippets || []
    outputs.value = all.filter(s => s.tags && s.tags.includes('output'))
    inspirations.value = all.filter(s => s.tags && s.tags.includes('inspiration'))

    const { data: grats } = await supabase.from(TABLES.GRATITUDES).select('*').order('date', { ascending: false })
    gratitudes.value = grats || []
  } catch (e) { console.warn(e) }
}

async function saveOutput() {
  if (!outputContent.value.trim()) return
  try {
    const tags = outputTags.value.split(/[,，]/).map(t => t.trim()).filter(Boolean)
    const { data } = await supabase.from(TABLES.SNIPPETS).insert({
      content: outputContent.value,
      type: 'snippet',
      tags: [...tags, 'output'],
      word_count: outputContent.value.length,
    }).select()
    if (data) {
      outputs.value.unshift(data[0])
      outputContent.value = ''
      outputTags.value = ''
    }
  } catch (e) { console.error(e) }
}

async function saveInspiration() {
  if (!inspirationContent.value.trim()) return
  try {
    const tags = inspirationTags.value.split(/[,，]/).map(t => t.trim()).filter(Boolean)
    const { data } = await supabase.from(TABLES.SNIPPETS).insert({
      content: inspirationContent.value,
      type: 'snippet',
      tags: [...tags, 'inspiration'],
      word_count: inspirationContent.value.length,
    }).select()
    if (data) {
      inspirations.value.unshift(data[0])
      inspirationContent.value = ''
      inspirationTags.value = ''
    }
  } catch (e) { console.error(e) }
}

async function saveGratitude() {
  if (!gratitude1.value) return
  try {
    const { data } = await supabase.from(TABLES.GRATITUDES).upsert({
      date: gratitudeDate.value,
      item1: gratitude1.value,
      item2: gratitude2.value,
      item3: gratitude3.value,
      emotions: emotions.value,
      extra: gratitudeExtra.value,
    }, { onConflict: 'date' }).select()
    if (data) {
      const idx = gratitudes.value.findIndex(g => g.date === gratitudeDate.value)
      if (idx >= 0) gratitudes.value[idx] = data[0]
      else gratitudes.value.unshift(data[0])
      gratitude1.value = ''
      gratitude2.value = ''
      gratitude3.value = ''
      emotions.value = ''
      gratitudeExtra.value = ''
    }
  } catch (e) { console.error('保存失败', e) }
}

async function deleteSnippet(s) {
  if (!confirm('确定删除？')) return
  try {
    await supabase.from(TABLES.SNIPPETS).delete().eq('id', s.id)
    outputs.value = outputs.value.filter(x => x.id !== s.id)
    inspirations.value = inspirations.value.filter(x => x.id !== s.id)
  } catch (e) { console.error(e) }
}

async function deleteGratitude(g) {
  if (!confirm('确定删除这篇日记？')) return
  try {
    await supabase.from(TABLES.GRATITUDES).delete().eq('date', g.date)
    gratitudes.value = gratitudes.value.filter(x => x.date !== g.date)
  } catch (e) { console.error(e) }
}

onMounted(loadData)
</script>

<style scoped>
.card-subtitle {
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 12px;
  margin-top: -8px;
}

.snippet-item {
  padding: 12px 0;
  border-bottom: 1px solid var(--border-soft);
}

.snippet-item:last-child {
  border-bottom: none;
}

.snippet-meta {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
}

.snippet-date {
  font-size: 11px;
  color: var(--text-muted);
  flex: 1;
}

.snippet-content {
  font-size: 14px;
  line-height: 1.7;
  color: var(--text-primary);
  text-indent: 2em;
  white-space: pre-wrap;
  word-break: break-word;
  margin-bottom: 6px;
}

.snippet-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

/* 感恩 */
.gratitude-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.gratitude-item {
  display: flex;
  gap: 8px;
  align-items: center;
}

.gratitude-item .input {
  flex: 1;
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
}

.gratitude-text {
  font-size: 14px;
  color: var(--text-primary);
  line-height: 1.6;
}

.emotions-row {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
  margin-top: 8px;
}

.er-label {
  font-size: 12px;
  color: var(--text-muted);
}

.diary-item {
  padding: 12px 0;
  border-bottom: 1px solid var(--border-soft);
}

.diary-item:last-child {
  border-bottom: none;
}

.diary-header {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}

.diary-date {
  font-size: 13px;
  color: var(--primary-dark);
  font-weight: 500;
  flex: 1;
}

.diary-extra {
  font-size: 13px;
  color: var(--text-secondary);
  text-indent: 2em;
  line-height: 1.7;
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px dashed var(--border-soft);
}

/* 灵感延伸问题 */
.follow-questions {
  margin-top: 10px;
  padding: 10px 12px;
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  border-left: 3px solid var(--accent-yellow);
}

.fq-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--accent-brown);
  margin-bottom: 6px;
}

.fq-item {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.8;
  text-indent: 0;
}

.inspiration-item {
  padding: 12px 0;
  border-bottom: 1px solid var(--border-soft);
}

.inspiration-item:last-child {
  border-bottom: none;
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
