import { expect, test } from 'claude-code/testing'

import { msToReset, nudgeHour, nyDate, parseStatus, shouldNudge, statusLine } from './puffer'

// 2026-11-16 20:48 CST = 21:48 EST = 02:48Z on the 17th; reset is 05:00Z, 2h 12m away.
const NOW = Date.parse('2026-11-17T02:48:00Z')
const TODAY = '2026-11-16'
const done = { diveDate: TODAY, diveDone: true, depthMeters: 4320, streak: 6 }
const notDone = { diveDate: TODAY, diveDone: false }

test('the dive date is New York’s, and rolls at its midnight', () => {
  expect(nyDate(NOW)).toBe(TODAY)
  expect(nyDate(Date.parse('2026-11-17T05:00:00Z'))).toBe('2026-11-17')
  expect(nyDate(Date.parse('2026-07-01T03:59:00Z'))).toBe('2026-06-30') // summer time
})

test('time to reset counts to the next New York midnight', () => {
  expect(msToReset(NOW)).toBe((2 * 60 + 12) * 60_000)
})

test('time to reset is right on days the clocks change', () => {
  // 2026-03-08 01:00 EST: spring forward at 02:00, so the day is 23h long; midnight is 22h away.
  expect(msToReset(Date.parse('2026-03-08T06:00:00Z'))).toBe(22 * 3_600_000)
  // 2026-11-01 00:30 EDT: fall back at 02:00, so the day is 25h long; midnight is 24.5h away.
  expect(msToReset(Date.parse('2026-11-01T04:30:00Z'))).toBe(24.5 * 3_600_000)
})

test('not done', () => {
  expect(statusLine(notDone, NOW)).toBe('><(((°>  dive not done · resets in 2h 12m')
})

test('done, with and without depth and streak', () => {
  expect(statusLine(done, NOW)).toBe('><(((°>✓ dove today · 4,320m · streak 6')
  expect(statusLine({ diveDate: TODAY, diveDone: true }, NOW)).toBe('><(((°>✓ dove today')
})

test('stale date reads as not done', () => {
  expect(statusLine({ ...done, diveDate: '2026-11-15' }, NOW)).toBe(
    '><(((°>  dive not done · resets in 2h 12m',
  )
})

test('missing file, garbage file and unknown status read as unknown', () => {
  const unknown = '><(((°>? dive status unknown · open the puffer'
  expect(statusLine(parseStatus(null), NOW)).toBe(unknown)
  expect(statusLine(parseStatus('{nope'), NOW)).toBe(unknown)
  expect(statusLine(parseStatus('[1,2]'), NOW)).toBe(unknown)
  expect(statusLine({ diveDate: TODAY, diveDone: null }, NOW)).toBe(unknown)
})

test('parseStatus reads the reminder hour: a number, null for off, absent in older files', () => {
  expect(parseStatus('{"diveDate":"2026-11-16","diveDone":false,"reminderHour":20}')?.reminderHour).toBe(20)
  expect(parseStatus('{"diveDate":"2026-11-16","diveDone":false,"reminderHour":null}')?.reminderHour).toBe(null)
  expect(parseStatus('{"diveDate":"2026-11-16","diveDone":false}')?.reminderHour).toBe(undefined)
  expect(parseStatus('{"diveDate":"2026-11-16","diveDone":false,"reminderHour":"7"}')?.reminderHour).toBe(undefined)
})

test('the nudge hour follows the app: its hour, never when off, 19 when unknown', () => {
  expect(nudgeHour({ diveDate: TODAY, diveDone: false, reminderHour: 21 })).toBe(21)
  expect(nudgeHour({ diveDate: TODAY, diveDone: false, reminderHour: null })).toBe(null)
  expect(nudgeHour({ diveDate: TODAY, diveDone: false })).toBe(19)
  expect(nudgeHour(null)).toBe(19)
})

test('parseStatus keeps the fields the app writes', () => {
  const text = JSON.stringify({ ...done, lastRoom: 'WXYZ', updatedAt: 'x' })
  expect(parseStatus(text)).toEqual({ ...done, lastRoom: 'WXYZ' })
})

// 19:00 CST on 2026-11-16 (= 20:00 New York, same dive day).
const SEVEN_PM_NOV16 = Date.parse('2026-11-17T01:00:00Z')

test('nudge once a day, after reminder time, while not done', () => {
  expect(shouldNudge(notDone, NOW, SEVEN_PM_NOV16, undefined)).toBe(true)
  expect(shouldNudge(null, NOW, SEVEN_PM_NOV16, undefined)).toBe(true)
  expect(shouldNudge(notDone, NOW, SEVEN_PM_NOV16, TODAY)).toBe(false)
  expect(shouldNudge(done, NOW, SEVEN_PM_NOV16, undefined)).toBe(false)
  expect(shouldNudge(notDone, SEVEN_PM_NOV16 - 60_000, SEVEN_PM_NOV16, undefined)).toBe(false)
  expect(shouldNudge(notDone, NOW, SEVEN_PM_NOV16, '2026-11-15')).toBe(true)
})

test('no nudge after the reset but before local midnight, and the next evening still nudges', () => {
  // 23:30 CST on the 16th is already the 17th in New York; the reminder time (19:00 on the 16th) belongs to the 16th.
  const lateNight = Date.parse('2026-11-17T05:30:00Z')
  const yesterdaysStatus = { diveDate: TODAY, diveDone: true }
  expect(shouldNudge(yesterdaysStatus, lateNight, SEVEN_PM_NOV16, undefined)).toBe(false)
  // So the 17th's nudge is still owed at 19:05 CST on the 17th.
  const sevenPmNov17 = SEVEN_PM_NOV16 + 86_400_000
  expect(shouldNudge(yesterdaysStatus, sevenPmNov17 + 300_000, sevenPmNov17, undefined)).toBe(true)
})
