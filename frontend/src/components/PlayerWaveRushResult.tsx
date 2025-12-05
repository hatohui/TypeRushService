import React from 'react'
import type {
	WaveRushGameResult,
	Player,
	WaveRushRoundResultType,
} from '../common/types'

interface WaveRushResultsProps {
	results: WaveRushGameResult
	players: Player[]
}

const WaveRushResults: React.FC<WaveRushResultsProps> = ({
	results,
	players,
}) => {
	// Get all rounds sorted
	const rounds = Object.keys(results.byRound)
		.map(Number)
		.sort((a, b) => a - b)

	// Helper to get player name or fallback to ID
	const getPlayerName = (playerId: string) => {
		const player = players.find(p => p.id === playerId)
		return player?.playerName || `Player ${playerId.slice(0, 6)}`
	}

	// Helper to format time
	const formatTime = (seconds: number | null) => {
		if (seconds === null) return 'N/A'
		return `${seconds.toFixed(1)}s`
	}

	// Sort players by performance (correct chars desc, then time asc)
	const sortByPerformance = (roundResults: WaveRushRoundResultType[]) => {
		return [...roundResults].sort((a, b) => {
			if (b.correct !== a.correct) {
				return b.correct - a.correct // More correct chars = better
			}
			const timeA = a.timeElapsed
			const timeB = b.timeElapsed
			return timeA - timeB // Less time = better
		})
	}

	return (
		<div className='bg-[#414246] rounded-lg p-6 text-white'>
			<h2 className='text-2xl font-bold mb-6'>Wave Rush Results</h2>

			{rounds.length === 0 ? (
				<p className='text-gray-400'>No results yet</p>
			) : (
				<div className='space-y-6'>
					{rounds.map(round => {
						const roundResults = results.byRound[round] || []
						const sortedResults = sortByPerformance(roundResults)

						return (
							<div key={round} className='border border-gray-600 p-4'>
								<h3 className='text-xl font-semibold mb-4'>
									Round {round + 1}
								</h3>

								{roundResults.length === 0 ? (
									<p className='text-gray-400 text-sm'>No submissions</p>
								) : (
									<div className='overflow-x-auto'>
										<table className='w-full text-sm'>
											<thead>
												<tr className='border-b border-gray-600'>
													<th className='text-left py-2 px-3'>Rank</th>
													<th className='text-left py-2 px-3'>Player</th>
													<th className='text-right py-2 px-3'>WPM</th>
													<th className='text-right py-2 px-3'>Typed</th>
													<th className='text-right py-2 px-3'>Time</th>
												</tr>
											</thead>
											<tbody>
												{sortedResults.map((result, index) => {
													const time = result.timeElapsed

													return (
														<tr
															key={result.playerId}
															className='border-b border-gray-700 hover:bg-gray-700'
														>
															<td className='py-3 px-3'>
																<span
																	className={`font-semibold ${
																		index === 0
																			? 'text-yellow-400'
																			: index === 1
																				? 'text-gray-300'
																				: index === 2
																					? 'text-orange-400'
																					: 'text-gray-400'
																	}`}
																>
																	{index === 0
																		? '🥇'
																		: index === 1
																			? '🥈'
																			: index === 2
																				? '🥉'
																				: `#${index + 1}`}
																</span>
															</td>
															<td className='py-3 px-3 font-medium'>
																{getPlayerName(result.playerId)}
															</td>
															<td className='py-3 px-3 text-right font-semibold text-blue-400'>
																{result.wpm.toFixed(1)}
															</td>
															<td className='py-3 px-3 text-right text-green-400'>
																{result.correct}
															</td>
															<td className='py-3 px-3 text-right text-gray-400'>
																{formatTime(time)}
															</td>
														</tr>
													)
												})}
											</tbody>
										</table>
									</div>
								)}
							</div>
						)
					})}
				</div>
			)}
		</div>
	)
}

export default WaveRushResults
