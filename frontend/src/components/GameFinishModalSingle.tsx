import type { PlayerStats } from '../common/types.ts'
import React from 'react'
import { Modal, Card } from 'antd'

interface GameFinishModalPracticeProps {
	onCancel: (isBetweenRounds: boolean) => void
	footer: React.ReactNode
	title: string
	playerStats: PlayerStats | null
	isMultiplayer: boolean
	position?: number | null
}

const GameFinishModalSingle = ({
	onCancel,
	footer,
	title,
	playerStats,
	isMultiplayer,
	position,
}: GameFinishModalPracticeProps) => {
	return (
		<Modal
			open={!!playerStats}
			onCancel={() => onCancel(false)}
			footer={[footer]}
			title={title}
			width={700}
		>
			{playerStats && (
				<div className='space-y-4'>
					{/* Main Stats Cards */}
					<div className='grid grid-cols-2 gap-4'>
						<Card className='bg-gradient-to-br from-blue-50 to-blue-100 border-blue-200'>
							<div className='text-center'>
								<div className='text-gray-600 text-sm mb-1'>WPM</div>
								<div className='text-4xl font-bold text-blue-600'>
									{Math.round(playerStats.wpm)}
								</div>
							</div>
						</Card>
						<Card className='bg-gradient-to-br from-green-50 to-green-100 border-green-200'>
							<div className='text-center'>
								<div className='text-gray-600 text-sm mb-1'>Accuracy</div>
								<div className='text-4xl font-bold text-green-600'>
									{Math.round(playerStats.accuracy)}%
								</div>
							</div>
						</Card>
					</div>

					{/* Secondary Stats */}
					<div className='grid grid-cols-3 gap-3'>
						<Card size='small' className='bg-gray-50'>
							<div className='text-center'>
								<div className='text-gray-500 text-xs mb-1'>Raw WPM</div>
								<div className='text-xl font-semibold text-gray-700'>
									{Math.round(playerStats.rawWpm)}
								</div>
							</div>
						</Card>
						<Card size='small' className='bg-gray-50'>
							<div className='text-center'>
								<div className='text-gray-500 text-xs mb-1'>Time</div>
								<div className='text-xl font-semibold text-gray-700'>
									{Math.round(playerStats.timeElapsed)}s
								</div>
							</div>
						</Card>
						{isMultiplayer && typeof position === 'number' && (
							<Card size='small' className='bg-yellow-50 border-yellow-200'>
								<div className='text-center'>
									<div className='text-gray-500 text-xs mb-1'>Position</div>
									<div className='text-xl font-semibold text-yellow-600'>
										#{position + 1}
									</div>
								</div>
							</Card>
						)}
					</div>

					{/* Character Breakdown */}
					<Card
						title={<span className='text-sm font-medium'>Character Stats</span>}
						size='small'
						className='bg-gray-50'
					>
						<div className='grid grid-cols-4 gap-2 text-center'>
							<div>
								<div className='text-xs text-gray-500 mb-1'>Correct</div>
								<div className='text-lg font-semibold text-green-600'>
									{playerStats.correct}
								</div>
							</div>
							<div>
								<div className='text-xs text-gray-500 mb-1'>Incorrect</div>
								<div className='text-lg font-semibold text-red-600'>
									{playerStats.incorrect}
								</div>
							</div>
							<div>
								<div className='text-xs text-gray-500 mb-1'>Overflow</div>
								<div className='text-lg font-semibold text-orange-600'>
									{playerStats.overflow}
								</div>
							</div>
							<div>
								<div className='text-xs text-gray-500 mb-1'>Missed</div>
								<div className='text-lg font-semibold text-gray-600'>
									{playerStats.missed}
								</div>
							</div>
						</div>
					</Card>
				</div>
			)}
		</Modal>
	)
}

export default GameFinishModalSingle
