import { expect, test } from 'claude-code/testing'

import { bar, fit, pctColor, prettyModel, span } from './register'

test('model ids read as names', async () => {
  expect(prettyModel('claude-opus-5-5')).toEqual('Opus 5.5')
  expect(prettyModel('claude-haiku-4-5-20251001')).toEqual('Haiku 4.5')
  expect(prettyModel('claude-sonnet-5-5[1m]')).toEqual('Sonnet 5.5 1M')
})

test('durations and bars', async () => {
  expect(span(42 * 60000)).toEqual('42m')
  expect(span(133 * 60000)).toEqual('2h13m')
  expect(span((3 * 1440 + 4 * 60) * 60000)).toEqual('3d4h')
  expect(bar(50)).toEqual('▰▰▰▰▱▱▱▱')
  expect(pctColor(85)).toEqual('error')
})

test('narrow widths drop the least important segment first', async () => {
  const seg = (text: string, priority: number) => ({ parts: [{ text }], priority })
  const all = [seg('model', 0), seg('ctx 40%', 1), seg('PR#12', 6)]
  expect(fit(all, 100).length).toEqual(3)
  expect(fit(all, 18).map(s => s.parts[0]?.text)).toEqual(['model', 'ctx 40%'])
  expect(fit(all, 1).map(s => s.parts[0]?.text)).toEqual(['model'])
})
