/** * 제조_매출원가 > 제조원가 */
<template>
  <auth-tabs>
    <!-- Tab 1 경비 집계 -->
    <template #tab-content-TAB030001>
      <TAB030001 tabId="TAB030001" />
    </template>
    <!-- Tab 2 가공비 배부 -->
    <template #tab-content-TAB030002>
      <TAB030002 tabId="TAB030002" />
    </template>
    <!-- Tab 3 재료비 집계 -->
    <template #tab-content-TAB030003>
      <TAB030003 tabId="TAB030003" />
    </template>
    <!-- Tab 4 재료비 배부 -->
    <template #tab-content-TAB030004>
      <TAB030004 tabId="TAB030004" />
    </template>
    <!-- Tab 5 재공 평가 -->
    <template #tab-content-TAB030005>
      <TAB030005 tabId="TAB030005" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB030001 from './tab/TAB030001.vue';
import TAB030002 from './tab/TAB030002.vue';
import TAB030003 from './tab/TAB030003.vue';
import TAB030004 from './tab/TAB030004.vue';
import TAB030005 from './tab/TAB030005.vue';

export default {
  name: 'DOI_C0003001',
  props: {},
  components: {
    TAB030001,
    TAB030002,
    TAB030003,
    TAB030004,
    TAB030005,
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
