import { useCallback, useEffect, useRef, useState } from 'react'
import { useGameStore } from '../stores/useGameStore.ts'

const useGameTimer = (
	isMultiplayer: boolean,
	intervalMs: number = 100 // Default 100ms for precise timing
) => {
	const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
	const [startTime, setStartTime] = useState<number | null>(null)
	const [timeElapsed, setTimeElapsed] = useState<number>(0)
	const { isGameStarted } = useGameStore()

	const increment = intervalMs / 1000 // Convert ms to seconds

	useEffect(() => {
		// For practice: wait for startTime to be set (when user types)
		// For multiplayer: wait for isGameStarted
		const shouldStart = isMultiplayer ? isGameStarted : startTime !== null
		if (!shouldStart) return
		timerRef.current = setInterval(() => {
			setTimeElapsed(prev => Number((prev + increment).toFixed(1)))
		}, intervalMs)

		return () => {
			if (timerRef.current) {
				clearInterval(timerRef.current)
				timerRef.current = null
			}
		}
	}, [isGameStarted, isMultiplayer, startTime, intervalMs, increment])

	//stop timer, but keep timeElapsed for UI display
	const stopTimer = useCallback(() => {
		if (timerRef.current) {
			clearInterval(timerRef.current)
			timerRef.current = null
		}
	}, [])

	const startTimer = useCallback(() => {
		if (timerRef.current) return
		timerRef.current = setInterval(() => {
			setTimeElapsed(prev => Number((prev + increment).toFixed(1)))
		}, intervalMs)
	}, [intervalMs, increment])

	//stop timer, reset timeElapsed and startTime, use for new round or new game
	const resetTimer = useCallback(() => {
		stopTimer()
		setTimeElapsed(0)
		setStartTime(null)
	}, [stopTimer])

	return {
		timeElapsed,
		startTime,
		setStartTime,
		resetTimer,
		stopTimer,
		timerRef,
		startTimer,
	}
}

export default useGameTimer
