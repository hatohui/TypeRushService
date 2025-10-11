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

export type GameConfig = {
    words: string[]
    duration: number
}

export type Room = {
    roomId: string
    players: Player[]
    config: GameConfig
    leaderboard: Player[]
}