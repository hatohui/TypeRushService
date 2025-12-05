import React from 'react'
import { Button, Form, type FormProps, InputNumber, Radio } from 'antd'
import { MULTIPLAYER_MODES } from '../common/constant'
import type { FieldType, LobbySettingsFormProps } from '../common/types'
import { useGameStore } from '../stores/useGameStore.ts'

const style: React.CSSProperties = {
	display: 'flex',
	flexDirection: 'column',
	gap: 8,
}

const LobbySettingsForm: React.FC<LobbySettingsFormProps> = ({
	config,
	isHost,
	multiplayerMode,
	onModeChange,
	onSubmit,
}) => {
	const [form] = Form.useForm<FieldType>()
	const { isGameStarted } = useGameStore()

	React.useEffect(() => {
		if (config) {
			form.setFieldsValue({
				mode: config.mode,
				roundDuration:
					config.mode === 'wave-rush' ? config.duration : undefined,
				waves: config.mode === 'wave-rush' ? config.waves : undefined,
				timeBetweenRounds:
					config.mode === 'wave-rush' ? config.timeBetweenRounds : undefined,
			})
			onModeChange(config.mode)
		}
	}, [config, form, onModeChange])

	const MULTIPLAYER_MODE_OPTIONS = MULTIPLAYER_MODES.map(m => ({ ...m }))

	const handleFinish: FormProps<FieldType>['onFinish'] = values => {
		onSubmit(values)
	}

	const initialValues = {
		mode: config.mode,
		roundDuration: config.mode === 'wave-rush' ? config.duration : 10,
		waves: config.mode === 'wave-rush' ? config.waves : 3,
		timeBetweenRounds:
			config.mode === 'wave-rush' ? config.timeBetweenRounds : 3,
	}

	return (
		<Form
			form={form}
			onFinish={handleFinish}
			initialValues={initialValues}
			onValuesChange={changedValues => {
				if (changedValues.mode) {
					onModeChange(changedValues.mode)
				}
			}}
			disabled={!isHost || isGameStarted}
		>
			<Form.Item label='Game mode:' name='mode' required>
				<Radio.Group style={style} options={MULTIPLAYER_MODE_OPTIONS} />
			</Form.Item>
			{multiplayerMode === 'wave-rush' && (
				<>
					<Form.Item label='Round Duration:' name='roundDuration' required>
						<InputNumber min={5} max={15} />
					</Form.Item>
					<Form.Item label='Number of waves:' name='waves' required>
						<InputNumber min={1} max={15} />
					</Form.Item>
					<Form.Item
						label='Time between rounds:'
						name='timeBetweenRounds'
						required
					>
						<InputNumber min={3} max={5} />
					</Form.Item>
				</>
			)}
			{isHost && (
				<Form.Item>
					<Button type='primary' htmlType='submit'>
						Save
					</Button>
				</Form.Item>
			)}
		</Form>
	)
}

export default LobbySettingsForm
