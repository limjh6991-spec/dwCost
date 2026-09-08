/** * 타시스템 > 자재투입정보(VN) - 탭 구조 */
<template>
  <auth-tabs>
    <!-- Tab 1: 품목별투입조회 -->
    <template #tab-content-TAB070020>
      <TAB070020 tabId="TAB070020" />
    </template>
    <!-- Tab 2: 기타입출고금액조회(통합) -->
    <template #tab-content-TAB070021>
      <TAB070021 tabId="TAB070021" />
    </template>
    <!-- Tab 3: 재고금액상세조회(통합) -->
    <template #tab-content-TAB070022>
      <TAB070022 tabId="TAB070022" />
    </template>
    <!-- Tab 4: 자재조회 -->
    <template #tab-content-TAB070023>
      <TAB070023 tabId="TAB070023" />
    </template>
    <!-- Tab 5: 창고별수불집계조회 -->
    <template #tab-content-TAB070025>
      <TAB070025 tabId="TAB070025" />
    </template>
    <!-- Tab 6: 사업단위별수불집계조회 -->
    <template #tab-content-TAB070026>
      <TAB070026 tabId="TAB070026" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070020 from './tab/TAB070020.vue';
import TAB070021 from './tab/TAB070021.vue';
import TAB070022 from './tab/TAB070022.vue';
import TAB070023 from './tab/TAB070023.vue';
import TAB070025 from './tab/TAB070025.vue';
import TAB070026 from './tab/TAB070026.vue';

export default {
  name: 'DOI_C0007016',
  props: {},
  components: {
    TAB070020,
    TAB070021,
    TAB070022,
    TAB070023,
    TAB070025,
    TAB070026,
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
