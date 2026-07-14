interface StatusContext {
	ui: {
		setStatus(id: string, text: string | undefined): void;
	};
	sessionManager: {
		getEntries?(): SessionEntry[];
		getBranch(): SessionEntry[];
	};
	getContextUsage(): { percent?: number } | undefined;
}

interface SessionEntry {
	type?: string;
	message?: {
		role?: string;
		usage?: {
			input?: number;
			output?: number;
			cost?: { total?: number };
		};
	};
}

interface PiAPI {
	events: {
		on(name: string, handler: (payload: unknown) => void): void;
	};
	on(
		name: string,
		handler: (event: unknown, context: StatusContext) => void,
	): void;
}

interface UsageState {
	provider?: string;
	usage?: {
		windows: Array<{
			label: string;
			usedPercent: number;
		}>;
	};
}

const STATUS_ID = "subscription-usage";

function formatCount(value: number): string {
	if (value < 1_000) return value.toString();
	if (value < 10_000) return `${(value / 1_000).toFixed(1)}k`;
	if (value < 1_000_000) return `${Math.round(value / 1_000)}k`;
	if (value < 10_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
	return `${Math.round(value / 1_000_000)}M`;
}

export default function (pi: PiAPI): void {
	let context: StatusContext | undefined;
	let state: UsageState | undefined;

	const render = (): void => {
		if (!context) return;

		const entries =
			context.sessionManager.getEntries?.() ??
			context.sessionManager.getBranch();
		let input = 0;
		let output = 0;
		let cost = 0;
		for (const entry of entries) {
			if (entry.type !== "message" || entry.message?.role !== "assistant")
				continue;
			input += entry.message.usage?.input ?? 0;
			output += entry.message.usage?.output ?? 0;
			cost += entry.message.usage?.cost?.total ?? 0;
		}

		const contextPercent = context.getContextUsage()?.percent;
		const contextLabel =
			contextPercent === undefined ? "--" : `${Math.round(contextPercent)}%`;
		const session = [
			`↑${formatCount(input)} ↓${formatCount(output)}`,
			`ctx ${contextLabel}`,
			`$${cost.toFixed(3)}`,
		];
		let windows: string[] = [];
		if (state?.provider) {
			windows = (state.usage?.windows ?? []).flatMap((window) => {
				if (!Number.isFinite(window.usedPercent)) return [];
				const label = /^(672|696|720|744)h$/.test(window.label)
					? "Month"
					: window.label;
				const remaining = Math.max(
					0,
					Math.min(100, Math.round(100 - window.usedPercent)),
				);
				return [`${label} ${remaining}% left`];
			});
		}

		context.ui.setStatus(STATUS_ID, [...session, ...windows].join(" · "));
	};

	const update = (payload: unknown): void => {
		state = (payload as { state?: UsageState }).state;
		render();
	};

	pi.events.on("usage-core:ready", update);
	pi.events.on("usage-core:update-current", update);

	pi.on("session_start", (_event, ctx) => {
		context = ctx;
		render();
	});

	pi.on("turn_end", (_event, ctx) => {
		context = ctx;
		render();
	});

	pi.on("session_shutdown", () => {
		context?.ui.setStatus(STATUS_ID, undefined);
		context = undefined;
	});
}
