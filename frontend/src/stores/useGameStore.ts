import { create } from 'zustand'
import { io } from 'socket.io-client'
import type {
	Caret,
	Player,
	GameState,
	Room,
	GameError,
	PlayerStats,
	GameConfig,
	WaveRushRoundResultType,
	WaveRushGameResult,
} from '../common/types.ts'
import throttle from 'lodash.throttle'

export const useGameStore = create<GameState>((set, get) => ({
	socket: null,
	roomId: null,
	players: [],
	config: null,
	connected: false,
	playerName: null,
	error: { type: '', message: '' },
	isGameStarted: false,
	renderStartModal: false,
	isHost: false,
	typeRaceGameResult: [],
	position: null,
	displayFinishModal: false,
	selectedDuration: 15,
	waveRushGameResult: {
		byPlayer: {},
		byRound: {},
		currentRound: 0,
	},
	isTransitioning: false,
	shouldHideUI: false,

	connect: () => {
		if (get().socket) return
		const socket = io(
			import.meta.env.VITE_SOCKET_URL || 'http://localhost:3000'
		)
		set({ socket })

		socket.on('connect', () => {
			set({ connected: true, socket })
		})

		socket.on('roomCreated', (room: Room) => {
			set({
				roomId: room.roomId,
				players: room.players,
				config: room.config,
				isHost: true,
			})
		})

		socket.on('roomJoined', (room: Room) => {
			set({
				roomId: room.roomId,
				players: room.players,
				config: room.config,
				error: { type: '', message: '' },
			})
		})

		socket.on('errorEvent', (err: GameError) => {
			set({ error: err })
		})

		socket.on('playersUpdated', (players: Player[]) => {
			set({ players })
		})

		socket.on(
			'typeRaceGameResultUpdated',
			(playerId: string, stats: PlayerStats) => {
				const newTypeRaceGameResult = [
					...get().typeRaceGameResult,
					{ playerId, stats },
				]
				if (playerId === get().socket?.id) {
					const position = newTypeRaceGameResult.findIndex(
						e => e.playerId === playerId
					)
					set({ typeRaceGameResult: newTypeRaceGameResult, position: position })
				} else {
					set({ typeRaceGameResult: newTypeRaceGameResult })
				}
			}
		)

		socket.on('gameFinished', () => {
			set({ displayFinishModal: true, isGameStarted: false })
		})

		socket.on(
			'caretUpdated',
			throttle(
				(payload: { playerId: string; caret: Caret }) => {
					set(state => ({
						players: state.players.map(p =>
							p.id === payload.playerId
								? {
										...p,
										progress: {
											...p.progress,
											caret: payload.caret,
										},
									}
								: p
						),
					}))
				},
				500,
				{ leading: true, trailing: true }
			)
		)

		socket.on('disconnect', () => {
			set({
				connected: false,
				roomId: null,
				players: [],
				config: null,
				error: { type: '', message: '' },
				socket: null,
			})
		})

		socket.on('gameStarted', () => {
			get().resetPlayersCaret()
			set({
				isTransitioning: false,
				renderStartModal: true,
				typeRaceGameResult: [],
				waveRushGameResult: {
					byPlayer: {},
					byRound: {},
					currentRound: 0,
				},
			})
		})

		socket.on('gameStopped', () => {
			set({
				isGameStarted: false,
				isTransitioning: false,
				typeRaceGameResult: [],
				waveRushGameResult: {
					byPlayer: {},
					byRound: {},
					currentRound: 0,
				},
			})
			get().resetPlayersCaret()
		})

		socket.on('configChanged', config => {
			set({ config: config })
		})

		socket.on('waveRushGameStateUpdated', (gameState: WaveRushGameResult) => {
			set({ waveRushGameResult: gameState })
		})

		socket.on('hostChanged', () => {
			set({ isHost: true })
		})

		// ✅ Server tells clients to start transition
		socket.on('startTransition', () => {
			set({ isTransitioning: true })
		})

		// ✅ Server tells clients next round started
		socket.on('nextRoundStarted', () => {
			set({ isTransitioning: false })
		})
	},

	createRoom: (playerName: string) => {
		get().socket?.emit('createRoom', { playerName: playerName })
	},

	setSelectedDuration: (duration: number) => {
		set({ selectedDuration: duration })
	},

	joinRoom: (roomId: string, playerName: string) => {
		get().socket?.emit('joinRoom', { roomId, playerName })
	},

	startGame: (roomId: string | null) => {
		if (!roomId) return
		get().socket?.emit('startGame', { roomId })
	},

	stopGame: (roomId: string | null) => {
		if (!roomId) return
		get().socket?.emit('stopGame', { roomId })
	},

	setIsGameStarted: (isGameStarted: boolean) => {
		set({ isGameStarted: isGameStarted })
	},

	setRenderStartModal: (renderStartModal: boolean) => {
		set({ renderStartModal: renderStartModal })
	},

	updateCaret: (caret: Caret, roomId: string) => {
		const socket = get().socket
		if (!socket) return

		set(state => ({
			players: state.players.map(p =>
				p.id === socket.id ? { ...p, progress: { caret } } : p
			),
		}))

		socket.emit('updateCaret', {
			caretIdx: caret.caretIdx,
			wordIdx: caret.wordIdx,
			roomId,
		})
	},

	handleConfigChange: (config: GameConfig, roomId: string | null) => {
		const socket = get().socket
		if (!socket || !config || !config.mode || !roomId) {
			return
		}
		socket.emit('configChange', { config, roomId })
	},

	handlePlayerFinish: (roomId: string | null, stats: PlayerStats) => {
		const socket = get().socket
		if (!socket || !roomId) return

		socket.emit('playerFinished', {
			roomId,
			stats,
		})
	},

	setDisplayFinishModal: (displayFinishModal: boolean) => {
		set({ displayFinishModal: displayFinishModal })
	},

	playerFinishRound: (
		roomId: string | null,
		results: WaveRushRoundResultType
	) => {
		const socket = get().socket
		if (!socket || !roomId) return
		socket.emit('playerFinishRound', {
			roomId,
			results,
		})
	},

	getCurrentRoundResult: () => {
		if (!get().socket) return null
		const results =
			get().waveRushGameResult.byRound[get().waveRushGameResult.currentRound] ||
			[]
		return results.find(r => r.playerId === get().socket?.id) || null
	},

	resetPlayersCaret: () => {
		set(state => ({
			players: state.players.map(player => ({
				...player,
				progress: {
					...player.progress,
					caret: {
						caretIdx: -1,
						wordIdx: 0,
					},
				},
			})),
		}))
	},

	setShouldHideUI: (value: boolean) => {
		set({ shouldHideUI: value })
	},
}))
