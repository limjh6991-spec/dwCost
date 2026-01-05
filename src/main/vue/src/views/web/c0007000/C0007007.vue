/** * 타시스템 > 유상사급 */
<template>
  <auth-tabs>
    <!-- Tab 0 자재기타출고 -->
    <template #tab-content-TAB070011>
      <TAB070011 tabId="TAB070011" />
    </template>
    <!-- Tab 1 재고금액상세 -->
    <template #tab-content-TAB070012>
      <TAB070012 tabId="TAB070012" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070011 from './tab/TAB070011.vue';
import TAB070012 from './tab/TAB070012.vue';

export default {
  name: 'DOI_C0007007',
  props: {},
  components: {
    TAB070011,
    TAB070012,
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
