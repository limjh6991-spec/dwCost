/** * 재공,제품 원가 (TAB 구조) */
<template>
  <auth-tabs>
    <!-- Tab 1 재공원가 -->
    <template #tab-content-TAB090006>
      <TAB090006 />
    </template>
    <!-- Tab 2 제품원가 -->
    <template #tab-content-TAB090007>
      <TAB090007 />
    </template>
  </auth-tabs>
</template>

<script>
import TAB090006 from '@web/c0009000/tab/TAB090006.vue';
import TAB090007 from '@web/c0009000/tab/TAB090007.vue';

export default {
  name: 'DW_C0009007',
  props: {},
  components: {
    TAB090006,
    TAB090007,
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
