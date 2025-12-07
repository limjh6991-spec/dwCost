/** * 제조경비 집계표 (TAB 구조) */
<template>
  <auth-tabs>
    <!-- Tab 1 부서별 집계표 -->
    <template #tab-content-TAB090004>
      <TAB090004 />
    </template>
    <!-- Tab 2 제품별 집계표 -->
    <template #tab-content-TAB090005>
      <TAB090005 />
    </template>
  </auth-tabs>
</template>

<script>
import TAB090004 from '@web/c0009000/tab/TAB090004.vue';
import TAB090005 from '@web/c0009000/tab/TAB090005.vue';

export default {
  name: 'DW_C0009005',
  props: {},
  components: {
    TAB090004,
    TAB090005,
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
