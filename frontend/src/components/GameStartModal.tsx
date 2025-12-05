import { Modal } from 'antd'
import { useEffect, useState } from 'react'
import { useGameStore } from '../stores/useGameStore.ts'

interface GameStartModalProps {
	duration: number
}

const GameStartModal = ({ duration }: GameStartModalProps) => {
	const [localDuration, setLocalDuration] = useState(duration)
	const { setIsGameStarted, setRenderStartModal } = useGameStore()

	useEffect(() => {
		if (localDuration <= 0) {
			setTimeout(() => {
				setRenderStartModal(false)
				setIsGameStarted(true)
			}, 500)
			return
		}

		const countdown = setInterval(() => {
			setLocalDuration(prev => prev - 1)
		}, 1000)

		return () => clearInterval(countdown)
	}, [localDuration, setIsGameStarted, setRenderStartModal])

	useEffect(() => {
		setLocalDuration(duration)
	}, [duration])

	return (
		<Modal
			open={localDuration > 0}
			footer={null}
			title='Get ready'
			closable={false}
		>
			{localDuration > 0 ? (
				<>
					<div>Game starts in:</div>
					<div className='text-4xl font-bold text-center'>{localDuration}</div>
				</>
			) : (
				<div className='text-4xl font-bold text-center'>Start!!!</div>
			)}
		</Modal>
	)
}

export default GameStartModal
