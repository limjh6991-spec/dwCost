/** * 제조_매출원가 > 매출원가 */
<template>
  <auth-tabs>
    <!-- Tab 6 제품 수불 -->
    <template #tab-content-TAB030006>
      <TAB030006 tabId="TAB030006" />
    </template>
    <!-- Tab 7 매출원가/판관비 -->
    <template #tab-content-TAB030007>
      <TAB030007 tabId="TAB030007" />
    </template>
    <!-- Tab 8 매출상계 -->
    <template #tab-content-TAB030008>
      <TAB030008 tabId="TAB030008" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB030006 from './tab/TAB030006.vue';
import TAB030007 from './tab/TAB030007.vue';
import TAB030008 from './tab/TAB030008.vue';

export default {
  name: 'DOI_C0003002',
  props: {},
  components: {
    TAB030006,
    TAB030007,
    TAB030008,
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
