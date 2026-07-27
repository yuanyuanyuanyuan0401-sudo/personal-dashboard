<template>
  <div class="diary-page">
    <div class="page-header">
      <h1 class="page-title">日记</h1>
      <div class="header-actions">
        <router-link to="/diary/calendar" class="btn btn-secondary btn-sm">📅</router-link>
        <router-link to="/diary/gallery" class="btn btn-secondary btn-sm">🖼️</router-link>
      </div>
    </div>

    <!-- 写日记 -->
    <div class="card">
      <div class="diary-editor">
        <div class="diary-date-row">
          <input type="date" v-model="diaryDate" class="input" style="width:auto;" />
        </div>
        <textarea v-model="diaryContent" class="textarea" placeholder="今天发生了什么？写点什么吧..." rows="4"></textarea>

        <!-- 图片上传 -->
        <div class="image-upload-row">
          <label class="upload-btn">
            📷 添加图片
            <input type="file" accept="image/*" multiple @change="handleImageUpload" hidden />
          </label>
          <div v-if="uploading" class="uploading-text">上传中...</div>
        </div>

        <!-- 图片预览 -->
        <div v-if="newImages.length > 0" class="image-preview-list">
          <div v-for="(img, idx) in newImages" :key="idx" class="preview-item">
            <img :src="img.url" class="preview-thumb" />
            <button class="remove-img" @click="removeImage(idx)">✕</button>
          </div>
        </div>

        <button class="btn btn-primary btn-block" @click="saveDiary" :disabled="saving">
          {{ saving ? '保存中...' : '保存日记' }}
        </button>
      </div>
    </div>

    <!-- 历史日记列表 -->
    <div v-if="diaries.length > 0" class="diary-list">
      <div v-for="entry in diaries" :key="entry.id" class="card diary-entry-card">
        <div class="diary-entry-header">
          <span class="diary-date">{{ formatDate(entry.date) }}</span>
          <button class="btn-icon-small danger" @click="deleteDiary(entry)">✕</button>
        </div>
        <div class="diary-entry-content">{{ entry.content }}</div>
        <div v-if="entry.images && entry.images.length > 0" class="diary-entry-images">
          <img
            v-for="(img, idx) in entry.images"
            :key="idx"
            :src="img"
            class="diary-thumb"
            @click="previewImage = img"
          />
        </div>
      </div>
    </div>
    <div v-else class="empty-state">
      <div class="icon">📝</div>
      <div class="text">还没有日记，开始写第一篇吧</div>
    </div>

    <!-- 图片预览遮罩 -->
    <div v-if="previewImage" class="image-overlay" @click="previewImage = null">
      <img :src="previewImage" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const diaryDate = ref(new Date().toISOString().split('T')[0])
const diaryContent = ref('')
const diaries = ref([])
const saving = ref(false)
const uploading = ref(false)
const newImages = ref([])
const previewImage = ref(null)

async function loadDiaries() {
  try {
    const { data } = await supabase
      .from(TABLES.DIARY)
      .select('*')
      .order('date', { ascending: false })
      .limit(50)
    diaries.value = (data || []).map(d => ({
      ...d,
      images: d.images || [],
    }))
  } catch (e) {
    console.warn('加载日记失败', e)
  }
}

async function handleImageUpload(e) {
  const files = e.target.files
  if (!files.length) return
  uploading.value = true

  for (const file of files) {
    const fileName = `${Date.now()}_${file.name}`
    try {
      const { data, error } = await supabase.storage
        .from('diary-images')
        .upload(fileName, file)

      if (error) {
        console.error('上传失败', error)
        continue
      }

      const { data: { publicUrl } } = supabase.storage
        .from('diary-images')
        .getPublicUrl(fileName)

      newImages.value.push({ name: fileName, url: publicUrl })
    } catch (e) {
      console.error('上传异常', e)
    }
  }

  uploading.value = false
}

function removeImage(idx) {
  newImages.value.splice(idx, 1)
}

async function saveDiary() {
  if (!diaryContent.value.trim()) {
    alert('请输入日记内容')
    return
  }

  saving.value = true
  try {
    const entry = {
      date: diaryDate.value,
      content: diaryContent.value,
      images: newImages.value.map(img => img.url),
    }

    const { data } = await supabase.from(TABLES.DIARY).insert(entry).select()
    if (data) {
      diaries.value.unshift({ ...data[0], images: data[0].images || [] })
    }
    diaryContent.value = ''
    newImages.value = []
  } catch (e) {
    console.error('保存失败', e)
    alert('保存失败，请重试')
  }
  saving.value = false
}

async function deleteDiary(entry) {
  if (!confirm('确定删除这篇日记？')) return
  try {
    await supabase.from(TABLES.DIARY).delete().eq('id', entry.id)
    diaries.value = diaries.value.filter(d => d.id !== entry.id)
  } catch (e) {
    console.error('删除失败', e)
  }
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 星期${weekdays[d.getDay()]}`
}

onMounted(loadDiaries)
</script>

<style scoped>
.header-actions {
  display: flex;
  gap: 8px;
}
.btn-sm {
  padding: 8px 12px;
  font-size: 16px;
}

.diary-date-row {
  margin-bottom: 8px;
}

.image-upload-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 8px 0;
}
.upload-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 8px 14px;
  background: var(--primary-bg);
  color: var(--primary-color);
  border-radius: var(--radius-sm);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}
.uploading-text {
  font-size: 13px;
  color: var(--text-muted);
}

.image-preview-list {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 10px;
}
.preview-item {
  position: relative;
  width: 80px;
  height: 80px;
}
.preview-thumb {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: var(--radius-sm);
}
.remove-img {
  position: absolute;
  top: -4px;
  right: -4px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: none;
  background: var(--danger-color);
  color: white;
  font-size: 10px;
  cursor: pointer;
}

.diary-entry-card {
  padding: 14px;
}
.diary-entry-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.diary-date {
  font-size: 14px;
  font-weight: 600;
  color: var(--primary-color);
}
.diary-entry-content {
  font-size: 14px;
  line-height: 1.7;
  white-space: pre-wrap;
  word-break: break-word;
  color: var(--text-primary);
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
  transition: opacity 0.2s;
}
.diary-thumb:active {
  opacity: 0.8;
}
</style>
