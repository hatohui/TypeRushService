import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './global.css'
import { AuthProvider } from 'react-oidc-context'
import { cognitoAuthConfig } from './config/cognitoAuthConfig'

createRoot(document.getElementById('root')!).render(
	<StrictMode>
		<AuthProvider {...cognitoAuthConfig}>
			<App />
		</AuthProvider>
	</StrictMode>
)
