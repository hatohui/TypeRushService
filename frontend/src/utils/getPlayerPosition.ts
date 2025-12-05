import type { Player, WaveRushGameResult } from '../common/types.ts'

export function calculateWaveRushScores(
	results: WaveRushGameResult,
	players: Player[]
) {
	// Map playerId → playerName
	const nameMap = Object.fromEntries(players.map(p => [p.id, p.playerName]))

	// Accumulate scores
	const totalScore: Record<string, number> = {}

	// Iterate through each round
	for (const roundIndex in results.byRound) {
		const round = results.byRound[roundIndex]

		// Sort by WPM descending (1st place first)
		const sorted = [...round].sort((a, b) => b.wpm - a.wpm)

		const numberOfPlayers = sorted.length

		sorted.forEach((entry, index) => {
			const score = numberOfPlayers - index

			totalScore[entry.playerId] = (totalScore[entry.playerId] ?? 0) + score
		})
	}

	// Convert to array and attach player names
	const resultArray = Object.entries(totalScore).map(([playerId, score]) => ({
		playerId,
		playerName: nameMap[playerId] ?? '(Unknown Player)',
		score,
	}))

	// Sort by score to assign rank
	resultArray.sort((a, b) => b.score - a.score)

	// Add rank
	return resultArray.map((item, index) => ({
		...item,
		rank: index + 1,
	}))
}
