import { useState, useEffect } from 'react'

interface TypingAnimationProps {
	text: string
	speed?: number
	className?: string
	colorSplit?: number
	primaryColor?: string
	accentColor?: string
}

const TypingAnimation = ({
	text,
	speed = 150,
	className = '',
	colorSplit,
	primaryColor = 'text-black',
	accentColor = 'text-blue-400',
}: TypingAnimationProps) => {
	const [displayedText, setDisplayedText] = useState('')
	const [currentIndex, setCurrentIndex] = useState(0)

	useEffect(() => {
		if (currentIndex < text.length) {
			const timeout = setTimeout(() => {
				setDisplayedText(prev => prev + text[currentIndex])
				setCurrentIndex(prev => prev + 1)
			}, speed)

			return () => clearTimeout(timeout)
		}
	}, [currentIndex, text, speed])

	if (colorSplit === undefined) {
		return (
			<span className={className}>
				{displayedText}
				<span className='animate-blink'>|</span>
			</span>
		)
	}

	const firstPart = displayedText.slice(0, colorSplit)
	const secondPart = displayedText.slice(colorSplit)

	return (
		<span className={`${className}`}>
			<span className={primaryColor}>{firstPart}</span>
			<span className={accentColor}>{secondPart}</span>
			<span className={`animate-blink ${accentColor}`}>|</span>
		</span>
	)
}

export default TypingAnimation
