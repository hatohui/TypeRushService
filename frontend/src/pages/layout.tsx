import React from 'react'
import NavBar from '../components/NavBar'
import Footer from '../components/Footer.tsx'

const MainLayout = ({
	children,
}: {
	children: React.ReactNode
}): React.ReactNode => {
	return (
		<div className='flex flex-col min-h-screen'>
			<NavBar />
			<main className='h-[calc(100vh-64px-54px)]'>{children}</main>
			<Footer />
		</div>
	)
}

export default MainLayout
