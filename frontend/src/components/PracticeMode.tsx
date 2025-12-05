import { useState } from 'react'
import type { GameDuration } from '../common/types.ts'
import Modebar from './Modebar.tsx'
import { SAMPLE_WORDS } from '../common/constant.ts'
import PracticeGameContainer from './PracticeGameContainer.tsx'
import { useGameStore } from '../stores/useGameStore.ts'

const PracticeMode = () => {
	const [selectedDuration, setSelectedDuration] = useState<GameDuration>(0)
	const { shouldHideUI } = useGameStore()
	return (
		<div className='w-full h-full flex flex-col justify-center items-center'>
			<Modebar
				selectedDuration={selectedDuration}
				setSelectedDuration={setSelectedDuration}
				className={`${shouldHideUI ? 'opacity-0' : ''} transition duration-200`}
			/>
			<PracticeGameContainer words={SAMPLE_WORDS} duration={selectedDuration} />
		</div>
	)
}

export default PracticeMode
