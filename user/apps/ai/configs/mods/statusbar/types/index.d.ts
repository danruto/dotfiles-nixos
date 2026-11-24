export type Step = {
  model: string
  effort: string | null
  at: number
  cacheRead: number
  cacheWrite: number
  fresh: number
}

declare module 'claude-code' {
  interface PluginState {
    statusbar: { step: { shape: string; value: Step | null }; apiMs: number; pr: number | null }
  }
}
