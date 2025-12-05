import { Form, Input, Button, Modal } from 'antd'

interface JoinRoomModalProps {
	open: boolean
	onOk: (values: { playerName: string; roomId?: string }) => void
	confirmLoading: boolean
	error: { type: string; message: string }
}

const JoinRoomModal = ({
	open,
	onOk,
	confirmLoading,
	error,
}: JoinRoomModalProps) => {
	const [form] = Form.useForm()

	const handleFinish = (values: { playerName: string; roomId?: string }) => {
		console.log('Form values:', values)
		onOk(values)
	}

	return (
		<Modal
			open={open}
			title='Join or Create Room'
			footer={null}
			confirmLoading={confirmLoading}
			closable={false}
		>
			<Form
				form={form}
				layout='vertical'
				onFinish={handleFinish}
				initialValues={{ playerName: '', roomId: '' }}
			>
				{/* Player Name */}
				<Form.Item
					label='Enter name'
					name='playerName'
					rules={[
						{ required: true, message: 'Please enter your name' },
						{ min: 2, message: 'Name must be at least 2 characters' },
					]}
				>
					<Input placeholder='Enter player name' />
				</Form.Item>

				{/* Room ID */}
				<Form.Item
					label='Enter room ID'
					name='roomId'
					rules={[
						{
							pattern: /^[A-Za-z0-9]*$/,
							message: 'Room ID can only contain letters and numbers',
						},
					]}
				>
					<Input placeholder='Leave empty to create room' />
				</Form.Item>

				{error.type !== '' && <p>{error.message}</p>}

				{/* Submit Button */}
				<Form.Item>
					<Button
						type='primary'
						htmlType='submit'
						block
						loading={confirmLoading}
					>
						{confirmLoading ? 'Connecting...' : 'OK'}
					</Button>
				</Form.Item>
			</Form>
		</Modal>
	)
}

export default JoinRoomModal
