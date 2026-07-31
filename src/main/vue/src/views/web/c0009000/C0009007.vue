/** * 재공,제품 원가 (TAB 구조) */
<template>
  <auth-tabs>
    <!-- Tab 1 재공원가 -->
    <template #tab-content-TAB090006>
      <TAB090006 />
    </template>
    <!-- Tab 2 제조원가(재공)_VN (VINA 전용) -->
    <template #tab-content-TAB090017>
      <TAB090017 />
    </template>
    <!-- Tab 3 제품원가 -->
    <template #tab-content-TAB090007>
      <TAB090007 />
    </template>
    <!-- Tab 4 매출원가(제품)_VN (VINA 전용) -->
    <template #tab-content-TAB090016>
      <TAB090016 />
    </template>
  </auth-tabs>
</template>

<script>
import TAB090006 from '@web/c0009000/tab/TAB090006.vue';
import TAB090017 from '@web/c0009000/tab/TAB090017.vue';
import TAB090007 from '@web/c0009000/tab/TAB090007.vue';
import TAB090016 from '@web/c0009000/tab/TAB090016.vue';

export default {
  name: 'DW_C0009007',
  props: {},
  components: {
    TAB090006,
    TAB090017,
    TAB090007,
    TAB090016,
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
