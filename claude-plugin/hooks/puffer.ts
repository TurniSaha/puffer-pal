// Pure helpers for the puffer mod: no `$`, so they test directly.
// status.json is written by the Puffer Pal Mac app; the dive day is New York's.

export type PufferStatus = {
  diveDate: string
  diveDone: boolean | null
  depthMeters?: number
  streak?: number
  lastRoom?: string
  /** The app's local reminder hour; null = reminders off; absent in files from older apps. */
  reminderHour?: number | null
}

const DEFAULT_REMINDER_HOUR = 19

const FISH = '><(((°>'
const NY = 'America/New_York'
const DAY_MS = 86_400_000

const nyParts = new Intl.DateTimeFormat('en-CA', {
  timeZone: NY,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hourCycle: 'h23',
})

function partsAt(nowMs: number): Record<string, number> {
  const out: Record<string, number> = {}
  for (const p of nyParts.formatToParts(new Date(nowMs))) {
    if (p.type !== 'literal') out[p.type] = Number(p.value)
  }
  return out
}

/** "YYYY-MM-DD" of the New York day `nowMs` falls in. */
export function nyDate(nowMs: number): string {
  const p = partsAt(nowMs)
  const pad = (n: number | undefined) => String(n ?? 0).padStart(2, '0')
  return `${p.year}-${pad(p.month)}-${pad(p.day)}`
}

const HOUR_MS = 3_600_000

/** Milliseconds until the next New York midnight. */
export function msToReset(nowMs: number): number {
  const p = partsAt(nowMs)
  const sinceMidnight = (((p.hour ?? 0) * 60 + (p.minute ?? 0)) * 60 + (p.second ?? 0)) * 1000
  // A guess assuming a 24h day; a clock change in between leaves it at 23:00 or 01:00.
  let reset = nowMs - (nowMs % 1000) + DAY_MS - sinceMidnight
  const hour = partsAt(reset).hour
  if (hour === 23) reset += HOUR_MS
  if (hour === 1) reset -= HOUR_MS
  return reset - nowMs
}

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === 'object' && v !== null && !Array.isArray(v)

/** The app's status file, or null when missing or unreadable. */
export function parseStatus(text: string | null): PufferStatus | null {
  if (text === null) return null
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    return null
  }
  if (!isRecord(raw) || typeof raw.diveDate !== 'string') return null
  const done = raw.diveDone
  const status: PufferStatus = {
    diveDate: raw.diveDate,
    diveDone: typeof done === 'boolean' ? done : null,
  }
  if (typeof raw.depthMeters === 'number') status.depthMeters = raw.depthMeters
  if (typeof raw.streak === 'number') status.streak = raw.streak
  if (typeof raw.lastRoom === 'string') status.lastRoom = raw.lastRoom
  const hour = raw.reminderHour
  if (hour === null) status.reminderHour = null
  else if (typeof hour === 'number' && Number.isInteger(hour) && hour >= 0 && hour <= 23) status.reminderHour = hour
  return status
}

/** The local hour to nudge at, mirroring the app's reminder; null when reminders are off. */
export function nudgeHour(s: PufferStatus | null): number | null {
  if (s?.reminderHour === undefined) return DEFAULT_REMINDER_HOUR
  return s.reminderHour
}

/** true / false for today, null when unknown. A status about another day is not done. */
function doneToday(s: PufferStatus | null, nowMs: number): boolean | null {
  if (s === null) return null
  if (s.diveDate !== nyDate(nowMs)) return false
  return s.diveDone
}

function formatDuration(ms: number): string {
  const minutes = Math.max(0, Math.floor(ms / 60_000))
  return `${Math.floor(minutes / 60)}h ${minutes % 60}m`
}

export function statusLine(s: PufferStatus | null, nowMs: number): string {
  const done = doneToday(s, nowMs)
  if (done === null) return `${FISH}? dive status unknown · open the puffer`
  if (!done) return `${FISH}  dive not done · resets in ${formatDuration(msToReset(nowMs))}`
  const extras = [
    s?.depthMeters !== undefined ? `${s.depthMeters.toLocaleString('en-US')}m` : null,
    s?.streak !== undefined ? `streak ${s.streak}` : null,
  ].filter((x): x is string => x !== null)
  return [`${FISH}✓ dove today`, ...extras].join(' · ')
}

/**
 * One nudge a day, from reminder time on, while the dive isn't done (unknown counts).
 * `reminderAtMs` is today's local reminder time; after New York's midnight it belongs to the
 * previous dive day, so no nudge fires (and none is used up) between 11pm and local midnight.
 */
export function shouldNudge(
  s: PufferStatus | null,
  nowMs: number,
  reminderAtMs: number,
  nudgedOn: string | undefined,
): boolean {
  const today = nyDate(nowMs)
  if (nowMs < reminderAtMs || nyDate(reminderAtMs) !== today) return false
  if (nudgedOn === today) return false
  return doneToday(s, nowMs) !== true
}

const ROOM = /^[A-Z]{4}$/

/** A 4-letter room code, uppercased, or null. */
export function roomCode(raw: string): string | null {
  const code = raw.trim().toUpperCase()
  return ROOM.test(code) ? code : null
}
