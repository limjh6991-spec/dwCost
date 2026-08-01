/** 매출원가 집계 > VINA 제품 수불 : UP_VN_STOCK_BOH(기초) + UP_VN_STOCK_COST(원가) */
<template>
  <VnProcRunner title="제품 수불 (기초+원가)" queryId="C0003002_Vn1" procName="UP_VN_STOCK_BOH" />
</template>
<script>
import VnProcRunner from './VnProcRunner.vue';
export default { name: 'TAB030018', components: { VnProcRunner } };
</script>
