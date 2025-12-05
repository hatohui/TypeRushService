import React, { useEffect, useRef } from 'react'
import { useGameStore } from '../stores/useGameStore.ts'
import { calculateWaveRushScores } from '../utils/getPlayerPosition.ts'
import gsap from 'gsap'
import { Flip } from 'gsap/Flip'

gsap.registerPlugin(Flip)

export interface Results {
	playerId: string
	playerName: string
	score: number
	rank: number
}

const PlayerPositions = () => {
	const { waveRushGameResult, players } = useGameStore()
	const containerRef = useRef<HTMLDivElement>(null)
	const prevOrderRef = useRef<string>('')
	const stateRef = useRef<Flip.FlipState>(null)

	const processedResults = React.useMemo(() => {
		if (
			!waveRushGameResult ||
			Object.keys(waveRushGameResult.byRound).length === 0
		)
			return []
		return calculateWaveRushScores(waveRushGameResult, players)
	}, [waveRushGameResult, players])

	useEffect(() => {
		if (!containerRef.current || processedResults.length === 0) return

		const currentOrder = processedResults.map(r => r.playerId).join(',')

		// Only animate if order actually changed
		if (
			prevOrderRef.current !== '' &&
			prevOrderRef.current !== currentOrder &&
			stateRef.current
		) {
			Flip.from(stateRef.current, {
				duration: 0.6,
				ease: 'power2.inOut',
				absolute: true,
			})
		}

		// Capture state for next change
		stateRef.current = Flip.getState(containerRef.current.children)
		prevOrderRef.current = currentOrder
	}, [processedResults])

	return (
		<div className='bg-[#414246] rounded-lg p-4 w-64'>
			<h3 className='text-sm font-semibold mb-4 text-gray-300'>Leaderboard</h3>
			<div ref={containerRef} className='flex flex-col gap-3'>
				{processedResults.map(result => (
					<div
						key={result.playerId}
						data-flip-id={result.playerId}
						className='flex items-center gap-3 bg-[#383A3E] rounded-lg p-3 transition-all hover:bg-[#4A4C50]'
					>
						<div className='flex items-center gap-3 flex-1'>
							<span className='text-lg font-bold text-gray-400 w-6'>
								#{result.rank}
							</span>
							<div className='w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center text-white font-semibold'>
								{result.playerName.charAt(0).toUpperCase()}
							</div>
							<span className='text-white font-medium flex-1'>
								{result.playerName}
							</span>
						</div>
						<span className='text-accent-primary font-bold text-lg'>
							{result.score}
						</span>
					</div>
				))}
			</div>
		</div>
	)
}

export default PlayerPositions
