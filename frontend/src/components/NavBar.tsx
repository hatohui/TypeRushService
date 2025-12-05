import React from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from 'antd'
import { useGameStore } from '../stores/useGameStore.ts'

const NavBar = (): React.ReactElement => {
	const navigate = useNavigate()
	const { shouldHideUI, isGameStarted } = useGameStore()
	const shouldHideUILocal = shouldHideUI || isGameStarted

	return (
		<header
			className={`${!shouldHideUILocal && 'bg-background-secondary'} transition duration-200 px-6 py-4 max-h-[64px] flex justify-between items-center w-full`}
		>
			<h1
				className='text-2xl font-bold text-white cursor-pointer'
				onClick={() => navigate('/')}
			>
				<span className='text-black'>Type</span>
				<span className='text-accent-primary'>Rush</span>
			</h1>

			<div
				className={`flex items-center gap-4 ${shouldHideUILocal && 'opacity-0'}`}
			>
				<nav className='flex gap-3'>
					<Button
						className='bg-background-primary px-3 py-1 rounded cursor-pointer'
						onClick={() => navigate('/gameRoom')}
					>
						multiplayer
					</Button>
					<button className='bg-background-primary px-3 py-1 rounded'>
						settings
					</button>
				</nav>
				<div className='w-5 h-5 rounded-full bg-blue-500' />
			</div>
		</header>
	)
}

export default NavBar
