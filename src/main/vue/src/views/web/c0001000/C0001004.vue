<!-- 기준정보 > 원가기준정보 (C0001004) -->
<template>
	<auth-tabs>
		<!-- Tab 0 계정코드 -->
		<template #tab-content-TAB010001>
			<TAB010001 tabId="TAB010001" />
		</template>
		<!-- Tab 1 부서코드 -->
		<template #tab-content-TAB010002>
			<TAB010002 tabId="TAB010002" />
		</template>
		<!-- Tab 2 자재코드 -->
		<template #tab-content-TAB010003>
			<TAB010003 tabId="TAB010003" />
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

export default {
	name:"DW_C0001004",
	props: {},
	components:{
		TAB010001,TAB010002,TAB010003,TAB010004,TAB010005
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
