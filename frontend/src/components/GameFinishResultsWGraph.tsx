import {
	LineChart,
	Line,
	XAxis,
	YAxis,
	Tooltip,
	ResponsiveContainer,
} from 'recharts'
import { Popover } from 'antd'
import {
	CharacterState,
	type GameDuration,
	type PlayerStats,
	type WordResultType,
} from '../common/types.ts'
import type { RefObject } from 'react'

interface GameFinishResultsWGraph {
	stats: PlayerStats | null
	wordResults: Record<number, WordResultType[]>
	testType: string
	startTime: number | null
	duration: GameDuration
	resultsRef: RefObject<HTMLDivElement | null>
}

const GameFinishResultsWGraph = ({
	stats,
	wordResults,
	startTime,
	duration,
	resultsRef,
}: GameFinishResultsWGraph) => {
	if (!stats || !startTime) return null

	// Flatten wordResults from Record<number, WordResultType[]> to single array
	const allWords = Object.values(wordResults).flat()

	// Group words by 1-second windows
	const totalSeconds = Math.ceil(stats.timeElapsed)
	const secondBuckets: {
		time: number
		wpm: number
		rawWpm: number
		errors: number
	}[] = []

	for (let second = 0; second <= totalSeconds; second++) {
		const windowStart = startTime + second * 1000
		const windowEnd = startTime + (second + 1) * 1000

		// Get all words in this 1-second window
		const wordsInWindow = allWords.filter(
			w => w.timestamp >= windowStart && w.timestamp < windowEnd
		)

		// Count errors in this window
		const errorsInWindow = wordsInWindow.filter(
			w =>
				w.state === CharacterState.INCORRECT ||
				w.state === CharacterState.OVERFLOW
		).length

		// Calculate WPM up to this point
		const timeElapsedSoFar = second + 1

		// WPM: based on correct characters only
		const correctCharsUpToNow = allWords.filter(
			w => w.timestamp < windowEnd && w.state === CharacterState.CORRECT
		).length
		const wpm =
			timeElapsedSoFar > 0
				? (correctCharsUpToNow / 5 / timeElapsedSoFar) * 60
				: 0

		// Raw WPM: based on all characters (correct + incorrect + overflow + missed)
		const allCharsUpToNow = allWords.filter(w => w.timestamp < windowEnd).length
		const rawWpm =
			timeElapsedSoFar > 0 ? (allCharsUpToNow / 5 / timeElapsedSoFar) * 60 : 0

		secondBuckets.push({
			time: second,
			wpm: Math.round(wpm),
			rawWpm: Math.round(rawWpm),
			errors: errorsInWindow,
		})
	}

	const chartData = secondBuckets

	// Generate ticks for X-axis (1 second intervals)
	const xAxisTicks = Array.from({ length: totalSeconds + 1 }, (_, i) => i)

	// Calculate consistency (standard deviation of WPM)
	const wpmValues = chartData.map(d => d.wpm)
	const avgWpm = wpmValues.reduce((a, b) => a + b, 0) / wpmValues.length
	const variance =
		wpmValues.reduce((sum, wpm) => sum + Math.pow(wpm - avgWpm, 2), 0) /
		wpmValues.length
	const consistency = Math.max(0, 100 - Math.sqrt(variance))

	return (
		<div
			ref={resultsRef}
			className='w-full flex-col max-w-4xl p-6 bg-[#2c2e31] rounded-lg text-white transition duration-200'
		>
			<div className='flex'>
				<div className='flex flex-col gap-8 mb-6'>
					<div>
						<div className='text-xl text-gray-400'>wpm</div>
						<div className='text-5xl font-bold text-accent-primary'>
							{Math.round(stats.wpm)}
						</div>
					</div>
					<div>
						<div className='text-xl text-gray-400'>acc</div>
						<div className='text-5xl font-bold text-accent-primary'>
							{Math.round(stats.accuracy)}%
						</div>
					</div>
				</div>

				{/* Chart */}
				<div className='mb-6 relative w-full'>
					<ResponsiveContainer width='100%' height={200}>
						<LineChart data={chartData}>
							<XAxis
								dataKey='time'
								stroke='#6b7280'
								tick={{ fill: '#6b7280', fontSize: 12 }}
								ticks={xAxisTicks}
								domain={[0, Math.ceil(stats.timeElapsed)]}
							/>
							<YAxis
								yAxisId='left'
								stroke='#6b7280'
								tick={{ fill: '#6b7280', fontSize: 12 }}
								domain={[0, 'auto']}
								label={{
									value: 'wpm',
									angle: -90,
									position: 'insideLeft',
									fill: '#6b7280',
								}}
							/>
							<YAxis
								yAxisId='right'
								orientation='right'
								stroke='#6b7280'
								tick={{ fill: '#6b7280', fontSize: 12 }}
								domain={[0, 'auto']}
								label={{
									value: 'errors',
									angle: 90,
									position: 'insideRight',
									fill: '#6b7280',
								}}
							/>
							<Tooltip
								contentStyle={{
									backgroundColor: '#1f2937',
									border: 'none',
									borderRadius: '4px',
								}}
								labelStyle={{ color: '#9ca3af' }}
							/>
							<Line
								yAxisId='left'
								type='monotone'
								dataKey='rawWpm'
								stroke='#6b7280'
								strokeWidth={2}
								dot={false}
								strokeDasharray='5 5'
							/>
							<Line
								yAxisId='left'
								type='monotone'
								dataKey='wpm'
								stroke='#3b82f6'
								strokeWidth={2}
								dot={false}
							/>
							<Line
								yAxisId='right'
								type='monotone'
								dataKey='errors'
								stroke='#ef4444'
								strokeWidth={2}
								dot={false}
							/>
						</LineChart>
					</ResponsiveContainer>
				</div>
			</div>

			{/* Bottom Stats */}
			<div className='flex justify-between items-center text-sm'>
				<div className='text-gray-400'>
					Timed{' '}
					<strong className='text-accent-primary'>
						{duration !== 0 ? duration : 'Infinite'}
					</strong>
				</div>
				<div className='flex gap-8'>
					<Popover
						content={
							<div className='text-sm text-white'>
								Raw WPM: {stats.rawWpm.toFixed(2)}
							</div>
						}
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>Raw word-per-min</span>}
					>
						<div className='cursor-pointer'>
							<div className='text-gray-400'>raw</div>
							<div className='text-accent-primary text-lg'>
								{Math.round(stats.rawWpm)}
							</div>
						</div>
					</Popover>
					<Popover
						content={
							<div className='text-sm text-white'>
								<div>Correct: {stats.correct}</div>
								<div>Incorrect: {stats.incorrect}</div>
								<div>Overflow: {stats.overflow}</div>
								<div>Missed: {stats.missed}</div>
							</div>
						}
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>Character Breakdown</span>}
					>
						<div className='cursor-pointer'>
							<div className='text-gray-400'>characters</div>
							<div className='text-accent-primary text-lg'>
								{stats.correct}/{stats.incorrect}/{stats.overflow}/
								{stats.missed}
							</div>
						</div>
					</Popover>
					<Popover
						content={
							<div className='text-sm text-white'>
								Measures how stable your typing speed is throughout the test.
								Higher is better.
							</div>
						}
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>Consistency</span>}
					>
						<div className='cursor-pointer'>
							<div className='text-gray-400'>consistency</div>
							<div className='text-accent-primary text-lg'>
								{Math.round(consistency)}%
							</div>
						</div>
					</Popover>
					<Popover
						content={
							<div className='text-sm text-white'>
								Total time taken to complete the test
							</div>
						}
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>Time</span>}
					>
						<div className='cursor-pointer'>
							<div className='text-gray-400'>time</div>
							<div className='text-accent-primary text-lg'>
								{Math.round(stats.timeElapsed)}s
							</div>
						</div>
					</Popover>
				</div>
			</div>
		</div>
	)
}

export default GameFinishResultsWGraph
