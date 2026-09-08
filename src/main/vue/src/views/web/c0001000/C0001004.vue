<!-- 기준정보 > 원가기준정보 (C0001004) -->
<template>
	<auth-tabs>
		<!-- Tab 0 계정코드 -->
		<template #tab-content-TAB010001>
			<TAB010001 tabId="TAB010001" />
		</template>
		<!-- 언어별계정항목 (계정코드~부서코드 사이) -->
		<template #tab-content-TAB010006>
			<TAB010006 tabId="TAB010006" />
		</template>
		<!-- Tab 1 부서코드 -->
		<template #tab-content-TAB010002>
			<TAB010002 tabId="TAB010002" />
		</template>
		<!-- Tab 2 자재코드 -->
		<template #tab-content-TAB010003>
			<TAB010003 tabId="TAB010003" />
		</template>
		<!-- 공정 (자재코드~면적기준정보 사이) -->
		<template #tab-content-TAB010007>
			<TAB010007 tabId="TAB010007" />
		</template>
		<!-- Tab 3 면적기준정보 -->
		<template #tab-content-TAB010004>
			<TAB010004 tabId="TAB010004" />
		</template>
		<!-- Tab 4 기준정보 이월 실행 -->
		<template #tab-content-TAB010005>
			<TAB010005 tabId="TAB010005" />
		</template>
	</auth-tabs>
</template>

<script>
import TAB010001 from './tab/TAB010001.vue';
import TAB010002 from './tab/TAB010002.vue';
import TAB010003 from './tab/TAB010003.vue';
import TAB010004 from './tab/TAB010004.vue';
import TAB010005 from './tab/TAB010005.vue';
import TAB010006 from './tab/TAB010006.vue';
import TAB010007 from './tab/TAB010007.vue';

export default {
	name:"DW_C0001004",
	props: {},
	components:{
		TAB010001,TAB010002,TAB010003,TAB010004,TAB010005,TAB010006,TAB010007
	},
	watch: {},
	data () {
		return {};
	},
	computed: {},
	created() {},
	mounted() {},
	beforeUnmount() {},
	methods: {},
}
</script>
