import { Socket } from 'socket.io-client'
import { type GAME_DURATION, MULTIPLAYER_MODES } from './constant.ts'

export interface Caret {
	caretIdx: number
	wordIdx: number
}

export interface Player {
	id: string
	playerName: string
	progress: {
		caret: Caret
	}
	isHost: boolean
	isDisconnected: boolean
}

export type MultiplayerMode = (typeof MULTIPLAYER_MODES)[number]['value']

export type GameConfig =
	| {
			words: string[]
			mode: 'type-race'
	  }
	| {
			words: string[][]
			mode: 'wave-rush'
			duration: number
			waves: number
			timeBetweenRounds: number
	  }

export interface TypeRaceGameResultEntry {
	playerId: string
	stats: PlayerStats
}

export type Room = {
	roomId: string
	players: Player[]
	config: GameConfig
	typeRaceGameResult: TypeRaceGameResultEntry[]
	waveRushGameResult: WaveRushGameResult
	gameStartTime: number | null
}

export interface GameError {
	type: string
	message: string
}

export interface GameState {
	socket: Socket | null
	roomId: string | null
	players: Player[]
	config: GameConfig | null
	connected: boolean
	playerName: string | null
	error: GameError
	isGameStarted: boolean
	renderStartModal: boolean
	isHost: boolean
	typeRaceGameResult: TypeRaceGameResultEntry[]
	position: number | null
	displayFinishModal: boolean
	selectedDuration: number
	waveRushGameResult: WaveRushGameResult
	isTransitioning: boolean
	shouldHideUI: boolean

	connect: () => void
	setSelectedDuration: (duration: number) => void
	createRoom: (playerName: string) => void
	joinRoom: (roomId: string, name: string) => void
	updateCaret: (caret: Caret, roomId: string) => void
	startGame: (roomId: string | null) => void
	stopGame: (roomId: string | null) => void
	setIsGameStarted: (isGameStarted: boolean) => void
	setRenderStartModal: (renderStartModal: boolean) => void
	handlePlayerFinish: (roomId: string | null, stats: PlayerStats) => void
	setDisplayFinishModal: (displayFinishModal: boolean) => void
	resetPlayersCaret: () => void
	handleConfigChange: (config: GameConfig, roomId: string | null) => void
	playerFinishRound: (
		roomId: string | null,
		results: WaveRushRoundResultType
	) => void
	getCurrentRoundResult: () => WaveRushRoundResultType | null
	setShouldHideUI: (value: boolean) => void
}

export type GameDuration = (typeof GAME_DURATION)[number]

export interface MainGameContainerProps {
	words: string[]
	mode: 'practice' | 'multiplayer'
	duration: GameDuration
}

export const InputKey = {
	SPACE: ' ',
	BACKSPACE: 'Backspace',
	ARROW_LEFT: 'ArrowLeft',
	ARROW_RIGHT: 'ArrowRight',
	ARROW_UP: 'ArrowUp',
	ARROW_DOWN: 'ArrowDown',
	CONTROL: 'Control',
	META: 'Meta',
	SHIFT: 'Shift',
	CAPSLOCK: 'CapsLock',
	ESCAPE: 'Escape',
	FUNCTIONS: [
		'F1',
		'F2',
		'F3',
		'F4',
		'F5',
		'F6',
		'F7',
		'F8',
		'F9',
		'F10',
		'F11',
		'F12',
	],
	DELETE: 'Delete',
	INSERT: 'Insert',
	PAGEUP: 'PageUp',
	PAGEDOWN: 'PageDown',
	NUMLOCK: 'NumLock',
	TAB: 'Tab',
	ENTER: 'Enter',
	ALT: 'Alt',
}

export const BlockedKeysSet = new Set([
	InputKey.ENTER,
	InputKey.TAB,
	InputKey.ALT,
	InputKey.ARROW_UP,
	InputKey.ARROW_DOWN,
	InputKey.ARROW_LEFT,
	InputKey.ARROW_RIGHT,
	InputKey.CONTROL,
	InputKey.META,
	InputKey.SHIFT,
	InputKey.NUMLOCK,
	InputKey.CAPSLOCK,
	InputKey.ESCAPE,
	'F1',
	'F2',
	'F3',
	'F4',
	'F5',
	'F6',
	'F7',
	'F8',
	'F9',
	'F10',
	'F11',
	'F12',
	InputKey.PAGEUP,
	InputKey.PAGEDOWN,
	InputKey.DELETE,
	InputKey.INSERT,
])

export const TypingMode = {
	PRACTICE: 'practice',
	MULTIPLAYER: 'multiplayer',
}

export const PlayerColor = {
	RED: '#ef4444',
	GREEN: '#22c55e',
	AMBER: '#f59e0b',
	BLUE: '#3b82f6',
	GRAY: '#6b7280',
}

export const CharacterState = {
	CORRECT: 'correct',
	INCORRECT: 'incorrect',
	UNTYPED: 'untyped',
	OVERFLOW: 'overflow',
} as const

export type CharacterStateType =
	(typeof CharacterState)[keyof typeof CharacterState]

export type WordResultType = {
	char: string
	typedChar: string
	state: CharacterStateType
	timestamp: number
}

export type PlayerStats = {
	accuracy: number
	wpm: number
	rawWpm: number
	correct: number
	incorrect: number
	overflow: number
	missed: number
	timeElapsed: number
}

export type WaveRushRoundResultType = PlayerStats & {
	playerId: string
	timeElapsed: number
}

export type WaveRushGameResult = {
	byPlayer: Record<string, WaveRushRoundResultType[]>
	byRound: Record<number, WaveRushRoundResultType[]>
	currentRound: number
}

export type FieldType = {
	mode: MultiplayerMode
	roundDuration: number
	waves: number
	timeBetweenRounds: number
}

export interface LobbySettingsFormProps {
	config: GameConfig
	isHost: boolean
	multiplayerMode: MultiplayerMode
	onModeChange: (mode: MultiplayerMode) => void
	onSubmit: (values: FieldType) => void
}

export interface LeaderboardEntry {
	user: {
		id: string
		playerName: string
	}
	accuracy: number
	wpm: number
	rawWpm: number
	mode: number
	recordedAt: Date
}

export interface LeaderboardData {
	entries: LeaderboardEntry[]
	totalEntries: number
}
