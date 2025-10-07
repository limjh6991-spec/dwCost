/**
 *	기준정보 > 사용자-메뉴 권한 관리
 */
<template>
	<auth-tabs>
		<!-- Tab 0 사용자 관리  #tab-content-#{DOI_CM_SYS_RESOURCE.sys_resource_id} -->
		<template #tab-content-TAB012000>
			<TAB012000/>
		</template>
		<!-- Tab 1 메뉴관리 -->
		<template #tab-content-TAB013000>
			<TAB013000/>	
		</template>
		<!-- Tab 2 사용자메뉴 권한관리 -->
		<template #tab-content-TAB014000>
			<TAB014000/>
		</template>
	</auth-tabs>
</template>

<script>
import TAB012000 from './tab/TAB012000.vue';
import TAB013000 from './tab/TAB013000.vue';
import TAB014000 from './tab/TAB014000.vue';
export default {
	name:"DW_C0001009",	
    props: {},  
	components:{
		TAB012000,TAB013000,TAB014000
	},
	watch: {},
	data () {
		return {
		}
	},
	computed: {},	
	created() {		
	},	
	mounted() {
		console.log("menu C0001009");
	},
	beforeUnmount() {
	},
	methods: {
	},

	//keepAlive 활성화시 사용가능
	activated() {
		console.log("onActivated");
		// called on initial mount
		// and every time it is re-inserted from the cache
	},

	deactivated(){
		console.log("onDeactivated");
		// called when removed from the DOM into the cache
		// and also when unmounted
	},
}

</script>