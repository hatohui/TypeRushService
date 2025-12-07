import { WebStorageStateStore } from 'oidc-client-ts'
import type { AuthProviderProps } from 'react-oidc-context'

export const cognitoAuthConfig: AuthProviderProps = {
	authority:
		'https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_8TexzArNh',
	client_id: '1pvvkk651p59c7m72kemg5vif6',
	redirect_uri: 'http://localhost:5173/',
	post_logout_redirect_uri: 'http://localhost:5173/',
	response_type: 'code',
	scope: 'openid profile email',
	loadUserInfo: true,
	userStore: new WebStorageStateStore({ store: window.localStorage }),
}
