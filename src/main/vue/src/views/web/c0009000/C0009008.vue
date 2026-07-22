/** * 판매관리비 집계표 (TAB 구조) */
<template>
  <auth-tabs>
    <!-- Tab 1 부서별 집계표 -->
    <template #tab-content-TAB090008>
      <TAB090008 />
    </template>
    <!-- Tab 2 제품별 집계표 -->
    <template #tab-content-TAB090009>
      <TAB090009 />
    </template>
    <!-- Tab 3 부서별 집계표(누적) -->
    <template #tab-content-TAB090008_Cum>
      <TAB090008Cum />
    </template>
  </auth-tabs>
</template>

<script>
import TAB090008 from '@web/c0009000/tab/TAB090008.vue';
import TAB090009 from '@web/c0009000/tab/TAB090009.vue';
import TAB090008Cum from '@web/c0009000/tab/TAB090008_Cum.vue';

export default {
  name: 'DW_C0009008',
  props: {},
  components: {
    TAB090008,
    TAB090009,
    TAB090008Cum,
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

