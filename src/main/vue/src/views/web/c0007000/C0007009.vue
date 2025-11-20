<!-- 타시스템 > 불량반품 -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1">
          <div class="form-floating">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm"/>
            <label>기준월</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-3">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" :disabled="true" />
            <label for="floating">사업장</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick">
          <span class="ico_search"></span>
          조회
        </b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <div>
            <b-button @click="addViewRow" class="sub"> 추가</b-button>
            <b-button class="second" @click="deleteRmaData"> 삭제</b-button>
            <b-button class="main" @click="updateRmaData">저장</b-button>  
          </div>
        </div>  
      </div>
      <div class="grid-border-none">   
        <RealGrid
          ref="viewGrid"
          :uid="'viewGrid'"
          :grid="viewGrid"
          :rows="viewGridRows"
          style="height: 100%"
          :fixLayoutWidth="false"
          @cellClicked="onCellClickedViewGrid"
          @editCommit="onEditCommitViewGrid"
        />
      </div>   
    </div>
     <CmDialog1 ref="cmDialog1C0007009" @confirm="handleModelConfirm" /> 
  </div>       
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import { viewGrid as baseViewGrid } from '@web/c0007000/js/C0007009.js';

export default {
  name: 'C0007009',
  props: {
    yearList: {
      type: Array,
      default: () => [],
    },
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      // 조회 그리드 설정
      viewGrid: _.cloneDeep(baseViewGrid),
      viewGridRows: [],
      deletedRows: [],
      hasSearched: false,

      params: {
        yyyymm: null,
        site: 'HQ',
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      selectedModel: '',
      selectedModelInfo: null,
      selectedRowIndex: null,
    };
  },
  computed: {
    viewGridView() {
      return this.$refs.viewGrid && this.$refs.viewGrid.getGridView();
    },
    viewGridDataProvider() {
      return this.$refs.viewGrid && this.$refs.viewGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  watch: {
    'params.yyyymm'(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) this.params.yyyymm = newVal;
      },
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';

          if (this.viewGridView && this.hasSearched) {
            this.searchClick();
          }
        }
      },
    },
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
  },
  activated() {
    this.reInitScreen();
  },
  methods: {
    reInitScreen() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';

      this.viewGridRows = [];
      this.deletedRows = [];
      this.hasSearched = false;

      if (this.viewGridDataProvider) this.viewGridDataProvider.clearRows();

      this.selectedModel = '';
      this.selectedRowIndex = null;

      this.$nextTick(() => {});
    },

    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },

    addViewRow() {
      if (!this.params.yyyymm) {
        this.$toast('error', '년월을 먼저 선택해 주세요.');
        return;
      }

      if (!this.viewGridDataProvider) {
        this.$toast('error', '그리드가 초기화되지 않았습니다.');
        return;
      }

      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;
      const siteCode = this.siteMap[this.params.site] || this.params.site;

      const newRow = {
        rowSeq: null,
        yyyymm,
        selCode: 'ACTUAL',
        siteOrg: siteCode,
        site: this.params.site,
        모델명: '',
        rmaIn: null,
        rmaOut: null,
        생성자: this.userAuthInfo.userInfo.userName,
        생성시각: null,
      };

      const dp = this.viewGridDataProvider;
      const rowIndex = dp.addRow(newRow);
      this.viewGridRows = dp.getJsonRows(0, dp.getRowCount());

      const gv = this.viewGridView;
      if (gv) {
        gv.setCurrent({ itemIndex: rowIndex, column: '모델명' });
        gv.showEditor();
      }
    },

    async getDataList() {
      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;
      const siteCode = this.siteMap[this.params.site] || this.params.site;

      const params = { yyyymm, site: siteCode };

      const param = {
        menuId: 'c0007009',
        queryId: 'selectRmaData',
        queryParams: params,
        target: this.viewGridRows,
      };
      try {
        await this.$axios.api.search(param);
      } catch (e) {
        console.error('❌ 조회 실패:', e);
        this.$toast('error', '조회 중 오류가 발생했습니다.');
      }
    },

    async searchClick() {
      if (!this.params.yyyymm) {
        this.$toast('error', '년월을 선택해 주세요.');
        return;
      }
    
      if (this.viewGridView) {
        this.viewGridView.commit();
      }

      this.hasSearched = true;
      await this.getDataList();
    },

    onCellClickedViewGrid(grid, clickData) {
      if (clickData.cellType !== 'data') return;

      if (clickData.fieldName === '모델명') {
        const itemIndex = clickData.itemIndex;
        if (itemIndex == null || itemIndex < 0) return;

        this.selectedRowIndex = itemIndex;
        const row = this.viewGridDataProvider.getJsonRow(itemIndex);
        this.selectedModel = row['모델명'] || '';

        this.openModelPopup();
      }
    },

    async deleteRmaData() {
      if (!this.viewGridView || !this.viewGridDataProvider) {
        console.error('❌ 그리드 초기화 안됨');
        this.$toast('error', '그리드가 초기화되지 않았습니다.');
        return;
      }

      const checkedRows = this.viewGridView.getCheckedRows(true);

      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 데이터를 선택해주세요.');
        return;
      }

      const result = confirm(`선택된 ${checkedRows.length}건을 삭제하시겠습니까?`);
      if (!result) {
        console.log('❌ 삭제 취소됨');
        return;
      }

      const deleteData = [];

      checkedRows.forEach(rowIndex => {
        const rowData = this.viewGridDataProvider.getJsonRow(rowIndex);

        deleteData.push({
          rowSeq: rowData.rowSeq,
          yyyymm: rowData.yyyymm,
          selCode: rowData.selCode,
          siteOrg: rowData.siteOrg,
          모델명: rowData['모델명'],
        });
      });

      this.deletedRows = this.deletedRows.concat(deleteData);
      this.viewGridDataProvider.removeRows(checkedRows);
      this.viewGridRows = this.viewGridDataProvider.getJsonRows(
        0,
        this.viewGridDataProvider.getRowCount()
      );

      this.$toast(
        'success',
        `${deleteData.length}건이 삭제되었습니다.\n"저장" 버튼을 눌러야 최종 삭제됩니다.`
      );
    },

    async updateRmaData() {
      if (!this.viewGridView || !this.viewGridDataProvider) {
        console.error('❌ 그리드 초기화 안됨');
        this.$toast('error', '그리드가 초기화되지 않았습니다.');
        return;
      }

      this.viewGridView.commit();

      const dp = this.viewGridDataProvider;
      const rowCount = dp.getRowCount();

      const insertData = [];
      const updateData = [];

      for (let rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        const rowData = dp.getJsonRow(rowIndex);
        const state = dp.getRowState(rowIndex); // 'created' | 'updated' | 'none' 등
        const isNew = state === 'created' || !rowData.rowSeq;
        const isModified = state === 'updated';

        if (!isNew && !isModified) continue;

        const base = {
          rowSeq: rowData.rowSeq,
          yyyymm: rowData.yyyymm,
          selCode: rowData.selCode,
          siteOrg: rowData.siteOrg,
          모델명: rowData['모델명'],
          rmaIn:
            rowData.rmaIn !== null && rowData.rmaIn !== undefined && rowData.rmaIn !== ''
              ? parseInt(rowData.rmaIn, 10)
              : null,
          rmaOut:
            rowData.rmaOut !== null && rowData.rmaOut !== undefined && rowData.rmaOut !== ''
              ? parseInt(rowData.rmaOut, 10)
              : null,
        };

        if (isNew) {
          insertData.push({
            ...base,
            site: base.siteOrg,
            생성자: this.userAuthInfo.userInfo.userName,
          });
        } else {
          updateData.push({
            ...base,
            생성자: this.userAuthInfo.userInfo.userName,

          });
        }
      }

      const deleteData = this.deletedRows || [];

      if (insertData.length === 0 && updateData.length === 0 && deleteData.length === 0) {
        this.$toast('info', '추가/수정/삭제할 데이터가 없습니다.');
        return;
      }

      const result = confirm(
        `추가 ${insertData.length}건, 수정 ${updateData.length}건, 삭제 ${deleteData.length}건을 저장하시겠습니까?`
      );
      if (!result) {
        console.log('❌ 저장 취소됨');
        return;
      }

      const param = { menuId: 'c0007009' };

      if (insertData.length > 0) {
        param.insert = [
          {
            queryId: 'insertRmaData',
            data: insertData,
          },
        ];
      }

      if (updateData.length > 0) {
        param.update = [
          {
            queryId: 'updateRmaData',
            data: updateData,
          },
        ];
      }

      if (deleteData.length > 0) {
        param.delete = [
          {
            queryId: 'deleteRmaData',
            data: deleteData,
          },
        ];
      }

      try {
        let resp = await this.$axios.api.saveData(param);
        this.$toast('info', '저장완료');
        this.searchClick();
      } catch {
        this.$toast('info', '에러발생. 다시 작업해주세요.');
      }
    },
    // 모델 팝업 열기
    openModelPopup() {
      const siteCode = this.siteMap[this.params.site] || this.params.site;

      const params = {
        dialogTitle: '모델 정보',
        popUpSize: 'lg',
        step: 7,
        height: 500,
        gridJs: 'C0007009Popup.js',
        search: {
          menuId: 'c0007009',
          queryId: 'selectModelPopup',
          queryParams: {
            site: siteCode,
            model: this.selectedModel || '',
          },
        },
        showButton: false,
        confirmOnEnter: true,
      };

      this.$refs.cmDialog1C0007009.openDialog(params);

      this.$nextTick(() => {
        setTimeout(() => {
          const dialog = this.$refs.cmDialog1C0007009;
          const gridWrapper = dialog?.$refs?.cmDialog1Grid;

          const gridView = gridWrapper?.getGridView?.();
          const dp = gridWrapper?.getGridDataProvider?.();

          if (!gridView || !dp) {
            return;
          }

          gridView.onCellDblClicked = (grid, clickData) => {
            if (clickData.cellType !== 'data') return;

            const row = dp.getJsonRow(clickData.dataRow);
            if (!row) return;

            this.applyModelFromPopup(row);

            if (typeof dialog.closeDialog === 'function') dialog.closeDialog();
            else if (typeof dialog.hide === 'function') dialog.hide();
            else if (typeof dialog.close === 'function') dialog.close();
            else console.warn('닫기 메소드 없음');
          };
        }, 50);
      });
    },

    handleModelConfirm(params) {
      if (params.gridJs !== 'C0007009Popup.js') return;

      const gridView = params.gridView;
      const dp = params.dataProvider;

      if (!gridView || !dp) {
        this.$toast('error', '그리드 정보를 찾을 수 없습니다.');
        return;
      }

      const checked = gridView.getCheckedRows(true);
      if (!checked || checked.length === 0) {
        this.$toast('info', '선택된 모델이 없습니다.');
        return;
      }

      const row = dp.getJsonRow(checked[0]);

      this.applyModelFromPopup(row);
    },

    applyModelFromPopup(row) {
      const modelValue = row.model;
      if (!modelValue) {
        this.$toast('error', '모델 정보를 찾을 수 없습니다.');
        return;
      }

      if (!this.viewGridDataProvider || this.selectedRowIndex == null) {
        this.$toast('error', '대상 행 정보를 찾을 수 없습니다.');
        return;
      }

      this.viewGridDataProvider.setValue(this.selectedRowIndex, '모델명', modelValue);

      if (this.viewGridRows[this.selectedRowIndex]) {
        this.viewGridRows[this.selectedRowIndex]['모델명'] = modelValue;
      }

      this.selectedRowIndex = null;
      this.selectedGridType = null;
      this.selectedModel = '';
    },
  },
};
</script>