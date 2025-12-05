import { createBrowserRouter } from 'react-router'
import type { ComponentType } from 'react'

type PageModule = { default: ComponentType<Record<string, unknown>> }
type GlobImport = Record<string, () => Promise<PageModule>>

const pageLoaders = import.meta.glob('../pages/**/page.tsx') as GlobImport
const layoutLoaders = import.meta.glob('../pages/**/layout.tsx') as GlobImport

const getRoutePath = (filename: string) => {
	let name = filename.replace(/^\.\.\/pages\//, '').replace(/\.tsx$/, '')
	name = name.replace(/\[(.+?)\]/g, ':$1')
	name = name.replace(/\/?\(([^)]+)\)/g, '')
	name = name.replace(/^\/+/, '')
	if (name === 'page') return '/'
	if (name.endsWith('/page'))
		return `/${name.replace('/page', '')}`.length
			? `/${name.replace('/page', '')}`
			: '/'
	return `/${name}`
}

const routes = Object.keys(pageLoaders).map(pageKey => {
	const path = getRoutePath(pageKey)

	return {
		path,
		lazy: {
			Component: async () => {
				const pageMod = await pageLoaders[pageKey]()
				let PageComponent = pageMod.default

				const matches: string[] = []
				const normalizedPageKey = pageKey.replace(/\\/g, '/')

				for (const layoutKey of Object.keys(layoutLoaders)) {
					const normalizedLayoutKey = layoutKey.replace(/\\/g, '/')
					const layoutDir = normalizedLayoutKey
						.replace(/\/layout\.tsx$/, '/')
						.replace(/\\/g, '/')
					if (normalizedPageKey.startsWith(layoutDir)) {
						matches.push(layoutKey)
					}
				}

				matches.sort((a, b) => b.length - a.length)

				for (const layoutKey of matches) {
					const layoutMod = await layoutLoaders[layoutKey]()
					const Layout = layoutMod.default
					const Prev = PageComponent
					PageComponent = () => (
						<Layout>
							<Prev />
						</Layout>
					)
				}

				return PageComponent
			},
		},
	}
})
const router = createBrowserRouter(routes, {
	future: { v7_startTransition: true },
})

export default router
