import {
	MdOutlineHistory,
	MdOutlineImage,
	MdReplay,
	MdOutlineFastRewind,
} from 'react-icons/md'
import { Tooltip } from 'antd'
import { useState } from 'react'
import WordHistory from './WordHistory'
import type { WordResultType } from '../common/types'

interface ResultsGraphToolbarProps {
	resetGameState: () => void
	wordResults: Record<number, WordResultType[]>
	words: string[]
	handleSaveImage: () => void
}

const ResultsGraphToolbar = ({
	resetGameState,
	wordResults,
	words,
	handleSaveImage,
}: ResultsGraphToolbarProps) => {
	const [showWordHistory, setShowWordHistory] = useState(false)
	const [showWordReplay, setShowWordReplay] = useState(false)

	const handlePreviewIconClick = (icon: 'history' | 'replay') => {
		if (icon === 'history') {
			setShowWordReplay(false)
			setShowWordHistory(!showWordHistory)
		} else {
			setShowWordHistory(false)
			setShowWordReplay(!showWordReplay)
		}
	}

	return (
		<div className='mt-[20px]'>
			{/* Word History Section */}
			<div
				className={`overflow-hidden transition-all duration-500 ease-in-out ${
					showWordHistory || showWordReplay
						? 'max-h-[500px] opacity-100 mb-4'
						: 'max-h-0 opacity-0'
				}`}
			>
				<div className='bg-[#2c2e31] rounded-lg p-6'>
					{showWordHistory && (
						<WordHistory
							wordResults={wordResults}
							words={words}
							usage='history'
						/>
					)}
					{showWordReplay && (
						<>
							<WordHistory
								wordResults={wordResults}
								words={words}
								usage='replay'
								isPlaying={true}
							/>
						</>
					)}
				</div>
			</div>

			{/* Toolbar */}
			<div className='flex max-h-[100px] bg-[#2c2e31] rounded-lg p-4'>
				<div className='flex w-full gap-20 justify-center items-center'>
					<Tooltip
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white mx-auto'>Retry</span>}
					>
						<button className='cursor-pointer' onClick={resetGameState}>
							<MdReplay className='text-gray-400 size-6 hover:text-white transition-colors' />
						</button>
					</Tooltip>
					<Tooltip
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>View word history</span>}
					>
						<button
							className='cursor-pointer'
							onClick={() => {
								handlePreviewIconClick('history')
							}}
						>
							<MdOutlineHistory
								className={`size-6 transition-colors ${
									showWordHistory
										? 'text-blue-400'
										: 'text-gray-400 hover:text-white'
								}`}
							/>
						</button>
					</Tooltip>
					<Tooltip
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>Replay typing</span>}
					>
						<button
							className='cursor-pointer'
							onClick={() => {
								handlePreviewIconClick('replay')
							}}
						>
							<MdOutlineFastRewind
								className={`size-6 transition-colors ${
									showWordReplay
										? 'text-blue-400'
										: 'text-gray-400 hover:text-white'
								}`}
							/>
						</button>
					</Tooltip>
					<Tooltip
						color='#1f2937'
						placement='bottom'
						title={<span className='text-white'>Save result</span>}
					>
						<button className='cursor-pointer' onClick={handleSaveImage}>
							<MdOutlineImage className='text-gray-400 size-6 hover:text-white transition-colors' />
						</button>
					</Tooltip>
				</div>
			</div>
		</div>
	)
}

export default ResultsGraphToolbar
