import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

const typed = { origin: { kind: 'composer' }, presentation: { isFullscreen: false, columns: 100 } } as const

function engine(on: On, opened: string[], exitCode = 0) {
  on('command.register', (_, e) => ({ value: { command: e.name } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('process.run', (_, e) => {
    opened.push(e.argv.join(' '))
    return { value: { exitCode, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
}

test('/party with a code opens that room', async ($, on) => {
  const opened: string[] = []
  engine(on, opened)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  const out = await $.command.run({ ...typed, command: 'party', args: ' wxyz ' })
  expect(opened).toEqual(['open pufferpal://party/WXYZ'])
  expect(out.text).toBe('Opening room WXYZ in the puffer 🐡')
})

test('/party with no code rejoins the last room', async ($, on) => {
  const opened: string[] = []
  engine(on, opened)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run({ ...typed, command: 'party', args: '' })
  expect(opened).toEqual(['open pufferpal://party'])
})

test('/party bad code is refused without opening anything', async ($, on) => {
  const opened: string[] = []
  engine(on, opened)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  for (const args of ['ab1', 'ABCDE', 'A B C']) {
    const out = await $.command.run({ ...typed, command: 'party', args })
    expect(out.text).toBe('Room codes are 4 letters, like /party ABCD')
  }
  expect(opened).toEqual([])
})

test('/dive opens the dive, and says so when the app is missing', async ($, on) => {
  const opened: string[] = []
  engine(on, opened, 1)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  const out = await $.command.run({ ...typed, command: 'dive', args: '' })
  expect(opened).toEqual(['open pufferpal://dive'])
  expect(out.text).toBe("Puffer Pal isn't installed. Run make install in your puffer-pal folder.")
})

// An instant on New York's 2026-11-16 that is 19:00 or later on this machine's own clock.
function eveningOfNov16(): number {
  for (let ms = Date.parse('2026-11-16T12:00:00Z'); ; ms += 3_600_000) {
    const ny = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(ms)
    if (new Date(ms).getHours() >= 19 && ny === '2026-11-16') return ms
  }
}

test('the session nudge fires once per New York day while the dive is not done', async ($, on) => {
  engine(on, [])
  mock.env(on, { HOME: '/home/t' })
  mock.store(on)
  mock.clock(on, { now: eveningOfNov16() })
  on('fs.read', () => ({ value: '{"diveDate":"2026-11-16","diveDone":false}' }))
  const toasts: string[] = []
  on('ui.toast', (_, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  expect(toasts).toEqual(['🐡 Daily Dive is still waiting. /dive to go, resets 11pm.'])
})

test('no session nudge when reminders are off in the app', async ($, on) => {
  engine(on, [])
  mock.env(on, { HOME: '/home/t' })
  mock.store(on)
  mock.clock(on, { now: eveningOfNov16() })
  on('fs.read', () => ({ value: '{"diveDate":"2026-11-16","diveDone":false,"reminderHour":null}' }))
  const toasts: string[] = []
  on('ui.toast', (_, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  expect(toasts).toEqual([])
})
