/**
 * 微信读书 API 代理 - Vercel Serverless Function
 * 解决浏览器 CORS 跨域问题
 */

const WEREAD_API_GATEWAY = 'https://i.weread.qq.com/api/agent/gateway'

export default async function handler(req, res) {
  // 设置 CORS 响应头
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization')

  if (req.method === 'OPTIONS') {
    return res.status(200).end()
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { apiKey, apiName, params = {} } = req.body || {}

    if (!apiKey) {
      return res.status(400).json({ error: '缺少 apiKey' })
    }
    if (!apiName) {
      return res.status(400).json({ error: '缺少 apiName' })
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

    const data = await response.json()
    return res.status(response.status).json(data)
  } catch (error) {
    return res.status(500).json({
      error: '代理请求失败',
      message: error.message,
    })
  }
}
