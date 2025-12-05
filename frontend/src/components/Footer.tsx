import { useGameStore } from '../stores/useGameStore.ts'

const Footer = () => {
	const { isGameStarted, shouldHideUI } = useGameStore()
	const shouldHideUILocal = isGameStarted || shouldHideUI

	return (
		<footer
			className={`fixed bottom-0 w-full bg-background-secondary py-4 
			text-center ${shouldHideUILocal && 'opacity-0'} transition duration-200`}
		>
			Footer
		</footer>
	)
}

export default Footer
