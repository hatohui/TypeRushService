import React, { useCallback, useRef, useState } from 'react'
import {
	BlockedKeysSet,
	CharacterState,
	type CharacterStateType,
	InputKey,
	type WordResultType,
} from '../common/types.ts'
import { MAX_OVERFLOW } from '../common/constant.ts'

// Utility function to build final word result for stats calculation (multiplayer mode)
export const buildFinalWordResult = (
	word: string,
	typed: string
): WordResultType[] => {
	return word.split('').map((char, idx) => {
		return {
			char: char,
			typedChar: char[idx] ?? '',
			state:
				typed[idx] === char ? CharacterState.CORRECT : CharacterState.INCORRECT,
			timestamp: Date.now(),
		}
	})
}

// Utility function to build word result with character-by-character evaluation
// Handles untyped characters and overflow
export const buildWordResult = (
	word: string,
	typed: string,
	timestamps: number[]
): WordResultType[] => {
	const currentResults = word.split('').map((char, idx) => {
		let charStatus: CharacterStateType

		if (idx < typed.length) {
			charStatus =
				typed[idx] === char ? CharacterState.CORRECT : CharacterState.INCORRECT
		} else {
			charStatus = CharacterState.UNTYPED
		}

		return {
			char: char,
			typedChar: typed[idx],
			state: charStatus,
			timestamp: timestamps[idx] || Date.now(),
		} as WordResultType
	})

	// Handle overflow characters
	if (typed.length > word.length) {
		const overflowCount = typed.length - word.length
		for (let i = 0; i < overflowCount; i++) {
			const idx = word.length + i
			currentResults.push({
				char: typed[idx],
				typedChar: typed[idx],
				state: CharacterState.OVERFLOW,
				timestamp: timestamps[idx] || Date.now(),
			})
		}
	}

	return currentResults
}

const useTypingLogic = (
	words: string[],
	animationRef?: React.RefObject<(() => void) | null>
) => {
	const [localWords, setLocalWords] = useState<string[]>(words)
	const [currentWordIdx, setCurrentWordIdx] = useState(0)
	const [currentWord, setCurrentWord] = useState<string | null>(
		localWords[currentWordIdx]
	)
	const [typed, setTyped] = useState<string>('')
	const [caretIdx, setCaretIdx] = useState(-1)
	const [wordResults, setWordResults] = useState<
		Record<number, WordResultType[]>
	>({})
	// Track timestamps for each character as they're typed (using ref to avoid re-renders)
	const charTimestampsRef = useRef<number[]>([])

	const handleSpacePress = (isFinish: boolean) => {
		if (typed.trim() === '') return

		const currentResults = buildWordResult(
			words[currentWordIdx],
			typed,
			charTimestampsRef.current
		)

		setWordResults(prev => ({
			...prev,
			[currentWordIdx]: currentResults,
		}))

		if (!isFinish) {
			setCaretIdx(-1)
			setCurrentWordIdx(prev => {
				const nextIdx = prev + 1
				setCurrentWord(localWords[nextIdx] ?? null)
				return nextIdx
			})
			setTyped('')
			charTimestampsRef.current = []
		}
	}

	const resetTypingState = useCallback(() => {
		setCurrentWordIdx(0)
		setTyped('')
		setCurrentWord(words[0] ?? null)
		setWordResults({})
		setCaretIdx(-1)
		setLocalWords(words)
		charTimestampsRef.current = []
	}, [words])

	const getCharStyle = (wordIdx: number, idx: number, char: string) => {
		let state = ''
		if (wordIdx < currentWordIdx) {
			const storedResults = wordResults[wordIdx]
			if (storedResults && storedResults[idx]) {
				state =
					storedResults[idx].state === CharacterState.CORRECT
						? 'text-white'
						: storedResults[idx].state === CharacterState.INCORRECT
							? 'text-red-500 underline'
							: 'text-red-800 underline'
			}
		} else if (wordIdx === currentWordIdx) {
			if (idx >= words[currentWordIdx].length) {
				state = 'text-red-800'
			} else if (idx < typed.length) {
				state = typed[idx] === char ? 'text-white' : 'text-red-500'
			}
		}
		return state
	}

	const isBlockedKey = (e: React.KeyboardEvent<HTMLInputElement>) => {
		return BlockedKeysSet.has(e.key)
	}

	const onKeyDownPracticeMode = (
		e: React.KeyboardEvent<HTMLInputElement>,
		startTime: number | null,
		setStartTime: (value: React.SetStateAction<number | null>) => void
	) => {
		{
			if (isBlockedKey(e)) {
				e.preventDefault()
				return
			}

			if (
				typed.length >= words[currentWordIdx].length + MAX_OVERFLOW &&
				e.key !== InputKey.BACKSPACE
			)
				return

			if (e.key === InputKey.SPACE) {
				e.preventDefault()
				handleSpacePress(false)
				return
			}

			if (e.key === InputKey.BACKSPACE) {
				if (typed.length > 0) {
					const newLength = typed.length - 1
					setCaretIdx(prev => Math.max(-1, prev - 1))
					setTyped(prev => prev.slice(0, -1))
					charTimestampsRef.current = charTimestampsRef.current.slice(0, -1)

					if (newLength >= words[currentWordIdx].length) {
						const newWord = localWords[currentWordIdx].slice(0, newLength)
						setLocalWords(prev => {
							const newLocalWords = [...prev]
							newLocalWords[currentWordIdx] = newWord
							return newLocalWords
						})
						setCurrentWord(newWord)
						setTyped(newWord)
					}
				}
				return
			}

			if (typed.length >= words[currentWordIdx].length) {
				const newWord = localWords[currentWordIdx] + e.key
				setLocalWords(prev => {
					const newLocalWords = [...prev]
					newLocalWords[currentWordIdx] = newWord
					return newLocalWords
				})
				setCurrentWord(newWord)
			}

			setCaretIdx(prev => prev + 1)
			setTyped(prev => prev + e.key)
			charTimestampsRef.current.push(Date.now())

			if (!startTime) setStartTime(Date.now())
		}
	}

	const onKeyDownMultiplayer = (e: React.KeyboardEvent<HTMLInputElement>) => {
		if (isBlockedKey(e)) {
			e.preventDefault()
			return
		}

		if (e.key === InputKey.SPACE) {
			if (caretIdx + 1 >= words[currentWordIdx].length) {
				handleSpacePress(false)
			}
			e.preventDefault()
			return
		}

		if (e.key === InputKey.BACKSPACE) {
			if (typed.length > 0) {
				setCaretIdx(prev => Math.max(-1, prev - 1))
				setTyped(prev => prev.slice(0, -1))
				charTimestampsRef.current = charTimestampsRef.current.slice(0, -1)
			}
			return
		}

		const nextChar = words[currentWordIdx]?.[caretIdx + 1]
		if (nextChar && nextChar === e.key) {
			setCaretIdx(prev => prev + 1)
			setTyped(prev => prev + e.key)
			charTimestampsRef.current.push(Date.now())
		} else {
			animationRef?.current?.()
			e.preventDefault()
		}
	}

	return {
		currentWordIdx,
		currentWord,
		typed,
		caretIdx,
		wordResults,
		localWords,
		setLocalWords,
		handleSpacePress,
		resetTypingState,
		setCurrentWord,
		setCaretIdx,
		setWordResults,
		setTyped,
		setCurrentWordIdx,
		onKeyDownPracticeMode,
		getCharStyle,
		onKeyDownMultiplayer,
		isBlockedKey,
		charTimestampsRef,
	}
}

export default useTypingLogic
