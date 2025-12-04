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
      // 구분 드롭다운 목록 추가
      categoryOptions: [
        { value: '개발', label: '개발' },
        { value: '양산', label: '양산' },
      ],

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

    this.$nextTick(() => {
      const gv = this.viewGridView;
      if (!gv) return;

        gv.setColumnProperty('구분', 'values', ['개발', '양산']);
        gv.setColumnProperty('구분', 'labels', ['개발', '양산']);
        gv.setColumnProperty('구분', 'lookupDisplay', true);
        gv.setColumnProperty('구분', 'editor', {
          type: 'dropdown',
          textReadOnly: true,
          dropDownWhenClick: true,
          domainOnly: true,
        });

      gv.onEditBegin = (grid, index) => {
        if (index.fieldName !== '구분') {
        const provider = grid.getDataProvider();
        const state = provider.getRowState(index.dataRow);

        if (state === 'created') {
          return false;
          }
        } 
      };
    });
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
        구분: '',
        도우코드: '',
        rmaIn: null,
        rmaOut: null,
        생성자: this.userAuthInfo.userInfo.userName,
        생성시각: null,
      };

      const dp = this.viewGridDataProvider;
      const rowIndex = dp.addRow(newRow);

      dp.setRowState(rowIndex, 'created');

      this.viewGridRows = dp.getJsonRows(0, dp.getRowCount());

      const gv = this.viewGridView;
      if (gv) {
        this.$nextTick(() => {
          const dropdownConfig ={
            type: 'dropdown',
            textReadOnly: true,
            dropDownWhenClick: true,
            domainOnly: true,
            items: [
              { value: '개발', label: '개발' },
              { value: '양산', label: '양산' },
            ],
          };

          gv.setColumnProperty('구분', 'editor', dropdownConfig);
          gv.setColumnProperty('구분', 'lookupDisplay', true);
          gv.setColumnProperty('구분', 'editable', true);

          gv.setCurrent({ itemIndex: rowIndex, column: '도우코드' });
          gv.showEditor();
      });
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
      } else {
        return;
      }

      this.hasSearched = true;
      await this.getDataList();

      const gv = this.viewGridView;
      if (gv) {
      }
    },

    onCellClickedViewGrid(grid, clickData) {
      if (clickData.cellType !== 'data') return;

    const fieldName = clickData.fieldName;
    const itemIndex = clickData.itemIndex;

    // ✅ 구분 셀 클릭 : RealGrid에게 맡긴다 (드롭다운만 잘 뜨면 됨)
    if (fieldName === '구분') {
      return;
    }

    // ✅ 도우코드 셀 클릭: 팝업 열기 전에 "반드시" 편집 종료
    if (fieldName === '도우코드') {
      if (grid.isEditing()) {
        try {
          grid.commit(true);   // 에디터 있으면 종료 + 커밋
        } catch (e) {
          console.warn('⚠️ [onCellClickedViewGrid] commit 중 에러 → cancel()', e);
          try {
            grid.cancel();
          } catch (e2) {
            console.warn('⚠️ [onCellClickedViewGrid] cancel 도 실패', e2);
          }
        }
      }

      if (itemIndex == null || itemIndex < 0) return;      

        this.selectedRowIndex = itemIndex;
        this.selectedModel = '';

        this.openModelPopup();
      }

      if (clickData.fieldName === '구분') {
        if (!grid.getColumnProperty('구분', 'editable')) {
          return;
        }

        this.$nextTick(() => {
          grid.showEditor();
        });
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
          도우코드: rowData['도우코드'],
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

      // 도우코드별 RMA_IN 합계를 추적하기 위한 맵
      const rmaInSumByCode = {};
      const outMonthByCode = {};

      // ✅ 첫 번째 패스: 전체 그리드의 모든 행에서 도우코드별 RMA_IN 합계 계산 (저장된 행 포함)
      for (let rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        const rowData = dp.getJsonRow(rowIndex);
        const 도우코드 = rowData['도우코드'];

        // 도우코드가 없으면 건너뛰기
        if (!도우코드 || 도우코드 === '') {
          continue;
        }

        const rmaIn = rowData.rmaIn !== null && rowData.rmaIn !== undefined && rowData.rmaIn !== ''
          ? parseInt(rowData.rmaIn, 10)
          : 0;
        const outMonth = rowData.outMonth !== null && rowData.outMonth !== undefined
          ? Number(rowData.outMonth)
          : 0;

        // 도우코드별 RMA_IN 합계 및 OUT_MONTH 기록
        if (!rmaInSumByCode[도우코드]) {
          rmaInSumByCode[도우코드] = 0;
          outMonthByCode[도우코드] = outMonth;
        }
        rmaInSumByCode[도우코드] += rmaIn;
      }

      // ✅ 두 번째 패스: 도우코드별 합계 검증
      for (const [도우코드, rmaInSum] of Object.entries(rmaInSumByCode)) {
        const outMonth = outMonthByCode[도우코드];
        if (outMonth > 0 && rmaInSum > outMonth) {
          this.$toast('error', `도우코드 ${도우코드}의 RMA_IN은 OUT_MONTH보다 클 수 없습니다.`);
          return;
        }
      }

      // ✅ 세 번째 패스: 추가/수정 데이터 수집 및 필수값 검증
      for (let rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        const rowData = dp.getJsonRow(rowIndex);
        const state = dp.getRowState(rowIndex); // 'created' | 'updated' | 'none' 등
        const isNew = state === 'created' || !rowData.rowSeq;
        const isModified = state === 'updated';

        if (!isNew && !isModified) continue;

        // RMA_IN 검증: OUT_MONTH보다 클 수 없음
        const rmaIn = rowData.rmaIn !== null && rowData.rmaIn !== undefined && rowData.rmaIn !== ''
          ? parseInt(rowData.rmaIn, 10)
          : null;
        const outMonth = rowData.outMonth !== null && rowData.outMonth !== undefined
          ? Number(rowData.outMonth)
          : 0;
        const 도우코드 = rowData['도우코드'];

        // 필수 필드 검증
        if (!도우코드 || 도우코드 === '') {
          this.$toast('error', `도우코드는 필수입니다.`);
          return;
        }

        if (rmaIn === null) {
          this.$toast('error', `도우코드 "${도우코드}"의 RMA_IN은 필수입니다.`);
          return;
        }

        const base = {
          rowSeq: rowData.rowSeq,
          yyyymm: rowData.yyyymm,
          selCode: rowData.selCode,
          siteOrg: rowData.siteOrg,
          도우코드: 도우코드,
          rmaIn: rmaIn,
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
    onEditCommitViewGrid(grid, index, oldValue, newValue) {
      const fieldName = index.fieldName || grid.getColumn(index.column).fieldName;

      if (fieldName !== 'rmaIn') {
        return;
      }
      const rmaIn = Number(newValue || 0);
      const outMonth = Number(grid.getValue(index.itemIndex, 'outMonth') || 0);

      if (outMonth && rmaIn > outMonth) {
        grid.setValue(index.itemIndex, 'rmaIn', oldValue);
      }
    },
    // 모델정보 팝업 열기
    openModelPopup() {
      const siteCode = this.siteMap[this.params.site] || this.params.site;
      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;

      // ✅ 도우코드 재선택 시 필터 없이 전체 목록 조회
      const queryParams = {
        yyyymm: yyyymm,
        site: siteCode,
      };
      
      // 도우코드가 있고 비어있지 않으면 필터로 사용
      if (this.selectedModel && this.selectedModel.trim() !== '') {
        queryParams.model = this.selectedModel;
      }

      const params = {
        dialogTitle: '모델 정보',
        popUpSize: 'lg',
        step: 7,
        height: 500,
        gridJs: 'C0007009Popup.js',
        search: {
          menuId: 'c0007009',
          queryId: 'selectModelPopup',
          queryParams: queryParams,
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

      // ✅ 팝업 그리드 더블클릭 시: popup grid 편집 먼저 끝내고 값 적용
      gridView.onCellDblClicked = (grid, clickData) => {
        if (clickData.cellType !== 'data') return;

        if (grid.isEditing()) {
          try {
            grid.commit(true);
          } catch (e) {
            console.warn('⚠️ [Popup] commit 에러 → cancel()', e);
            try {
              grid.cancel();
            } catch (e2) {
              console.warn('⚠️ [Popup] cancel 도 실패', e2);
            }
          }
        }

        const row = dp.getJsonRow(clickData.dataRow);
        if (!row) return;

        // ✅ 메인 그리드에도 동일하게 안전장치 (이중 안전벨트 느낌)
        const mainGrid = this.viewGridView;
        if (mainGrid && mainGrid.isEditing()) {
          try {
            mainGrid.commit(true);
          } catch (e) {
            console.warn('⚠️ [Popup] 메인 commit 에러 → cancel()', e);
            try {
              mainGrid.cancel();
            } catch (e2) {
              console.warn('⚠️ [Popup] 메인 cancel 도 실패', e2);
            }
          }
        }

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

      // ✅ 팝업 그리드 편집 종료
      if (gridView.isEditing()) {
        try {
          gridView.commit(true);
        } catch (e) {
          console.warn('⚠️ [handleModelConfirm] commit 에러 → cancel()', e);
          try {
            gridView.cancel();
          } catch (e2) {
            console.warn('⚠️ [handleModelConfirm] cancel 도 실패', e2);
          }
        }
      }

      const checked = gridView.getCheckedRows(true);
      if (!checked || checked.length === 0) {
        this.$toast('info', '선택된 모델이 없습니다.');
        return;
      }

      const row = dp.getJsonRow(checked[0]);

      const mainGrid = this.viewGridView;
      if (mainGrid && mainGrid.isEditing()) {
        try {
          mainGrid.commit(true);
        } catch (e) {
          console.warn('⚠️ [handleModelConfirm] 메인 commit 에러 → cancel()', e);
          try {
            mainGrid.cancel();
          } catch (e2) {
            console.warn('⚠️ [handleModelConfirm] 메인 cancel 도 실패', e2);
          }
        }
      }

      this.applyModelFromPopup(row);
    },

    applyModelFromPopup(row) {
      const modelValue = row['도우코드'];
      if (!modelValue) {
        this.$toast('error', '모델 정보를 찾을 수 없습니다.');
        return;
      }

      if (!this.viewGridDataProvider || this.selectedRowIndex == null) {
        this.$toast('error', '대상 행 정보를 찾을 수 없습니다.');
        return;
      }

      this.viewGridDataProvider.setValue(this.selectedRowIndex, '도우코드', modelValue);

      const lastChar = modelValue.slice(-1).toUpperCase();
      const category = lastChar === 'D' ? '개발' : '양산';
      this.viewGridDataProvider.setValue(this.selectedRowIndex, '구분', category);

      // 팝업에서 받아온 OUT_MONTH 데이터를 그리드에 저장
      const outMonth = row['outMonth'] || row['OUT_MONTH'] || row['outQty'];
      if (outMonth) {
        this.viewGridDataProvider.setValue(this.selectedRowIndex, 'outMonth', outMonth);
      }

      if (this.viewGridRows[this.selectedRowIndex]) {
        this.viewGridRows[this.selectedRowIndex]['도우코드'] = modelValue;
        this.viewGridRows[this.selectedRowIndex]['구분'] = category;
        if (outMonth) {
          this.viewGridRows[this.selectedRowIndex]['outMonth'] = outMonth;
        }
      }

      this.selectedRowIndex = null;
      this.selectedGridType = null;
      this.selectedModel = '';
    },
  },
};
</script>