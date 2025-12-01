/** * 타시스템 > 수불체크 (생산/입고/판매) */
<template>
  <auth-tabs>
    <!-- Tab 5 생산수불 자체 체크 -->
    <template #tab-content-TAB070005>
      <TAB070005 tabId="TAB070005" />
    </template>
    <!-- Tab 6 입고수불 체크 -->
    <template #tab-content-TAB070006>
      <TAB070006 tabId="TAB070006" />
    </template>
    <!-- Tab 7 생산/입고/판매 체크 -->
    <template #tab-content-TAB070007>
      <TAB070007 tabId="TAB070007" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070005 from './tab/TAB070005.vue';
import TAB070006 from './tab/TAB070006.vue';
import TAB070007 from './tab/TAB070007.vue';

export default {
  name: 'DOI_C0007006',
  props: {},
  components: {
    TAB070005,
    TAB070006,
    TAB070007,
  },
  watch: {},
  data() {
    return {};
  },
  computed: {},
  created() {},
  mounted() {},
  beforeUnmount() {},
  methods: {},
};
</script>
