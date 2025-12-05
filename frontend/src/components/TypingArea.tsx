import React, { useEffect, useRef } from 'react'

interface TypingAreaProps {
	localWords: string[]
	currentWord: string | null
	typed: string
	onKeyDown: (e: React.KeyboardEvent<HTMLInputElement>) => void
	getCharStyle: (wordIdx: number, charIdx: number, char: string) => string
	isRoundComplete?: boolean
}

const TypingArea = ({
	localWords,
	currentWord,
	typed,
	onKeyDown,
	getCharStyle,
	isRoundComplete,
}: TypingAreaProps) => {
	const inputRef = useRef<HTMLInputElement>(null)

	useEffect(() => {
		if (!isRoundComplete) {
			setTimeout(() => inputRef.current?.focus(), 0)
		}
	}, [isRoundComplete, currentWord])

	return (
		<div className='w-full gap-2 text-2xl sm:text-4xl sm:gap-4 flex justify-center items-center'>
			{localWords?.map((word, wordIdx) => (
				<span key={wordIdx}>
					{word === currentWord && (
						<input
							className='text-3xl opacity-0 absolute flex focus:outline-none focus:ring-0 focus:border-transparent'
							autoFocus
							ref={inputRef}
							type='text'
							value={typed}
							onKeyDown={e => {
								onKeyDown(e)
							}}
							disabled={isRoundComplete} //prevent input on round complete in Wave Rush mode
						/>
					)}
					{word?.split('').map((char, charIdx) => {
						const state = getCharStyle(wordIdx, charIdx, char)
						return (
							<span
								key={charIdx}
								className={state}
								data-word={wordIdx}
								data-char={charIdx}
							>
								{char}
							</span>
						)
					})}
				</span>
			))}
		</div>
	)
}

export default TypingArea
