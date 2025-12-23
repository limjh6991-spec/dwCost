/** * 타시스템 I/F > 재공/재고기초금액 이월 */
<template>
  <auth-tabs>
    <!-- Tab 5 생산수불 자체 체크 -->
    <template #tab-content-TAB070009>
      <TAB070009 tabId="TAB070009" />
    </template>
    <!-- Tab 6 입고수불 체크 -->
    <template #tab-content-TAB070010>
      <TAB070010 tabId="TAB070010" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070009 from './tab/TAB070009.vue';
import TAB070010 from './tab/TAB070010.vue';

export default {
  name: 'DOI_C0007010',
  props: {},
  components: {
    TAB070009,
    TAB070010,
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
