<template>
  <div class="work-files-page">
    <div class="sub-header">
      <router-link to="/work" class="back-btn">←</router-link>
      <span class="sub-title">📚 资料汇总</span>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">把每一份资料，都收藏在这里。</div>
    </div>

    <!-- 上传 -->
    <div class="card">
      <div class="card-title">➕ 新增资料</div>
      <input v-model="form.title" class="input" placeholder="资料标题" style="margin-bottom:8px;" />
      <select v-model="form.category" class="select" style="margin-bottom:8px;">
        <option value="总结">总结</option>
        <option value="计划">计划</option>
        <option value="报告">报告</option>
        <option value="课件">课件</option>
        <option value="通知">通知</option>
        <option value="其他">其他</option>
      </select>
      <textarea v-model="form.description" class="textarea" placeholder="简介（可选）" rows="2" style="margin-bottom:8px;"></textarea>

      <div class="upload-row">
        <label class="upload-btn">
          📁 选择文件
          <input type="file" @change="handleFile" hidden />
        </label>
        <span v-if="form.file_name" class="file-name">{{ form.file_name }}</span>
        <span v-if="uploading" class="upload-status">上传中...</span>
      </div>

      <button class="btn btn-primary btn-block" @click="saveFile" :disabled="!form.title || uploading" style="margin-top:10px;">
        保存资料
      </button>
    </div>

    <!-- 资料列表 -->
    <div class="card">
      <div class="card-title">📖 我的资料</div>

      <div class="filter-row">
        <button :class="['filter-btn', { active: filterCat === 'all' }]" @click="filterCat = 'all'">全部</button>
        <button v-for="c in categories" :key="c" :class="['filter-btn', { active: filterCat === c }]" @click="filterCat = c">{{ c }}</button>
      </div>

      <div v-if="filteredFiles.length === 0" class="empty-state">
        <div class="icon">📂</div>
        <div class="text">还没有资料</div>
      </div>

      <div v-for="file in filteredFiles" :key="file.id" class="file-item">
        <div class="file-icon">{{ getFileIcon(file.file_type) }}</div>
        <div class="file-info">
          <div class="file-title">{{ file.title }}</div>
          <div class="file-meta">
            <span class="tag" :class="tagClass(file.category)">{{ file.category }}</span>
            <span>{{ formatDate(file.created_at) }}</span>
          </div>
        </div>
        <div class="file-actions">
          <button v-if="file.file_url" class="btn-icon-small" @click="previewFile(file)" title="查看">👁️</button>
          <button class="btn-icon-small danger" @click="deleteFile(file)" title="删除">✕</button>
        </div>
      </div>
    </div>

    <!-- 文件预览 -->
    <div v-if="previewFileData" class="image-overlay" @click="previewFileData = null">
      <div class="preview-content" @click.stop>
        <img v-if="previewFileData.file_type?.startsWith('image')" :src="previewFileData.file_url" />
        <iframe v-else :src="previewFileData.file_url" class="preview-iframe"></iframe>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const files = ref([])
const uploading = ref(false)
const filterCat = ref('all')
const previewFileData = ref(null)

const form = ref({
  title: '',
  category: '总结',
  description: '',
  file_name: '',
  file_url: '',
  file_type: '',
  file_size: 0,
})

const categories = ['总结', '计划', '报告', '课件', '通知', '其他']

const filteredFiles = computed(() => {
  if (filterCat.value === 'all') return files.value
  return files.value.filter(f => f.category === filterCat.value)
})

function getFileIcon(type) {
  if (!type) return '📄'
  if (type.startsWith('image')) return '🖼️'
  if (type.includes('pdf')) return '📕'
  if (type.includes('word') || type.includes('document')) return '📘'
  if (type.includes('sheet') || type.includes('excel')) return '📗'
  if (type.includes('presentation') || type.includes('powerpoint')) return '📙'
  if (type.includes('video')) return '🎬'
  if (type.includes('audio')) return '🎵'
  return '📄'
}

function tagClass(cat) {
  const map = { 总结: 'tag-yellow', 计划: 'tag-blue', 报告: 'tag-rose', 课件: 'tag-brown', 通知: 'tag' }
  return map[cat] || 'tag'
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getMonth() + 1}/${d.getDate()}`
}

async function loadFiles() {
  try {
    const { data } = await supabase
      .from(TABLES.WORK_FILES)
      .select('*')
      .order('created_at', { ascending: false })
    files.value = data || []
  } catch (e) { console.warn(e) }
}

async function handleFile(e) {
  const file = e.target.files[0]
  if (!file) return
  uploading.value = true
  const fileName = `${Date.now()}_${file.name}`

  try {
    const { data, error } = await supabase.storage
      .from('work-files')
      .upload(fileName, file)
    if (error) throw error

    const { data: { publicUrl } } = supabase.storage
      .from('work-files')
      .getPublicUrl(fileName)

    form.value.file_name = file.name
    form.value.file_url = publicUrl
    form.value.file_type = file.type
    form.value.file_size = file.size
  } catch (e) {
    console.error('上传失败', e)
    alert('上传失败，请检查 work-files 存储桶是否已创建')
  }
  uploading.value = false
}

async function saveFile() {
  if (!form.value.title) return
  try {
    const { data } = await supabase.from(TABLES.WORK_FILES).insert({
      title: form.value.title,
      category: form.value.category,
      description: form.value.description,
      file_url: form.value.file_url,
      file_type: form.value.file_type,
      file_size: form.value.file_size,
    }).select()
    if (data) {
      files.value.unshift(data[0])
      form.value = { title: '', category: '总结', description: '', file_name: '', file_url: '', file_type: '', file_size: 0 }
    }
  } catch (e) {
    console.error('保存失败', e)
    alert('保存失败，请重试')
  }
}

function previewFile(file) {
  previewFileData.value = file
}

async function deleteFile(file) {
  if (!confirm(`确定删除"${file.title}"？`)) return
  try {
    await supabase.from(TABLES.WORK_FILES).delete().eq('id', file.id)
    files.value = files.value.filter(f => f.id !== file.id)
  } catch (e) { console.error(e) }
}

onMounted(loadFiles)
</script>

<style scoped>
.upload-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.upload-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 8px 14px;
  background: var(--primary-bg);
  color: var(--primary-dark);
  border-radius: var(--radius-sm);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.file-name {
  font-size: 13px;
  color: var(--text-secondary);
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.upload-status {
  font-size: 12px;
  color: var(--warning-color);
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

.file-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid var(--border-soft);
}

.file-item:last-child {
  border-bottom: none;
}

.file-icon {
  font-size: 28px;
  flex-shrink: 0;
}

.file-info {
  flex: 1;
  min-width: 0;
}

.file-title {
  font-size: 14px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.file-meta {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-top: 4px;
  font-size: 11px;
  color: var(--text-muted);
}

.file-actions {
  display: flex;
  gap: 4px;
}

.preview-content {
  background: var(--card-bg);
  border-radius: var(--radius-md);
  max-width: 90vw;
  max-height: 90vh;
  overflow: auto;
}

.preview-content img {
  max-width: 100%;
  max-height: 90vh;
  display: block;
}

.preview-iframe {
  width: 90vw;
  height: 90vh;
  border: none;
}
</style>
