/** * 결산증빙 자료 > 투입비용 */
<template>
  <auth-tabs>
    <!-- Tab 1 부서별 경비 집계표-->
    <template #tab-content-TAB080001>
      <TAB080001 />
    </template>
    <!-- Tab 2 원가항목별 비용 -->
    <template #tab-content-TAB080002>
      <TAB080002 />
    </template>
    <!-- Tab 3 제품별 가공비 -->
    <template #tab-content-TAB080003>
      <TAB080003 />
    </template>
    <!-- Tab 4 자재별 투입실적 -->
    <template #tab-content-TAB080004>
      <TAB080004 />
    </template>
    <!-- Tab 5  원가항목별 재료비 -->
    <template #tab-content-TAB080005>
      <TAB080005 />
    </template>
    <!-- Tab 6  제품투입별 재료비 -->
    <template #tab-content-TAB080006>
      <TAB080006 />
    </template>
  </auth-tabs>
</template>

<script>
import TAB080001 from './tab/TAB080001.vue';
import TAB080002 from './tab/TAB080002.vue';
import TAB080003 from './tab/TAB080003.vue';
import TAB080004 from './tab/TAB080004.vue';
import TAB080005 from './tab/TAB080005.vue';
import TAB080006 from './tab/TAB080006.vue';

export default {
  name: 'DW_C0008002',
  props: {},
  components: {
    TAB080001,
    TAB080002,
    TAB080003,
    TAB080004,
    TAB080005,
    TAB080006,
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
