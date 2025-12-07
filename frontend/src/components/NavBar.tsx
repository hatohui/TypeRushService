import React from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from 'antd'
import { useGameStore } from '../stores/useGameStore.ts'
import { useAuth } from 'react-oidc-context'
import { UserDropdown } from './UserDropdown.tsx'

const NavBar = (): React.ReactElement => {
	const navigate = useNavigate()
	const { shouldHideUI, isGameStarted } = useGameStore()
	const shouldHideUILocal = shouldHideUI || isGameStarted
	const auth = useAuth()
	const goToCognito = () => {
		auth.signinRedirect()
	}

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
						Multiplayer
					</Button>

					<button className='bg-background-primary px-3 py-1 rounded'>
						Settings
					</button>

					{auth.isAuthenticated && auth.user?.profile ? (
						<div className='group relative bg-background-primary px-3 py-1 rounded cursor-pointer'>
							{auth.user.profile.name}
							<div className='absolute opacity-0 group-hover:opacity-100 duration-200'>
								<UserDropdown></UserDropdown>
							</div>
						</div>
					) : (
						<button
							className='bg-background-primary px-3 py-1 rounded cursor-pointer'
							onClick={goToCognito}
						>
							Sign in
						</button>
					)}
				</nav>

				<div className='w-5 h-5 rounded-full bg-blue-500' />
			</div>
		</header>
	)
}

export default NavBar
