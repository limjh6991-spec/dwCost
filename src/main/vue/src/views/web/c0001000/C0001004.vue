<!-- 기준정보 > 사용자-메뉴 권한 관리 (C0001004) -->
<template>
	<auth-tabs>
		<!-- Tab 0 계정과목 관리 -->
		<template #tab-content-TAB010001>
			<TAB010001 :yearList="yearList" />
		</template>
		<!-- Tab 1 부서 관리 -->
		<template #tab-content-TAB010002>
			<TAB010002 :yearList="yearList" />
		</template>
		<!-- Tab 2 BOM 관리 -->
		<template #tab-content-TAB010003>
			<TAB010003 :yearList="yearList" />
		</template>
		<!-- Tab 3 모델 관리 -->
		<template #tab-content-TAB010005>
			<TAB010005 :yearList="yearList" />
		</template>
	</auth-tabs>
</template>

<script>
import TAB010001 from './tab/TAB010001.vue';
import TAB010002 from './tab/TAB010002.vue';
import TAB010003 from './tab/TAB010003.vue';
import TAB010005 from './tab/TAB010005.vue';
export default {
	name:"DW_C0001004",
	props: {},
	components:{
		TAB010001,TAB010002,TAB010003,TAB010005
	},
	watch: {},
	data () {
		return {
			yearList: []
		}
	},
	computed: {},
	created() {
		// yearList 생성: 최근 10년치
		const currentYear = new Date().getFullYear();
		this.yearList = Array.from({length: 10}, (_, i) => ({
			value: String(currentYear - i),
			text: String(currentYear - i)
		}));
	},
	mounted() {
		console.log("menu C0001004");
	},
	beforeUnmount() {},
	methods: {},
	activated() {
		console.log("onActivated");
	}
}
</script>
