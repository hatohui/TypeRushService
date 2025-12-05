import { useEffect, useState } from 'react'
import { CharacterState, type WordResultType } from '../common/types.ts'

interface WordHistoryProps {
	wordResults: Record<number, WordResultType[]>
	words: string[]
	usage: 'history' | 'replay'
	isPlaying?: boolean
}

const WordHistory = ({
	wordResults,
	words,
	usage,
	isPlaying = false,
}: WordHistoryProps) => {
	const [replayProgress, setReplayProgress] = useState<{
		wordIdx: number
		charIdx: number
	}>({ wordIdx: 0, charIdx: -1 })

	useEffect(() => {
		if (usage !== 'replay' || !isPlaying) {
			setReplayProgress({ wordIdx: 0, charIdx: -1 })
			return
		}

		// Flatten all characters with timestamps
		const allChars: Array<{
			wordIdx: number
			charIdx: number
			timestamp: number
		}> = []

		Object.entries(wordResults).forEach(([wordIdxStr, results]) => {
			const wordIdx = parseInt(wordIdxStr)
			results.forEach((result, charIdx) => {
				allChars.push({ wordIdx, charIdx, timestamp: result.timestamp })
			})
		})

		// Sort by timestamp
		allChars.sort((a, b) => a.timestamp - b.timestamp)

		if (allChars.length === 0) return

		const startTime = allChars[0].timestamp
		const timeouts: ReturnType<typeof setTimeout>[] = []

		// Schedule all character reveals
		allChars.forEach(char => {
			const delay = char.timestamp - startTime

			const timeout = setTimeout(() => {
				setReplayProgress({ wordIdx: char.wordIdx, charIdx: char.charIdx })
			}, delay)

			timeouts.push(timeout)
		})

		// Cleanup function
		return () => {
			timeouts.forEach(timeout => clearTimeout(timeout))
		}
	}, [usage, isPlaying, wordResults])

	const getCharStyle = (
		wordIdx: number,
		charIdx: number,
		isVisible: boolean
	) => {
		if (!isVisible) return 'text-gray-500 opacity-30'

		const storedResults = wordResults[wordIdx]
		if (!storedResults || !storedResults[charIdx]) {
			return 'text-gray-500'
		}

		const result = storedResults[charIdx]
		switch (result.state) {
			case CharacterState.CORRECT:
				return 'text-white'
			case CharacterState.INCORRECT:
				return 'text-red-500 underline'
			case CharacterState.OVERFLOW:
				return 'text-red-800 underline'
			case CharacterState.UNTYPED:
				return 'text-gray-500'
			default:
				return 'text-gray-500'
		}
	}

	const isCharVisible = (wordIdx: number, charIdx: number) => {
		if (usage === 'history') return true

		// In replay mode, show chars up to current progress
		if (wordIdx < replayProgress.wordIdx) return true
		if (wordIdx === replayProgress.wordIdx && charIdx <= replayProgress.charIdx)
			return true
		return false
	}

	return (
		<div className='w-full justify-center items-center'>
			<div className='w-full flex-col'>
				<div className='text-sm text-white'>Word {usage}</div>
				<div className='gap-2 text-2xl sm:text-4xl sm:gap-4 flex flex-wrap'>
					{words.map((word, wordIdx) => {
						const results = wordResults[wordIdx]
						return (
							<span key={wordIdx} className='inline-flex'>
								{results
									? results.map((result, charIdx) => {
											const isVisible = isCharVisible(wordIdx, charIdx)
											return (
												<span
													key={charIdx}
													className={`${getCharStyle(wordIdx, charIdx, isVisible)} transition-opacity duration-100`}
													data-word={wordIdx}
													data-char={charIdx}
												>
													{result.typedChar}
												</span>
											)
										})
									: word.split('').map((char, charIdx) => (
											<span
												key={charIdx}
												className='text-gray-500 opacity-30'
												data-word={wordIdx}
												data-char={charIdx}
											>
												{char}
											</span>
										))}
							</span>
						)
					})}
				</div>
			</div>
		</div>
	)
}

export default WordHistory
