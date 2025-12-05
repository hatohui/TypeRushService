import { message } from 'antd'

export const useAntdMessage = () => {
	const [api, contextHolder] = message.useMessage()

	const showMessage = (status: 'success' | 'error', content: string) => {
		switch (status) {
			case 'success':
				api.open({
					type: 'success',
					content: `${content}`,
				})
				break
			case 'error':
				api.open({
					type: 'error',
					content: `${content}`,
				})
		}
	}

	return {
		showMessage,
		contextHolder,
	}
}
