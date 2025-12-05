import PracticeMode from '../../components/PracticeMode.tsx'

const Page = () => {
	return (
		<div className='flex min-w-outer-container h-full items-center justify-center flex-col gap-10'>
			<div className='text-center'>
				{/*<h1 className='sm:block text-8xl hidden font-bold tracking-tight'>*/}
				{/*	<TypingAnimation text='TypeRush' speed={200} colorSplit={4} />*/}
				{/*</h1>*/}
			</div>
			<PracticeMode />
		</div>
	)
}

export default Page
