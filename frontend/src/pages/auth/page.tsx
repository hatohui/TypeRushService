// import { useAuth } from 'react-oidc-context'

// const Page = () => {
// 	const auth = useAuth()

// 	if (auth.isLoading) return <div>Loading...</div>
// 	if (auth.error) return <div>Error: {auth.error.message}</div>

// 	if (auth.isAuthenticated) {
// 		return (
// 			<div>
// 				<div>Logged in as: {auth.user?.profile.email}</div>

// 				<button onClick={() => auth.removeUser()}>Sign out (local)</button>
// 				<button onClick={signOutRedirect}>Sign out (Cognito)</button>
// 			</div>
// 		)
// 	}

// 	return (
// 		<div>
// 			<button onClick={() => auth.signinRedirect()}>Sign in</button>
// 		</div>
// 	)
// }

// export default Page
