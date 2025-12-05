import React, { forwardRef } from 'react'

interface CaretProps {
	isOpponent?: boolean
	playerName?: string
	color?: string
	className?: string
	isDisconnected?: boolean
	mistakeAnimCaretRef?: React.RefObject<HTMLSpanElement | null>
}

const Caret = forwardRef<HTMLSpanElement, CaretProps>(
	(
		{
			isOpponent = false,
			playerName = 'Player',
			color = '#3b82f6',
			className = '',
			isDisconnected = false,
			mistakeAnimCaretRef,
		},
		ref
	) => {
		return (
			<span className={`relative inline-block ${className} h-[1em]`} ref={ref}>
				<span
					className='inline-block w-[1.5px] animate-pulse align-text-bottom'
					style={{
						backgroundColor: isDisconnected ? 'gray' : color,
						height: '1em',
						marginLeft: '-1px',
						opacity: isDisconnected ? 0.3 : 1,
					}}
					ref={mistakeAnimCaretRef}
				/>

				{isOpponent && (
					<span
						className='absolute -top-4 left-0 text-xs px-2 py-1 rounded whitespace-nowrap shadow-sm'
						style={{
							backgroundColor: isDisconnected ? 'gray' : color,
							color: 'white',
							fontSize: '10px',
							transform: 'translateX(-50%)',
							opacity: isDisconnected ? 0.3 : 1,
						}}
					>
						{playerName}
					</span>
				)}
			</span>
		)
	}
)

Caret.displayName = 'Caret'

export default Caret
