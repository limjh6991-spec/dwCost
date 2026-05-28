/** * 타시스템 I/F > 생산수불 변경 검증 */
<template>
  <auth-tabs>
    <!-- Tab: 수불 변경 검증 -->
    <template #tab-content-TAB070014>
      <TAB070014 tabId="TAB070014" />
    </template>
    <!-- Tab: 수불 산출 검증 -->
    <template #tab-content-TAB070015>
      <TAB070015 tabId="TAB070015" />
    </template>
  </auth-tabs>
</template>

<script>
import TAB070014 from './tab/TAB070014.vue';
import TAB070015 from './tab/TAB070015.vue';

export default {
  name: 'DOI_C0007011',
  props: {},
  components: {
    TAB070014,
    TAB070015,
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
