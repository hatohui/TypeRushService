import { useCallback } from 'react'
import { CharacterState, type WordResultType } from '../common/types.ts'

const useTypingStats = (
	wordResults: Record<number, WordResultType[]>,
	timeElapsed: number
) => {
	const calculateStats = useCallback(
		(overrideWordResults?: Record<number, WordResultType[]>) => {
			let correct = 0
			let incorrect = 0
			let overflow = 0
			let missed = 0

			const resultsToUse = overrideWordResults ?? wordResults

			Object.values(resultsToUse).forEach(results => {
				results.forEach(r => {
					if (r.state === CharacterState.CORRECT) correct++
					if (r.state === CharacterState.INCORRECT) incorrect++
					if (r.state === CharacterState.UNTYPED) missed++
					if (r.state === CharacterState.OVERFLOW) overflow++
				})
			})

			// Total characters actually typed (including mistakes and overflow)
			const totalTyped = correct + incorrect + overflow

			// Accuracy: correct chars / all chars typed (excluding missed)
			const accuracy = totalTyped > 0 ? (correct / totalTyped) * 100 : 0

			const timeInMinutes = timeElapsed / 60

			// WPM: only correct characters count toward speed
			const wpm = timeInMinutes > 0 ? correct / 5 / timeInMinutes : 0

			// Raw WPM: all typed characters (correct + incorrect + overflow)
			const rawWpm = timeInMinutes > 0 ? totalTyped / 5 / timeInMinutes : 0

			return {
				accuracy,
				wpm,
				rawWpm,
				correct,
				incorrect,
				overflow,
				missed,
				timeElapsed,
			}
		},
		[wordResults, timeElapsed]
	)

	return { calculateStats }
}

export default useTypingStats
