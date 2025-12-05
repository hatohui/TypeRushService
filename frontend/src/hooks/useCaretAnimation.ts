import { useEffect, useRef } from 'react'
import { Flip } from 'gsap/Flip'
import { gsap } from 'gsap'
import type { Socket } from 'socket.io-client'
import type { Player } from '../common/types.ts'

interface UseCaretAnimationProps {
	caretIdx: number
	currentWordIdx: number
	isMultiplayer: boolean
	socket: Socket | null
	players: Player[] | null
}

const useCaretAnimation = ({
	caretIdx,
	currentWordIdx,
	isMultiplayer,
	socket = null,
	players = null,
}: UseCaretAnimationProps) => {
	const containerRef = useRef<HTMLDivElement>(null)
	const caretRef = useRef<HTMLSpanElement | null>(null)
	const caretRefs = useRef<(HTMLSpanElement | null)[]>([])
	const shakeAnim = useRef<gsap.core.Timeline>(null)
	const mistakeAnimCaretRef = useRef<HTMLSpanElement | null>(null)

	// Animate self caret
	useEffect(() => {
		const caretElement = isMultiplayer ? caretRefs.current[3] : caretRef.current
		if (!caretElement) return

		let target: HTMLElement | null = null
		if (caretIdx === -1) {
			target = containerRef.current?.querySelector(
				`[data-word="${currentWordIdx}"][data-char="0"]`
			) as HTMLElement | null

			if (target) {
				const state = Flip.getState(caretElement)
				target.parentNode?.insertBefore(caretElement, target)
				Flip.from(state, {
					duration: 0.15,
					ease: 'none',
				})
			}
			return
		}

		target = containerRef.current?.querySelector(
			`[data-word="${currentWordIdx}"][data-char="${caretIdx}"]`
		) as HTMLElement | null

		if (!target) return

		const state = Flip.getState(caretElement)
		target.appendChild(caretElement)
		Flip.from(state, {
			duration: 0.15,
			ease: 'none',
		})
	}, [currentWordIdx, caretIdx, isMultiplayer])

	// Initial practice mode caret positioning
	useEffect(() => {
		if (!containerRef.current || isMultiplayer) return

		requestAnimationFrame(() => {
			const caretElement = caretRef.current
			if (caretElement) {
				const target = containerRef.current?.querySelector(
					`[data-word="0"][data-char="0"]`
				) as HTMLElement | null

				if (target) {
					target.parentNode?.insertBefore(caretElement, target)
				}
			}
		})
	}, [isMultiplayer])

	//MULTIPLAYER
	// Initialize caret refs
	useEffect(() => {
		if (!isMultiplayer) return
		caretRefs.current = Array.from({ length: 4 }, () => null)
	}, [isMultiplayer])

	// Mistake animation setup
	useEffect(() => {
		if (!isMultiplayer) return

		const caretElement = mistakeAnimCaretRef.current

		if (!caretElement) {
			return
		}

		shakeAnim.current?.kill()

		shakeAnim.current = gsap
			.timeline({ paused: true })
			.to(caretElement, {
				x: -4,
				backgroundColor: 'red',
				duration: 0.08,
				ease: 'power2.out',
			})
			.to(caretElement, {
				x: 4,
				duration: 0.08,
				ease: 'power2.inOut',
			})
			.to(caretElement, {
				x: -3,
				duration: 0.08,
				ease: 'power2.inOut',
			})
			.to(caretElement, {
				x: 3,
				duration: 0.08,
				ease: 'power2.inOut',
			})
			.to(caretElement, {
				x: 0,
				backgroundColor: '#3b82f6',
				duration: 0.15,
				ease: 'power2.out',
			})

		return () => {
			shakeAnim.current?.kill()
		}
	}, [isMultiplayer, caretRefs.current[3]])

	const triggerMistakeAnimation = () => {
		shakeAnim.current?.restart()
	}

	// Animate opponent carets
	useEffect(() => {
		if (!isMultiplayer || !socket || !players) return

		const otherPlayers = players.filter(p => p.id !== socket.id)

		otherPlayers.forEach((player, playerIndex) => {
			const caretElement = caretRefs.current[playerIndex]
			if (!caretElement) return

			const caret = player.progress?.caret
			if (!caret) return

			const { caretIdx: playerCaretIdx, wordIdx: playerWordIdx } = caret
			let target: HTMLElement | null = null

			if (playerCaretIdx === -1) {
				target = containerRef.current?.querySelector(
					`[data-word="${playerWordIdx}"][data-char="0"]`
				) as HTMLElement | null

				if (target) {
					const state = Flip.getState(caretElement)
					target.parentNode?.insertBefore(caretElement, target)
					Flip.from(state, {
						duration: 0.3,
						ease: 'power1.inOut',
					})
				}
				return
			}

			target = containerRef.current?.querySelector(
				`[data-word="${playerWordIdx}"][data-char="${playerCaretIdx}"]`
			) as HTMLElement | null

			if (!target) return

			const state = Flip.getState(caretElement)
			target.appendChild(caretElement)
			Flip.from(state, {
				duration: 0.3,
				ease: 'power1.inOut',
			})
		})
	}, [isMultiplayer, players, socket])

	// Initial caret positioning for all players
	useEffect(() => {
		if (!containerRef.current || !isMultiplayer || !socket || !players) return

		requestAnimationFrame(() => {
			// Position own caret
			const ownCaretElement = caretRefs.current[3]
			if (ownCaretElement) {
				const target = containerRef.current?.querySelector(
					`[data-word="0"][data-char="0"]`
				) as HTMLElement | null

				if (target) {
					target.parentNode?.insertBefore(ownCaretElement, target)
				}
			}

			// Position other players' carets
			if (!socket) return
			const otherPlayers = players.filter(p => p.id !== socket.id)

			otherPlayers.forEach((_player, playerIndex) => {
				const caretElement = caretRefs.current[playerIndex]
				if (!caretElement) {
					return
				}

				const target = containerRef.current?.querySelector(
					`[data-word="0"][data-char="0"]`
				) as HTMLElement | null

				if (target) {
					target.parentNode?.insertBefore(caretElement, target)
				}
			})
		})
	}, [isMultiplayer])

	return {
		containerRef,
		caretRef,
		caretRefs,
		triggerMistakeAnimation,
		mistakeAnimCaretRef,
	}
}
export default useCaretAnimation
