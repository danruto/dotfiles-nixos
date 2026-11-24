import { atom, read, update } from 'claude-code'
import type { Color, EngineInterface, Register, SessionRateLimit } from 'claude-code'

import type { Step } from '../types'

const step = atom({ plugin: 'statusbar', key: 'step' } as const, null as Step | null, { shape: 'step-1' })
const apiMs = atom({ plugin: 'statusbar', key: 'apiMs' } as const, 0)
const pr = atom({ plugin: 'statusbar', key: 'pr' } as const, null as number | null)

const SEP = ' │ '
const CACHE_TTL_MIN = 60

type Part = { text: string; color?: Color; dim?: boolean }
type Segment = { parts: Part[]; priority: number }

export const pctColor = (p: number): Color =>
  p >= 80 ? 'error' : p >= 60 ? 'warning' : 'success'

export const prettyModel = (id: string): string => {
  const isLong = /\[1m\]$/i.test(id)
  const [family, ...version] = id
    .replace(/\[1m\]$/i, '')
    .replace(/^claude-/, '')
    .replace(/-\d{8}$/, '')
    .split('-')
  const name = (family ?? '').charAt(0).toUpperCase() + (family ?? '').slice(1)

  return [name, version.join('.'), isLong ? '1M' : ''].filter(Boolean).join(' ')
}

export const span = (ms: number): string => {
  const m = Math.max(0, Math.floor(ms / 60000))
  if (m >= 1440) return `${Math.floor(m / 1440)}d${Math.floor((m % 1440) / 60)}h`
  if (m >= 60) return `${Math.floor(m / 60)}h${m % 60}m`

  return `${m}m`
}

export const bar = (p: number, cells = 8): string => {
  const filled = Math.min(cells, Math.round((p / 100) * cells))

  return '▰'.repeat(filled) + '▱'.repeat(cells - filled)
}

const LIMIT_LABEL: Record<string, string> = { five_hour: '5h', seven_day: 'wk', spend_limit: '$lim' }

const limitSegment = (l: SessionRateLimit, now: number): Segment => {
  const parts: Part[] = [
    { text: `${LIMIT_LABEL[l.kind] ?? l.kind} `, dim: true },
    { text: `${Math.floor(l.percentUsed)}%`, color: pctColor(l.percentUsed) },
  ]
  const resets = l.resetsAt ? Date.parse(l.resetsAt) - now : NaN
  if (resets > 0) parts.push({ text: ` ${span(resets)}`, dim: true })

  return { parts, priority: l.kind === 'five_hour' ? 2 : 4 }
}

const width = (s: Segment) => s.parts.reduce((n, p) => n + p.text.length, 0)

export const fit = (segments: Segment[], columns: number): Segment[] => {
  const kept = [...segments]
  const total = () => kept.reduce((n, s) => n + width(s), 0) + SEP.length * (kept.length - 1)
  while (kept.length > 1 && total() > columns) {
    const drop = kept.reduce((lo, s, i) => (s.priority > (kept[lo]?.priority ?? -1) ? i : lo), 0)
    kept.splice(drop, 1)
  }

  return kept
}

const refreshPr = async ($: EngineInterface) => {
  const ran = await $.process.run(['gh', 'pr', 'view', '--json', 'number', '-q', '.number'], {
    cwd: await $.session.cwd(),
    timeoutMs: 5000,
  }).catch(() => null)
  const n = ran && ran.exitCode === 0 ? Number.parseInt(ran.stdout.trim(), 10) : NaN
  await update($, pr, () => (Number.isFinite(n) ? n : null))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    $.clock.every(30_000, () => $.ui.invalidate('ui.render'))
    void refreshPr($)

    return next(e)
  })

  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) return yield* next(e)

    const startedAt = await $.clock.now()
    const res = yield* next(e)
    const at = await $.clock.now()
    await update($, apiMs, ms => ms + (at - startedAt))
    if (res.usage) {
      const u = res.usage
      const s: Step = {
        model: u.model || e.model,
        effort: typeof e.effort === 'string' ? e.effort : null,
        at,
        cacheRead: u.cache_read_input_tokens,
        cacheWrite: u.cache_creation_input_tokens,
        fresh: u.input_tokens,
      }
      await update($, step, () => s)
    }

    return res
  })

  on('turn.complete', ($, e, next) => {
    if (e.agentId === undefined) void refreshPr($)

    return next(e)
  })

  on('session.measure', ($, e, next) => {
    $.ui.invalidate('ui.render')

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const [usage, now, last, api, prNum, sessionModel] = await Promise.all([
      $.session.usage(),
      $.clock.now(),
      read($, step),
      read($, apiMs),
      read($, pr),
      $.session.model(),
    ])

    const segments: Segment[] = []

    const model: Part[] = [{ text: prettyModel(last?.model ?? sessionModel), color: 'claude' }]
    if (last?.effort) model.push({ text: ` ${last.effort}`, dim: true })
    segments.push({ parts: model, priority: 0 })

    const elapsed = now - usage.startedAt
    segments.push({
      parts: [{ text: span(elapsed) }, { text: ' api ', dim: true }, { text: span(api) }],
      priority: 5,
    })

    if (usage.cost) {
      const parts: Part[] = [{ text: `$${usage.cost.usd.toFixed(2)}` }]
      if (elapsed >= 300_000) {
        parts.push({ text: ` $${((usage.cost.usd * 3_600_000) / elapsed).toFixed(2)}/h`, dim: true })
      }
      segments.push({ parts, priority: 3 })
    }

    const ctx = usage.context.percent
    if (ctx !== undefined) {
      segments.push({
        parts: [
          { text: 'ctx ', dim: true },
          { text: bar(ctx), color: pctColor(ctx) },
          { text: ` ${Math.floor(ctx)}%`, color: pctColor(ctx) },
        ],
        priority: 1,
      })
    }

    const cacheTotal = last ? last.cacheRead + last.cacheWrite + last.fresh : 0
    if (last && cacheTotal > 0) {
      const ageMin = Math.floor((now - last.at) / 60000)
      const ageColor: Color =
        ageMin >= CACHE_TTL_MIN ? 'error' : ageMin >= CACHE_TTL_MIN - 15 ? 'warning' : 'success'
      segments.push({
        parts: [
          { text: 'cache ', dim: true },
          { text: `${Math.floor((last.cacheRead * 100) / cacheTotal)}%` },
          { text: ` ${ageMin}m`, color: ageColor },
        ],
        priority: 4,
      })
    }

    for (const l of usage.rateLimits) segments.push(limitSegment(l, now))

    if (prNum !== null) segments.push({ parts: [{ text: `PR#${prNum}`, color: 'suggestion' }], priority: 6 })

    const shown = fit(segments, e.props.bodyColumns)

    return (
      <Box>
        <Text wrap="truncate-end">
          {shown.flatMap((s, i) => [
            ...(i > 0 ? [<Text dimColor>{SEP}</Text>] : []),
            ...s.parts.map(p => (
              <Text color={p.color} dimColor={p.dim}>
                {p.text}
              </Text>
            )),
          ])}
        </Text>
      </Box>
    )
  })
}
