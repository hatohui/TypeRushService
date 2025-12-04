
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

export const MULTIPLAYER_MODES = ['type-race', 'wave-rush'] as const

export type MultiplayerMode = typeof MULTIPLAYER_MODES[number]

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
    transitionTimer: NodeJS.Timeout | null
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