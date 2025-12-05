import React from 'react'
import registerGSAPPlugins from './config/registerGSAPPlugins'
import { RouterProvider } from 'react-router'
import router from './config/dynamicRouter'
import { useAntdMessage } from './hooks/useAntdMessage.tsx'

const App = (): React.ReactNode => {
	registerGSAPPlugins()
	const { contextHolder } = useAntdMessage()

	return (
		<>
			{contextHolder}
			<RouterProvider router={router} />
		</>
	)
}

export default App
