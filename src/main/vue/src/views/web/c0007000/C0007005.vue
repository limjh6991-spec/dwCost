/** * 타시스템 > 매출정보 */
<template>
  <auth-tabs>
    <!-- Tab 0 세금계산서 -->
    <template #tab-content-TAB070003>
      <TAB070003 tabId="TAB070003" />
    </template>
    <!-- Tab 1 수출신고필증 -->
    <template #tab-content-TAB070004>
      <TAB070004 tabId="TAB070004" />
    </template>
    <!-- Tab 2 수출Claim (참고/조회용, VN) -->
    <template #tab-content-TAB070016>
      <TAB070016 tabId="TAB070016" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070003 from './tab/TAB070003.vue';
import TAB070004 from './tab/TAB070004.vue';
import TAB070016 from './tab/TAB070016.vue';

export default {
  name: 'DOI_C0007005',
  props: {},
  components: {
    TAB070003,
    TAB070004,
    TAB070016,
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
