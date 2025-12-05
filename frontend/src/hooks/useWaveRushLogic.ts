import { useState, useCallback, useEffect, type RefObject } from 'react'
import type {
	PlayerStats,
	WaveRushRoundResultType,
	WordResultType,
} from '../common/types.ts'
import { useGameStore } from '../stores/useGameStore.ts'
import { buildFinalWordResult } from './useTypingLogic.ts'
import type { Socket } from 'socket.io-client'

export const useWaveRushGame = (words: string[][]) => {
	const {
		waveRushGameResult: roundResults,
		playerFinishRound,
		roomId,
	} = useGameStore()
	const currentRound = roundResults.currentRound
	const currentWords =
		words[Math.min(roundResults.currentRound, words.length - 1)]
	const isLastRound = roundResults.currentRound === words.length - 1

	const handleRoundComplete = useCallback(
		(result: WaveRushRoundResultType) => {
			// The `hasSubmittedResult` flag in useWaveRushRound prevents duplicates
			playerFinishRound(roomId, result)
		},
		[playerFinishRound, roomId]
	)

	return {
		roundResults,
		handleRoundComplete,
		isLastRound,
		currentWords,
		currentRound,
	}
}

// Hook for managing a single round's execution in Wave Rush mode
export const useWaveRushRound = ({
	mode,
	waveRushMode,
	words,
	currentWordIdx,
	caretIdx,
	typed,
	wordResults,
	socket,
	calculateStats,
	gameTime,
	gameTimerRef,
	stopGameTimer,
	startTransitionTimer,
	resetTransitionTimer,
	resetGameState,
}: {
	mode: string
	waveRushMode?: {
		roundDuration: number
		onRoundComplete: (result: WaveRushRoundResultType) => void
	}
	words: string[]
	currentWordIdx: number
	caretIdx: number
	typed: string
	wordResults: Record<number, WordResultType[]>
	socket: Socket | null
	calculateStats: (overrideWordResults?: Record<number, WordResultType[]>) => {
		accuracy: number
		wpm: number
		rawWpm: number
		correct: number
		incorrect: number
	}
	gameTime: number
	gameTimerRef: RefObject<ReturnType<typeof setInterval> | null>
	stopGameTimer: () => void
	startTransitionTimer: () => void
	resetTransitionTimer: () => void
	resetGameState: (isBetweenRounds: boolean) => void
}) => {
	const [hasSubmittedResult, setHasSubmittedResult] = useState(false)
	const [isFinishedEarly, setIsFinishedEarly] = useState(false)
	const { isTransitioning } = useGameStore()

	const submitRoundResult = useCallback(
		(completeWordResults?: Record<number, WordResultType[]>) => {
			if (!socket?.id || hasSubmittedResult) return

			const stats = calculateStats(completeWordResults)
			waveRushMode?.onRoundComplete({
				...(stats as PlayerStats),
				playerId: socket.id,
				timeElapsed: gameTime,
			})
			setHasSubmittedResult(true)
		},
		[socket?.id, hasSubmittedResult, calculateStats, waveRushMode, gameTime]
	)

	// Check if finished typing all words early
	useEffect(() => {
		if (
			mode !== 'wave-rush' ||
			!waveRushMode ||
			hasSubmittedResult ||
			!gameTimerRef.current
		)
			return

		const isFinishedTyping =
			currentWordIdx === words.length - 1 &&
			caretIdx === words[currentWordIdx].length - 1

		if (isFinishedTyping) {
			// Build final word result synchronously to include in stats
			const finalWordResult = buildFinalWordResult(words[currentWordIdx], typed)

			// Create complete wordResults with final word
			const completeWordResults = {
				...wordResults,
				[currentWordIdx]: finalWordResult,
			}

			setIsFinishedEarly(true)
			submitRoundResult(completeWordResults)
		}
	}, [
		mode,
		currentWordIdx,
		caretIdx,
		words,
		typed,
		wordResults,
		hasSubmittedResult,
		gameTimerRef,
		submitRoundResult,
		waveRushMode,
	])

	// Check if round time is up
	useEffect(() => {
		if (
			mode !== 'wave-rush' ||
			!waveRushMode ||
			isTransitioning ||
			!gameTimerRef.current
		) {
			return
		}

		if (gameTime >= waveRushMode.roundDuration) {
			// Submit result if not already submitted
			if (!hasSubmittedResult) {
				const finalWordResult = buildFinalWordResult(
					words[currentWordIdx],
					typed
				)

				// Create complete wordResults with final word
				const completeWordResults = {
					...wordResults,
					[currentWordIdx]: finalWordResult,
				}
				submitRoundResult(completeWordResults)
			}
			stopGameTimer()
			setIsFinishedEarly(false)
			//startTransitionTimer()
		}
	}, [
		mode,
		waveRushMode,
		gameTime,
		gameTimerRef,
		hasSubmittedResult,
		submitRoundResult,
		stopGameTimer,
		isTransitioning,
		socket?.id,
		words,
		currentWordIdx,
		typed,
		wordResults,
	])

	useEffect(() => {
		if (!socket) return

		const handleStartTransition = () => {
			startTransitionTimer()
		}

		const handleNextRound = () => {
			resetTransitionTimer()
			resetGameState(true)
			setHasSubmittedResult(false)
		}

		socket.on('startTransition', handleStartTransition)
		socket.on('nextRoundStarted', handleNextRound)

		return () => {
			socket.off('startTransition', handleStartTransition)
			socket.off('nextRoundStarted', handleNextRound)
		}
	}, [socket, startTransitionTimer, resetTransitionTimer, resetGameState])

	return {
		hasSubmittedResult,
		isFinishedEarly,
	}
}
