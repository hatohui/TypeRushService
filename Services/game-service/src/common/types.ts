
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
}

export const MULTIPLAYER_MODES = ['type-race', 'wave-rush'] as const

export type MultiplayerMode = typeof MULTIPLAYER_MODES[number]

export type GameConfig =
    | {
    words: string[]
    mode: 'type-race'
}
    | {
    words: string[]
    mode: 'wave-rush'
    duration: number
}

export interface PlayerStats {
    accuracy: number
    wpm: number
    rawWpm: number
    correct: number
    incorrect: number
}

export interface RoomLeaderboardEntry {
    playerId: string
    stats: PlayerStats
}

export type Room = {
    roomId: string
    players: Player[]
    config: GameConfig
    leaderboard: RoomLeaderboardEntry[]
}