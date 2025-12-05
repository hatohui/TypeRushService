export const GAME_DURATION = [15, 30, 60, 0] as const

export const MAX_OVERFLOW = 10

export const SAMPLE_WORDS = [
	'about',
	'after',
	'again',
	'animal',
	'around',
	'before',
	// 'between',
	// 'cause',
	// 'change',
	// 'country',
	// 'different',
	// 'example',
	// 'father',
	// 'follow',
	// 'great',
	// 'house',
	// 'important',
	// 'large',
	// 'little',
	// 'mother',
	// 'number',
	// 'other',
	// 'people',
	// 'place',
	// 'point',
	// 'right',
	// 'small',
	// 'student',
	// 'system',
	// 'water',
]

export const WAVE_RUSH_WORDS = [
	['apple', 'bread', 'chair', 'dance', 'earth'],
	['flame', 'grace', 'heart', 'ivory', 'juice'],
	['knife', 'lemon', 'music', 'night', 'ocean'],
	['paint', 'queen', 'river', 'stone', 'train'],
	['unity', 'voice', 'water', 'youth', 'zebra'],
]

export const MULTIPLAYER_MODES = [
	{ value: 'type-race', label: 'Type Race' },
	{ value: 'wave-rush', label: 'Wave Rush' },
] as const
