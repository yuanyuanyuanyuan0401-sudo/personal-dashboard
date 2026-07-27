/**
 * 微信读书 API 客户端
 * 通过官方 Skills API Key 读取用户的阅读数据
 */

const WEREAD_API_GATEWAY = 'https://i.weread.qq.com/api/agent/gateway'

/**
 * 调用微信读书官方 API
 * @param {string} apiKey - 用户在 weread.qq.com/r/weread-skills 获取的 API Key
 * @param {string} apiName - 接口名称
 * @param {object} params - 请求参数
 */
async function callWereadAPI(apiKey, apiName, params = {}) {
  if (!apiKey) {
    throw new Error('请先在设置中配置微信读书 API Key')
  }

  const response = await fetch(WEREAD_API_GATEWAY, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      api_name: apiName,
      skill_version: '1.0.4',
      ...params,
    }),
  })

  if (!response.ok) {
    throw new Error(`API 请求失败: ${response.status}`)
  }

  return response.json()
}

/**
 * 获取书架列表（最近阅读）
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
