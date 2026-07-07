<!-- 환율관리 팝업 : VINA USD → KRW/VND 월평균 환율 수동 등록 (menuId=c0007012) -->
<template>
  <b-modal v-model="isOpen" size="lg" hide-footer no-close-on-backdrop centered>
    <template #title> 환율관리 (월평균) </template>
    <div>
      <div class="d-flex align-items-center mb-2">
        <span class="me-auto text-muted" style="font-size: 12px">
          환율은 <strong>USD 1 = N 통화</strong> 기준입니다. (예: KRW 1350, VND 25000)
        </span>
        <b-button class="sub" @click="addBtnClick">추가</b-button>
        <b-button @click="delBtnClick">삭제</b-button>
        <b-button class="main" @click="saveBtnClick">저장</b-button>
      </div>
      <div style="height: 360px">
        <RealGrid ref="rateGrid" :uid="'rateGrid'" :rows="rateRows" style="height: 100%" :fitLayoutWidthEnable="true" />
      </div>
    </div>
    <div class="bttn_wrap">
      <b-button block @click="closeDialog">닫기</b-button>
    </div>
  </b-modal>
</template>

<script>
import { RowState, ValueType } from 'realgrid';

export default {
  name: 'ExchangeRatePopup',
  data() {
    return {
      isOpen: false,
      rateRows: [],
      defaultYyyymm: null,
      duplicateKey: ['yyyymm', '통화'],
      isValidateCell: false,
      // RealGrid 레이아웃 (RealGrid 컴포넌트가 this.rateGrid 를 읽음)
      rateGrid: {
        options: {
          checkBar: { visible: true, exclusive: false, syncHeadCheck: true },
          display: { columnMovable: false, fitStyle: 'fill', emptyMessage: '등록된 환율이 없습니다.', showEmptyMessage: true },
          edit: { editable: true, columnEditableFirst: true, commitByCell: true, commitWhenLeave: true },
          rowIndicator: { visible: true },
          sorting: { enabled: false },
          stateBar: { visible: true },
        },
        fields: [
          { fieldName: 'yyyymm', dataType: ValueType.TEXT },
          { fieldName: '통화', dataType: ValueType.TEXT },
          { fieldName: '환율', dataType: ValueType.NUMBER },
        ],
        columns: [
          { name: 'YYYYMM', fieldName: 'yyyymm', width: '120', header: { text: '기준월(YYYYMM)' }, editable: true, styleName: 'tc' },
          {
            name: '통화',
            fieldName: '통화',
            width: '120',
            header: { text: '통화' },
            editable: true,
            styleName: 'tc',
            editor: { type: 'dropdown', textReadOnly: true, values: ['KRW', 'VND'], labels: ['KRW', 'VND'] },
          },
          { name: '환율', fieldName: '환율', width: '160', header: { text: '환율 (USD 1 = N)' }, editable: true, styleName: 'tr', numberFormat: '#,##0.####', editor: { type: 'number' } },
        ],
      },
    };
  },
  computed: {
    gridView() {
      return this.$refs.rateGrid ? this.$refs.rateGrid.getGridView() : null;
    },
    gridDataProvider() {
      return this.$refs.rateGrid ? this.$refs.rateGrid.getGridDataProvider() : null;
    },
  },
  methods: {
    async openDialog(params = {}) {
      this.defaultYyyymm = params.yyyymm ? String(params.yyyymm).replaceAll('-', '') : null;
      this.isOpen = true;
      await this.$nextTick();
      this.$refs.rateGrid.created();
      await this.getDataList();
    },
    closeDialog() {
      this.$emit('closePopup');
      this.isOpen = false;
    },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();
      let param = {
        menuId: 'c0007012',
        queryId: 'C0007012_Sch1',
        queryParams: {},
        target: this.rateRows,
      };
      await this.$axios.api.search(param);
    },
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();
      this.gridDataProvider.addRow({ yyyymm: this.defaultYyyymm, 통화: 'KRW', 환율: null });
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex });
    },
    delBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 행을 선택하세요');
        return;
      }
      this.$confirm('확인', `${checkedRows.length}건을 삭제하시겠습니까?`, async (confirmed) => {
        if (!confirmed) return;
        let newRows = [];
        let existingRows = [];
        checkedRows.forEach((itemIndex) => {
          if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            newRows.push(itemIndex);
          } else {
            existingRows.push(this.gridDataProvider.getJsonRow(itemIndex));
          }
        });
        if (newRows.length > 0) this.gridDataProvider.removeRows(newRows);
        if (existingRows.length > 0) {
          try {
            await this.$axios.api.saveData({
              menuId: 'c0007012',
              delete: [{ queryId: 'C0007012_Delete1', data: existingRows }],
            });
            this.getDataList();
          } catch {
            this.$toast('error', '삭제 중 에러가 발생했습니다.');
            return;
          }
        }
        this.$toast('success', '삭제되었습니다.');
      });
    },
    _validate(rows) {
      for (const r of rows) {
        if (!r.yyyymm || !/^\d{6}$/.test(String(r.yyyymm))) return '기준월은 YYYYMM 6자리로 입력하세요.';
        if (!r['통화'] || (r['통화'] !== 'KRW' && r['통화'] !== 'VND')) return '통화는 KRW 또는 VND 여야 합니다.';
        if (r['환율'] == null || Number(r['환율']) <= 0) return '환율은 0보다 큰 값이어야 합니다.';
      }
      return null;
    },
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();
      let saveData = this.$refs.rateGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      const err = this._validate([...saveData.insert, ...saveData.update]);
      if (err) {
        this.$toast('error', err);
        return;
      }
      this.$confirm('확인', '입력하신 환율을 저장하시겠습니까?', async (confirm) => {
        if (!confirm) return;
        try {
          await this.$axios.api.saveData({
            menuId: 'c0007012',
            delete: [{ queryId: 'C0007012_Delete1', data: saveData.delete }],
            insert: [{ queryId: 'C0007012_Insert1', data: saveData.insert }],
            update: [{ queryId: 'C0007012_Update1', data: saveData.update }],
          });
          this.$toast('info', '저장완료');
          this.getDataList();
        } catch {
          this.$toast('error', '저장 중 에러가 발생했습니다.');
        }
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.bttn_wrap {
  margin-top: 10px;
  text-align: center;
}
</style>
