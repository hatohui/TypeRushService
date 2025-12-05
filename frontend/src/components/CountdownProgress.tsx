import { Progress } from 'antd'

const CountdownProgress = ({
	duration,
	timeElapsed,
	isTransition = false,
}: {
	duration: number
	timeElapsed: number
	isTransition?: boolean
}) => {
	const remainingTime = Math.max(0, duration - timeElapsed)

	// Display whole seconds (rounded)
	const displaySeconds = Math.round(remainingTime)
	const displayTime = `${displaySeconds}s`

	// When display shows 0s, force progress bar to 0%
	const percent =
		displaySeconds === 0
			? 0
			: duration > 0
				? (remainingTime / duration) * 100
				: 0

	const showGetReady = isTransition && displaySeconds === 0

	return (
		<div
			className='transition-opacity duration-500'
			style={{ opacity: displaySeconds === 0 ? 0.3 : 1 }}
		>
			<Progress
				percent={percent}
				format={() => (
					<span
						className={`font-bold text-lg ${showGetReady ? 'text-green-500 animate-pulse' : 'text-accent-primary'}`}
					>
						{showGetReady ? 'Get Ready!' : displayTime}
					</span>
				)}
				status={displaySeconds === 0 ? 'exception' : 'active'}
				strokeLinecap='round'
			/>
		</div>
	)
}

export default CountdownProgress
