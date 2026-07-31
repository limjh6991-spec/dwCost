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
    <!-- VINA 원가 파이프라인 (제조원가집계) : ①~③ 원천 + ④~⑧ 리팩토링 -->
    <template #tab-content-TAB030009>
      <TAB030009 tabId="TAB030009" />
    </template>
    <template #tab-content-TAB030010>
      <TAB030010 tabId="TAB030010" />
    </template>
    <template #tab-content-TAB030011>
      <TAB030011 tabId="TAB030011" />
    </template>
    <template #tab-content-TAB030012>
      <TAB030012 tabId="TAB030012" />
    </template>
    <template #tab-content-TAB030013>
      <TAB030013 tabId="TAB030013" />
    </template>
    <template #tab-content-TAB030014>
      <TAB030014 tabId="TAB030014" />
    </template>
    <template #tab-content-TAB030015>
      <TAB030015 tabId="TAB030015" />
    </template>
    <template #tab-content-TAB030016>
      <TAB030016 tabId="TAB030016" />
    </template>
    <template #tab-content-TAB030017>
      <TAB030017 tabId="TAB030017" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB030001 from './tab/TAB030001.vue';
import TAB030002 from './tab/TAB030002.vue';
import TAB030003 from './tab/TAB030003.vue';
import TAB030004 from './tab/TAB030004.vue';
import TAB030005 from './tab/TAB030005.vue';
import TAB030009 from './tab/TAB030009.vue';
import TAB030010 from './tab/TAB030010.vue';
import TAB030011 from './tab/TAB030011.vue';
import TAB030012 from './tab/TAB030012.vue';
import TAB030013 from './tab/TAB030013.vue';
import TAB030014 from './tab/TAB030014.vue';
import TAB030015 from './tab/TAB030015.vue';
import TAB030016 from './tab/TAB030016.vue';
import TAB030017 from './tab/TAB030017.vue';

export default {
  name: 'DOI_C0003001',
  props: {},
  components: {
    TAB030001,
    TAB030002,
    TAB030003,
    TAB030004,
    TAB030005,
    TAB030009,
    TAB030010,
    TAB030011,
    TAB030012,
    TAB030013,
    TAB030014,
    TAB030015,
    TAB030016,
    TAB030017,
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
