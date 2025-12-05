import { Card } from 'antd'
import type { WaveRushRoundResultType } from '../common/types.ts'

interface RoundResultCardProps {
	result: WaveRushRoundResultType | null
	roundNumber: number
}

const RoundResultCard = ({ result, roundNumber }: RoundResultCardProps) => {
	if (!result) return null

	return (
		<div className='flex items-center justify-center z-50 pointer-events-none animate-in fade-in duration-300'>
			<Card
				className='shadow-2xl pointer-events-auto'
				style={{
					minWidth: '400px',
					background: 'rgba(17, 24, 39, 0.95)',
					backdropFilter: 'blur(10px)',
					border: '1px solid rgba(59, 130, 246, 0.3)',
				}}
			>
				<div className='text-center space-y-4'>
					<h2 className='text-2xl font-bold text-blue-400'>
						Round {roundNumber} Complete!
					</h2>

					<div className='grid grid-cols-2 gap-4 mt-6'>
						<div className='bg-gray-800 rounded-lg p-4'>
							<div className='text-gray-400 text-sm'>WPM</div>
							<div className='text-3xl font-bold text-white'>{result.wpm}</div>
						</div>

						<div className='bg-gray-800 rounded-lg p-4'>
							<div className='text-gray-400 text-sm'>Accuracy</div>
							<div className='text-3xl font-bold text-green-400'>
								{result.accuracy}%
							</div>
						</div>

						<div className='bg-gray-800 rounded-lg p-4'>
							<div className='text-gray-400 text-sm'>Correct</div>
							<div className='text-xl font-bold text-green-500'>
								{result.correct}
							</div>
						</div>

						<div className='bg-gray-800 rounded-lg p-4'>
							<div className='text-gray-400 text-sm'>Incorrect</div>
							<div className='text-xl font-bold text-red-500'>
								{result.incorrect}
							</div>
						</div>
					</div>

					<div className='text-gray-400 text-sm mt-4'>
						Time: {result.timeElapsed.toFixed(1)}s
					</div>
				</div>
			</Card>
		</div>
	)
}

export default RoundResultCard
