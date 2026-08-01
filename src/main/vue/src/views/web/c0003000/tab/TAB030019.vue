/** 매출원가 집계 > VINA 매출원가·판관비 : UP_VN_SALE_COST (doi_slco/doi_smce_cost) */
<template>
  <VnProcRunner title="매출원가·판관비" queryId="C0003002_Vn2" procName="UP_DOI_SALE_COST" />
</template>
<script>
import VnProcRunner from './VnProcRunner.vue';
export default { name: 'TAB030019', components: { VnProcRunner } };
</script>
