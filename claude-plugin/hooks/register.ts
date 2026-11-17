import type { EngineInterface, Register } from 'claude-code'

import { nudgeHour, nyDate, parseStatus, roomCode, shouldNudge, statusLine } from './puffer'

const STATUS_PATH = 'Library/Application Support/PufferPal/status.json'
const NUDGED_KEY = 'nudgedOn'
const REFRESH_MS = 60_000
const NUDGE = '🐡 Daily Dive is still waiting. /dive to go, resets 11pm.'
const NOT_INSTALLED = "Puffer Pal isn't installed. Run make install in your puffer-pal folder."
const BAD_CODE = 'Room codes are 4 letters, like /party ABCD'

async function readStatus($: EngineInterface) {
  const home = await $.env.get('HOME')
  if (!home) return null
  try {
    return parseStatus(await $.fs.read(`${home}/${STATUS_PATH}`))
  } catch {
    return null // no file yet, or unreadable: shown as unknown
  }
}

async function refresh($: EngineInterface, allowNudge: boolean) {
  const status = await readStatus($)
  const now = await $.clock.now()
  $.ui.status(statusLine(status, now))
  const hour = nudgeHour(status)
  if (!allowNudge || hour === null) return
  const nudgedOn = await $.store.get(NUDGED_KEY)
  const reminderAt = new Date(now).setHours(hour, 0, 0, 0)
  if (shouldNudge(status, now, reminderAt, typeof nudgedOn === 'string' ? nudgedOn : undefined)) {
    $.ui.toast(NUDGE)
    await $.store.set(NUDGED_KEY, nyDate(now))
  }
}

async function openInPuffer($: EngineInterface, url: string, done: string) {
  try {
    const { exitCode } = await $.process.run(['open', url], { timeoutMs: 10_000 })
    return { text: exitCode === 0 ? done : NOT_INSTALLED }
  } catch {
    return { text: NOT_INSTALLED }
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'party',
      description: 'Join a Krillion Puffer Party room in the puffer (no code = last room)',
      argumentHint: '[CODE]',
    })
    await $.command.register({ name: 'dive', description: "Open today's Krillion Daily Dive in the puffer" })
    await refresh($, true)
    $.clock.every(REFRESH_MS, () => void refresh($, false))
    return next(e)
  })

  on('command.run', { command: 'party' }, async ($, e) => {
    const raw = e.args.trim()
    if (raw === '') return openInPuffer($, 'pufferpal://party', 'Opening your last room in the puffer 🐡')
    const code = roomCode(raw)
    if (!code) return { text: BAD_CODE }
    return openInPuffer($, `pufferpal://party/${code}`, `Opening room ${code} in the puffer 🐡`)
  })

  on('command.run', { command: 'dive' }, async $ =>
    openInPuffer($, 'pufferpal://dive', "Opening today's Daily Dive in the puffer 🐡"),
  )
}
