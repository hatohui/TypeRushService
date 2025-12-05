import React, { useEffect, useState } from 'react'
import Container from '../../components/Container'
import type { LeaderboardData } from '../../common/types'

type LeaderboardType = 'all_time'
type LeaderboardMode = 15 | 30 | 60

const LeaderboardPage: React.FC = () => {
	const [leaderboardData, setLeaderboardData] =
		useState<LeaderboardData | null>(null)
	const [loading, setLoading] = useState(true)
	const [type] = useState<LeaderboardType>('all_time')
	const [mode, setMode] = useState<LeaderboardMode>(15)

	useEffect(() => {
		setLoading(true)

		const allMockData: LeaderboardData = {
			entries: [],
			totalEntries: 0,
		}

		setTimeout(() => {
			// Filter entries by selected mode and sort by WPM (desc) then date (asc)
			const filteredEntries = allMockData.entries
				.filter(entry => entry.mode === mode)
				.sort((a, b) => {
					// Primary sort: WPM descending (higher is better)
					if (b.wpm !== a.wpm) {
						return b.wpm - a.wpm
					}
					// Tiebreaker: Earlier date wins (older date = higher rank)
					return a.recordedAt.getTime() - b.recordedAt.getTime()
				})

			setLeaderboardData({
				entries: filteredEntries,
				totalEntries: filteredEntries.length,
			})
			setLoading(false)
		}, 500)
	}, [type, mode])

	if (loading) {
		return (
			<Container>
				<div className='loading'>Loading leaderboard...</div>
			</Container>
		)
	}

	return (
		<Container>
			<div className='leaderboard'>
				<h1>Leaderboard - All Time</h1>
				<div className='leaderboard-container'>
					<div className='leaderboard-sidebar'>
						<div className='leaderboard-modes'>
							<button
								className={mode === 15 ? 'mode-btn active' : 'mode-btn'}
								onClick={() => setMode(15)}
							>
								15s
							</button>
							<button
								className={mode === 30 ? 'mode-btn active' : 'mode-btn'}
								onClick={() => setMode(30)}
							>
								30s
							</button>
							<button
								className={mode === 60 ? 'mode-btn active' : 'mode-btn'}
								onClick={() => setMode(60)}
							>
								60s
							</button>
						</div>
					</div>
					<div className='leaderboard-content'>
						<div className='leaderboard-entries'>
							{leaderboardData?.entries.map((entry, index) => (
								<div key={entry.user.id} className='leaderboard-entry'>
									<div className='entry-rank'>#{index + 1}</div>
									<div className='entry-name'>{entry.user.playerName}</div>
									<div className='entry-stats'>
										{' '}
										WPM: {entry.wpm} | Raw: {entry.rawWpm} | ACC:{' '}
										{entry.accuracy}% | Date:{' '}
										{entry.recordedAt.toLocaleDateString()}
									</div>
								</div>
							))}
						</div>
					</div>
				</div>
			</div>
		</Container>
	)
}

export default LeaderboardPage
