import { useAuth } from 'react-oidc-context'

export const UserDropdown = () => {
	const auth = useAuth()

	const handleSignOut = async () => {
		try {
			await auth.removeUser()
			const domain = 'https://18texzarnh.auth.ap-southeast-1.amazoncognito.com'
			const clientId = '1pvvkk651p59c7m72kemg5vif6'
			const logoutUri = encodeURIComponent('http://localhost:5173/')

			window.location.href = `${domain}/logout?client_id=${clientId}&logout_uri=${logoutUri}`
		} catch (error) {
			console.error('Logout error:', error)
		}
	}

	return (
		<div>
			<div onClick={handleSignOut}>SignOut</div>
		</div>
	)
}
