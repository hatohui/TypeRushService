import { Card, Modal } from 'antd'
import { useGameStore } from '../stores/useGameStore.ts'
import { PlayerColor } from '../common/types.ts'
import WaveRushResults from './PlayerWaveRushResult.tsx'

interface GameFinishModalProps {
	displayFinishModal: boolean
	setDisplayFinishModal: (displayFinishModal: boolean) => void
}

const GameFinishModalMultiplayer = ({
	displayFinishModal,
	setDisplayFinishModal,
}: GameFinishModalProps) => {
	const { typeRaceGameResult, waveRushGameResult, players } = useGameStore()
	let positionColor = PlayerColor.GRAY

	const getPositionStyle = (position: number) => {
		switch (position) {
			case 0:
				positionColor = 'text-amber-300'
				break
			case 1:
				positionColor = 'text-gray-300'
				break
			case 2:
				positionColor = 'text-green-300'
				break
			case 3:
				positionColor = 'text-red-300'
				break
			default:
				positionColor = 'text-gray-300'
				break
		}

		return `text-3xl font-bold ${positionColor}`
	}

	return (
		<Modal
			open={displayFinishModal}
			onCancel={() => setDisplayFinishModal(false)}
			title='Results'
			footer={null}
		>
			{typeRaceGameResult && typeRaceGameResult.length > 0 ? (
				typeRaceGameResult.map((entry, idx) => {
					const player = players.find(player => player.id === entry.playerId)
					return (
						<Card key={entry.playerId} className='mb-4'>
							<div className='flex items-center justify-between'>
								<div className='flex items-center gap-4'>
									<span className={getPositionStyle(idx)}>#{idx + 1}</span>
									<div>
										<div className='font-semibold text-lg'>
											{player?.playerName}
										</div>
										<div className='text-gray-500 text-sm'>
											Accuracy: {entry.stats.accuracy.toFixed(1)}% | WPM:{' '}
											{Math.round(entry.stats.wpm)}
										</div>
									</div>
								</div>
								<div className='text-right'>
									<div className='text-sm text-gray-500'>
										Raw WPM: {Math.round(entry.stats.rawWpm)}
									</div>
									<div className='text-xs text-gray-400'>
										Time elapsed: {entry.stats.timeElapsed} s
									</div>
								</div>
							</div>
						</Card>
					)
				})
			) : (
				<WaveRushResults results={waveRushGameResult} players={players} />
			)}
		</Modal>
	)
}

export default GameFinishModalMultiplayer
