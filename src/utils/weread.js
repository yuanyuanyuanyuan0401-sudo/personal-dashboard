/**
 * 微信读书 API 客户端（通过 Vercel 代理绕开 CORS）
 */

const PROXY_URL = '/api/weread'

/**
 * 调用微信读书 API（通过我们自己的 Vercel 代理）
 */
async function callWereadAPI(apiKey, apiName, params = {}) {
  if (!apiKey) {
    throw new Error('请先在设置中配置微信读书 API Key')
  }

  const response = await fetch(PROXY_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      apiKey,
      apiName,
      params,
    }),
  })

  if (!response.ok) {
    const err = await response.json().catch(() => ({}))
    throw new Error(err.error || `API 请求失败: ${response.status}`)
  }

  return response.json()
}

/**
 * 获取书架列表
 */
export async function getShelf(apiKey) {
  return callWereadAPI(apiKey, '/shelf/sync', { count: 50 })
}

/**
 * 获取本周阅读统计
 */
export async function getWeeklyStats(apiKey) {
  return callWereadAPI(apiKey, '/readdata/summary', { mode: 'weekly' })
}

/**
 * 获取总阅读统计
 */
export async function getOverallStats(apiKey) {
  return callWereadAPI(apiKey, '/readdata/summary', { mode: 'annually' })
}

/**
 * 获取阅读详情（包含每日阅读时长）
 */
export async function getReadDataDetail(apiKey) {
  return callWereadAPI(apiKey, '/readdata/detail', {})
}

/**
 * 获取每日阅读时长
 */
export async function getDailyReadTime(apiKey, date) {
  return callWereadAPI(apiKey, '/readdata/daily', { date })
}

/**
 * 获取阅读历史（按天）
 */
export async function getReadHistory(apiKey, year) {
  return callWereadAPI(apiKey, '/readdata/history', { year })
}

/**
 * 获取书籍详情
 */
export async function getBookInfo(apiKey, bookId) {
  return callWereadAPI(apiKey, '/book/info', { book_id: bookId })
}

/**
 * 获取书籍笔记和划线
 */
export async function getBookNotes(apiKey, bookId) {
  return callWereadAPI(apiKey, '/notes/export', { book_id: bookId, format: 'json' })
}

/**
 * 搜索书籍
 */
export async function searchBooks(apiKey, keyword) {
  return callWereadAPI(apiKey, '/book/search', { keyword })
}

/**
 * 获取个性化推荐
 */
export async function getRecommendations(apiKey) {
  return callWereadAPI(apiKey, '/discover/recommend', { count: 12 })
}

/**
 * 验证 API Key 是否有效
 */
export async function validateApiKey(apiKey) {
  try {
    const result = await getShelf(apiKey)
    return !!result
  } catch {
    return false
  }
}
