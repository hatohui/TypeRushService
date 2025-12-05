import { type GameDuration } from '../common/types.ts'
import { GAME_DURATION } from '../common/constant.ts'

interface GameDurationSelectorProps {
	selectedDuration: GameDuration
	setSelectedDuration: (selectedDuration: GameDuration) => void
}

const GameDurationSelector = ({
	selectedDuration,
	setSelectedDuration,
}: GameDurationSelectorProps) => {
	return (
		<div>
			{GAME_DURATION &&
				GAME_DURATION.map((duration, idx) => {
					return (
						<span
							onClick={() => {
								setSelectedDuration(duration)
							}}
							key={idx}
							className={`${duration === selectedDuration ? 'font-bold text-accent-primary' : 'text-gray-400'} mr-2 cursor-pointer`}
						>
							{duration === 0 ? 'No time' : duration}
						</span>
					)
				})}
		</div>
	)
}

export default GameDurationSelector
