/** * 생산실적 메인 화면 (TAB 구조) */
<template>
  <auth-tabs>
    <!-- Tab 1 월별 집계 (수량) -->
    <template #tab-content-TAB090001>
      <TAB090001 />
    </template>
    <!-- Tab 2 월별, 기간별(누적) (수량) -->
    <template #tab-content-TAB090002>
      <TAB090002 />
    </template>
    <!-- Tab 3 년간 전체 실적 집계 -->
    <template #tab-content-TAB090003>
      <TAB090003 />
    </template>
  </auth-tabs>
</template>

<script>
import TAB090001 from '@web/c0009000/tab/TAB090001.vue';
import TAB090002 from '@web/c0009000/tab/TAB090002.vue';
import TAB090003 from '@web/c0009000/tab/TAB090003.vue';

export default {
  name: 'DW_C0009001',
  props: {},
  components: {
    TAB090001,
    TAB090002,
    TAB090003,
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
