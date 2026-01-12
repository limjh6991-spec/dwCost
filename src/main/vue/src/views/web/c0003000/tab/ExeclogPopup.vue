/** * 제조매출원가 프로시저 로그 팝업 */
<template>
  <b-modal
    v-model="visible"
    size="xl"
    title="프로시저 실행 로그"
    hide-footer
    @shown="onShown"
  >
    <div style="height: 250px;">
      <RealGrid ref="execLogGrid" :uid="'execLogGrid'" :step="'1'" :rows="logRows" />
    </div>

    <div style="height: 400px;">
      <div class="d-flex align-items-center mb-2">
        <strong style="margin-top: 10px;">상세 로그</strong>
      </div>

      <div class="rslt-box" v-html="formattedRslt"></div>
    </div>
  </b-modal>
</template>

<script>
import gridField from '@web/c0003000/js/ExeclogPopup.js';

export default {
  data() {
    return {
      visible: false,
      logRows: [],
      execLogGrid: null,
      queryParams: null,
      selectedRow: null,
      rsltMessage: '',
      _gridInited: false,
    };
  },
  created() {
    this.execLogGrid = _.cloneDeep(gridField);
    //this.initializeGrid();
  },
  computed: {
    formattedRslt() {

      const msg = this.rsltMessage || '행을 선택하면 상세 로그가 표시됩니다.';
      return msg.replaceAll('\n', '<br/>');
    },
    gridView() {
      return this.$refs.execLogGrid?.getGridView();
    },
    dataProvider() {
      return this.$refs.execLogGrid?.getGridDataProvider();
    },
  },
  methods: {
    open(queryParams) {
      this.queryParams = queryParams;
      this.visible = true;
    },
    async onShown() {
      await this.$nextTick();
      this.initGridOnce();
      await this.fetchLogList();
      this.rsltMessage = '';
      this.selectedRow = null;
    },

    initGridOnce() {
      if (this._gridInited) return;

      const gv = this.gridView;
      if (!gv) return;

      gv.onCellClicked = async (grid, clickData) => {
        if (clickData.cellType !== 'data') return;

        const row = this.dataProvider.getJsonRow(clickData.itemIndex);
        this.selectedRow = row;
        await this.fetchRsltMessage(row);
      };
      this._gridInited = true;
    },

    async fetchLogList() {
      const param = {
        menuId: 'c0003000',
        queryId: 'ExeclogPopup',
        queryParams: this.queryParams,
        target: null,
      };

      const resp = await this.$axios.api.search(param);

      const data = resp?.data?.data || resp?.data || resp || [];
      this.logRows = Array.isArray(data) ? data : [];
    },

    async fetchRsltMessage(row) {
      const param = {
        menuId: 'c0003000',
        queryId: 'ExeclogDetail',
        queryParams: { seqNo: row.seqNo ?? row.seqno },
        target: null,
      };

      const resp = await this.$axios.api.search(param);
      const data = resp?.data?.data || resp?.data || resp || [];

    const one = data[0] || null;
    const v = one?.rsltMessage ?? one?.rslt_message ?? one.rsltmessage;

    this.rsltMessage = (v === null || v === undefined)
      ? '(상세 로그가 없습니다)'
      : String(v);

    console.log('clicked row=', row, 'seqNo=', row.seqNo ?? row.seqno);
    console.log('ExeclogDetail raw resp =', resp);
    },
  },
};
</script>
<style scoped>
.rslt-box {
  width: 100%;
  height: 350px;
  overflow-y: auto;
  border: 1px solid #d8d8d8;
  border-radius: 6px;
  padding: 10px;
  background: #fbfbfb;
  font-family: 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.5;
  white-space: pre-wrap;
}
</style>
