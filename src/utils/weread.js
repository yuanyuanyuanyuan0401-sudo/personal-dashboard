/**
 * 微信读书 API 客户端（通过 Vercel 代理绕开 CORS）
 */

const PROXY_URL = '/api/weread'

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

export async function getShelf(apiKey) {
  return callWereadAPI(apiKey, '/shelf/sync', { count: 50 })
}

/**
 * 获取阅读数据详情
 * mode: weekly / monthly / annually / overall
 * 返回 readTimes: { unix_timestamp: 当天阅读秒数 }, readDays: 总天数
 */
export async function getReadDataDetail(apiKey, mode = 'monthly') {
  return callWereadAPI(apiKey, '/readdata/detail', { mode, skill_version: '1.0.3' })
}

/**
 * 智能同步：把 readTimes 转换为按日期的累计分钟数
 * 返回 { '2026-07-27': 20, ... }  单位：分钟
 */
export function parseReadTimes(readTimes) {
  if (!readTimes || typeof readTimes !== 'object') return {}
  const result = {}
  for (const [timestamp, seconds] of Object.entries(readTimes)) {
    const ts = parseInt(timestamp) * 1000  // 转毫秒
    const date = new Date(ts)
    const dateStr = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    result[dateStr] = Math.round(seconds / 60)  // 转分钟
  }
  return result
}

export async function getReadHistory(apiKey, year) {
  return callWereadAPI(apiKey, '/readdata/history', { year })
}

export async function getBookInfo(apiKey, bookId) {
  return callWereadAPI(apiKey, '/book/info', { book_id: bookId })
}

export async function getBookNotes(apiKey, bookId) {
  return callWereadAPI(apiKey, '/notes/export', { book_id: bookId, format: 'json' })
}

export async function searchBooks(apiKey, keyword) {
  return callWereadAPI(apiKey, '/store/search', { keyword, scope: 10, count: 10 })
}

export async function getRecommendations(apiKey) {
  return callWereadAPI(apiKey, '/discover/recommend', { count: 12 })
}

export async function validateApiKey(apiKey) {
  try {
    const result = await getShelf(apiKey)
    return !!result
  } catch {
    return false
  }
}
