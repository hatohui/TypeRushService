import GameDurationSelector from './GameDurationSelector.tsx'
import type { GameDuration } from '../common/types.ts'

interface ModeBarProps {
	selectedDuration: GameDuration
	setSelectedDuration: (selectedDuration: GameDuration) => void
	className: string
}

const Modebar = ({
	selectedDuration,
	setSelectedDuration,
	className,
}: ModeBarProps) => {
	return (
		<div
			className={`${className} bg-background-secondary py-3 px-6 rounded-2xl w-[50%]`}
		>
			<GameDurationSelector
				selectedDuration={selectedDuration}
				setSelectedDuration={setSelectedDuration}
			/>
		</div>
	)
}

export default Modebar
