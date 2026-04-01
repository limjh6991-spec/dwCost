/** * 타시스템 > 생산정보 */
<template>
  <auth-tabs>
    <!-- Tab 0 생산수불 -->
    <template #tab-content-TAB070001>
      <TAB070001 tabId="TAB070001" />
    </template>
    <!-- Tab 1 연구개발 수불 -->
    <template #tab-content-TAB070002>
      <TAB070002 tabId="TAB070002" />
    </template>
    <!-- Tab 2 MES 수불 -->
    <template #tab-content-TAB070013>
      <TAB070013 tabId="TAB070013" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070001 from './tab/TAB070001.vue';
import TAB070002 from './tab/TAB070002.vue';
import TAB070013 from './tab/TAB070013.vue';

export default {
  name: 'DOI_C0007003',
  props: {},
  components: {
    TAB070001,
    TAB070002,
    TAB070013,
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
