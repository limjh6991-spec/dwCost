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

    <div class="master-page">
      <!-- 🔼 입력용 그리드 -->
      <div class="input-grid-area mt-4">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="mb-0">불량반품 입력</h5>
          <div class="btn_wrap ms-auto">
            <b-button @click="addInputRow" class="sub"> 추가</b-button>
            <b-button @click="removeInputRow" class="second"> 행 삭제</b-button>
            <b-button class="main" @click="saveInputRows"> 저장</b-button>
          </div>
        </div>
        <RealGrid
          ref="inputGrid"
          :uid="'inputGrid'"
          :grid="inputGrid"
          :rows="inputGridRows"
          style="width: 100%; height: 100px"
          class="top-border"
          @cellClicked="onCellClickedInputGrid"
        />
      </div>
      <!-- 📋 조회용 그리드 -->
      <div class="view-grid-area mt-4">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="mb-0">불량반품 조회</h5>
          <div>
            <b-button class="second" @click="deleteRmaData"> 삭제</b-button>
            <b-button class="main" @click="updateRmaData">저장</b-button>
          </div>
        </div>
        <RealGrid
          ref="viewGrid"
          :uid="'viewGrid'"
          :grid="viewGrid"
          :rows="viewGridRows"
          style="width: 100%; height: 400px"
          class="top-border"
          @cellClicked="onCellClickedViewGrid"
          @editCommit="onEditCommitViewGrid"
        />
      </div>
    </div>

    <!-- 공통 검색 팝업 -->
    <CmDialog1 ref="cmDialog1C0007009" @confirm="handleModelConfirm" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
// named import로 변경
import { viewGrid } from '@web/c0007000/js/C0007009.js';
import { inputGridColumns, inputGridFields, inputGridOptions } from '@web/c0007000/js/C0007009_Input.js';
import grid from '../../../components/js/DPR';

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
      // 입력 그리드
      inputGrid: {
        fields: inputGridFields,
        columns: inputGridColumns,
        options: inputGridOptions
      },
      inputGridRows: [],
      
      // 조회 그리드 - 직접 할당
      viewGrid: _.cloneDeep(viewGrid),
      viewGridRows: [],

      deletedRows: [],
      
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
      selectedGridType: null,
    };
  },
  computed: {
    viewGridView() {
      return this.$refs.viewGrid && this.$refs.viewGrid.getGridView();
    },
    viewGridDataProvider() {
      return this.$refs.viewGrid && this.$refs.viewGrid.getGridDataProvider();
    },
    inputGridView() {
      return this.$refs.inputGrid && this.$refs.inputGrid.getGridView();
    },
    inputGridDataProvider() {
      return this.$refs.inputGrid && this.$refs.inputGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
  },
  watch: {
    'params.yyyymm'(newVal) {
      if (newVal) {
        this.onDateChange();
        this.updateInputGridYyyymm();
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
          this.updateInputGridSite();
          if (this.viewGridView) this.searchClick();
        }
      },
    },
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    
    this.$nextTick(() => {
      // 입력 그리드에 기본 행 추가
      this.initializeInputGrid();
      
      if (this.params.yyyymm) {
        this.searchClick();
      }
    });
  },
  activated() {
    this.reInitScreen();
  },
  methods: {
        initializeInputGrid() {
      if (!this.params.yyyymm) return;
      
      // 입력 그리드에 기본 행이 없으면 추가
      if (this.inputGridRows.length === 0) {
        const defaultRow = this.getEmptyInputRow();
        this.inputGridRows.push(defaultRow);
        console.log('✅ 입력 그리드 기본 행 추가:', defaultRow);
      }
    },

    reInitScreen() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';

      this.viewGridRows = [];
      this.inputGridRows = [];
      this.deletedRows = [];

      if (this.viewGridDataProvider) this.viewGridDataProvider.clearRows();
      if (this.inputGridDataProvider) this.inputGridDataProvider.clearRows();

      this.selectedModel = '';
      this.selectedRowIndex = null;
      this.selectedGridType = null;

      this.$nextTick(() => {
      // 재초기화 시에도 기본 행 추가
      this.initializeInputGrid();
        
        if (this.params.yyyymm) {
          this.searchClick();
        }
      });
    },

    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });

            // 년월 변경 시 입력 그리드 재초기화
      this.$nextTick(() => {
        this.initializeInputGrid();
      });
    },

    updateInputGridYyyymm() {
      if (!this.inputGridDataProvider) return;
      
      const yyyymm = this.params.yyyymm 
        ? this.params.yyyymm.replaceAll('-', '') 
        : null;
      
      const rowCount = this.inputGridDataProvider.getRowCount();
      for (let i = 0; i < rowCount; i++) {
        this.inputGridDataProvider.setValue(i, 'yyyymm', yyyymm);
      }
      
      this.inputGridRows.forEach(row => {
        row.yyyymm = yyyymm;
      });

      // 년월 업데이트 후 행이 없으면 기본 행 추가
      if (rowCount === 0) {
        this.initializeInputGrid();
      }
    },

    updateInputGridSite() {
      if (!this.inputGridDataProvider) return;
      
      const siteCode = this.siteMap[this.params.site] || this.params.site;
      
      const rowCount = this.inputGridDataProvider.getRowCount();
      for (let i = 0; i < rowCount; i++) {
        this.inputGridDataProvider.setValue(i, 'siteOrg', siteCode);
        this.inputGridDataProvider.setValue(i, 'site', this.params.site);
      }
      
      this.inputGridRows.forEach(row => {
        row.siteOrg = siteCode;
        row.site = this.params.site;
      });

      // 사업장 업데이트 후 행이 없으면 기본 행 추가
      if (rowCount === 0) {
        this.initializeInputGrid();
      }
    },

    getEmptyInputRow() {
      const yyyymm = this.params.yyyymm 
        ? this.params.yyyymm.replaceAll('-', '') 
        : null;
      const siteCode = this.siteMap[this.params.site] || this.params.site;

      return {
        yyyymm,
        selCode: 'ACTUAL',
        siteOrg: siteCode,
        site: this.params.site,
        모델명: '',
        rmaIn: null,
        rmaOut: null,
        생성자: this.userAuthInfo.userInfo.userName,
        생성시각: new Date().toISOString(),
      };
    },

    addInputRow() {
      if (!this.params.yyyymm) {
        this.$toast('error', '년월을 먼저 선택해 주세요.');
        return;
      }

      const newRow = this.getEmptyInputRow();
      this.inputGridRows.push(newRow);
      console.log('✅ 새 행 추가:', newRow);
    },

    removeInputRow() {
      if (!this.inputGridView || !this.inputGridDataProvider) {
        this.$toast('error', '입력 그리드가 초기화되지 않았습니다.');
        return;
      }

      this.inputGridView.commit();

      const checked = this.inputGridView.getCheckedRows(true);
      if (!checked || checked.length === 0) {
        this.$toast('error', '삭제할 입력행을 선택해 주세요.');
        return;
      }

      this.inputGridDataProvider.removeRows(checked);
      this.inputGridRows = this.inputGridDataProvider.getJsonRows(
        0,
        this.inputGridDataProvider.getRowCount()
      );

      // 모든 행이 삭제되면 기본 행 추가
      if (this.inputGridRows.length === 0) {
        this.$nextTick(() => {
          this.initializeInputGrid();
        });
      } 
    },

    async saveInputRows() {
      if (!this.inputGridView || !this.inputGridDataProvider) {
        this.$toast('error', '입력 그리드가 초기화되지 않았습니다.');
        return;
      }

      if (this.inputGridRows.length === 0) {
        this.$toast('info', '먼저 "추가" 버튼을 눌러 입력할 데이터를 추가해주세요.');
        return;
      }

      this.inputGridView.commit();

      const rowCount = this.inputGridDataProvider.getRowCount();
      const rows = this.inputGridDataProvider.getJsonRows(0, rowCount);

      if (!rows || rows.length === 0) {
        this.$toast('error', '저장할 입력 데이터가 없습니다.');
        return;
      }

      const invalidRows = rows.filter(row => 
        !row['모델명'] || 
        (row.rmaIn === null && row.rmaOut === null)
      );

      if (invalidRows.length > 0) {
        this.$toast('error', '모델명과 RMA_IN 또는 RMA_OUT 중 하나는 필수입니다.');
        return;
      }

      const insertData = rows.map((row) => ({
        yyyymm: row.yyyymm,
        selCode: row.selCode,
        site: row.siteOrg, // siteOrg 사용
        모델명: row['모델명'],
        rmaIn: row.rmaIn !== null && row.rmaIn !== undefined && row.rmaIn !== ''
          ? parseInt(row.rmaIn, 10) : null,
        rmaOut: row.rmaOut !== null && row.rmaOut !== undefined && row.rmaOut !== ''
          ? parseInt(row.rmaOut, 10) : null,
        생성자: this.userAuthInfo.userInfo.userName,
      }));

      const param = {
        menuId: 'c0007009',
        insert: [
          {
            queryId: 'insertRmaData',
            data: insertData,
          },
        ],
      };

      try {
        await this.$axios.api.saveData(param);
        this.$toast('success', '저장이 완료되었습니다.');

        if (this.inputGridDataProvider) {
          this.inputGridDataProvider.clearRows();
        }
        this.inputGridRows = [];

        // 저장 후 기본 행 다시 추가
        this.$nextTick(() => {
          this.initializeInputGrid();
        });

        await this.searchClick();
      } catch (e) {
        console.error('❌ 저장 실패:', e);
        this.$toast('error', '저장 중 오류가 발생했습니다.');
      }
    },

    onCellClickedInputGrid(grid, clickData) {
      if (clickData.cellType !== 'data') return;

      if (this.inputGridRows.length === 0) {
        this.$toast('info', '먼저 "추가" 버튼을 눌러 입력할 데이터를 추가해주세요.');
        return;
      }

      const fieldName = clickData.fieldName;
      if (fieldName !== '모델명') return;

      const itemIndex = clickData.itemIndex;
      if (itemIndex == null || itemIndex < 0) return;

      this.selectedRowIndex = itemIndex;
      this.selectedGridType = 'input';
      const row = this.inputGridRows[itemIndex];
      this.selectedModel = row['모델명'] || '';

      this.openModelPopup();
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
        console.log('✅ 조회 완료:', this.viewGridRows.length, '건');
      } catch (e) {
        console.error('❌ 조회 실패:', e);
        this.$toast('error', '조회 중 오류가 발생했습니다.');
      }
    },

    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast('error', '년월을 선택해 주세요.');
        return;
      }
      this.getDataList();
    },

    onCellClickedViewGrid(grid, clickData) {
      if (clickData.cellType !== 'data') return;
      
      if (clickData.fieldName === '모델명') {
        this.selectedRowIndex = clickData.itemIndex;
        this.selectedGridType = 'view';
        const row = this.viewGridDataProvider.getJsonRow(clickData.itemIndex);
        this.selectedModel = row['모델명'] || '';
        this.openModelPopup();
      }
    },

    async deleteRmaData() {
      console.log('🗑️ 삭제 버튼 클릭됨');

      if (!this.viewGridView || !this.viewGridDataProvider) {
        console.error('❌ 그리드 초기화 안됨');
        this.$toast('error', '그리드가 초기화되지 않았습니다.');
        return;
      }

      const checkedRows = this.viewGridView.getCheckedRows(true);
      console.log('✅ 체크된 행:', checkedRows);

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
        console.log('🗑️ 삭제 대상 행:', rowData);

        deleteData.push({
          rowSeq: rowData.rowSeq,
          yyyymm: rowData.yyyymm,
          selCode: rowData.selCode,
          siteOrg: rowData.siteOrg,
          모델명: rowData['모델명'],
        });
      });

      // 기존 삭제 예정 목록에 누적
      this.deletedRows = this.deletedRows.concat(deleteData);
      console.log('삭제 예정 목록(deletedRows):', this.deletedRows);

      // 화면에서만 제거
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
      console.log('💾 저장 버튼 클릭됨');

      if (!this.viewGridView || !this.viewGridDataProvider) {
        console.error('❌ 그리드 초기화 안됨');
        this.$toast('error', '그리드가 초기화되지 않았습니다.');
        return;
      }

      this.viewGridView.commit();

      // 1) 수정 대상 (체크된 행)
      const checkedRows = this.viewGridView.getCheckedRows(true);
      console.log('✅ 체크된 행(업데이트 대상):', checkedRows);

      const updateData = [];
      checkedRows.forEach(rowIndex => {
        const rowData = this.viewGridDataProvider.getJsonRow(rowIndex);
        console.log('📝 수정 행 데이터:', rowData);

        updateData.push({
          yyyymm: rowData.yyyymm,
          selCode: rowData.selCode,
          siteOrg: rowData.siteOrg,
          모델명: rowData['모델명'],
          생성시각: rowData['생성시각'],
          rmaIn: rowData.rmaIn !== null && rowData.rmaIn !== undefined
            ? parseInt(rowData.rmaIn, 10)
            : null,
          rmaOut: rowData.rmaOut !== null && rowData.rmaOut !== undefined
            ? parseInt(rowData.rmaOut, 10)
            : null,
          생성자: this.userAuthInfo.userInfo.userName,
        });
      });

      const deleteData = this.deletedRows || [];
      console.log('🗑️ 삭제 데이터(deleteData):', deleteData);

      if (updateData.length === 0 && deleteData.length === 0) {
        this.$toast('info', '수정/삭제할 데이터가 없습니다.');
        return;
      }

      const result = confirm(
        `수정 ${updateData.length}건, 삭제 ${deleteData.length}건을 저장하시겠습니까?`
      );
      if (!result) {
        console.log('❌ 저장 취소됨');
        return;
      }

      const param = { menuId: 'c0007009' };

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

      console.log('📤 서버로 전송할 파라미터:', JSON.stringify(param, null, 2));

      try {
        await this.$axios.api.saveData(param);
        console.log('✅ 저장/삭제 성공');

        this.$toast('success', '저장이 완료되었습니다.');

        // 삭제 예정 목록 초기화
        this.deletedRows = [];

        // 재조회
        await this.getDataList();
      } catch (error) {
        console.error('❌ 수정/삭제 저장 실패:', error);
        console.error('❌ 에러 상세:', error.response?.data);
        this.$toast('error', '저장 중 오류가 발생했습니다.');
      }
    },

    onEditCommitViewGrid(grid, index, oldValue, newValue) {
      console.log('✏️ 셀 수정:', {
        fieldName: index.fieldName,
        row: index.itemIndex,
        oldValue,
        newValue
      });

      const dataRow = this.viewGridDataProvider.getJsonRow(index.itemIndex);
      dataRow._modified = true;
      this.viewGridDataProvider.updateRow(index.itemIndex, dataRow);
    },

    onCellClickedViewGrid(grid, clickData) {
      console.log('🖱️ 셀 클릭:', clickData);

      if (clickData.cellType !== 'data') return;
      
      if (clickData.fieldName === '모델명') {
        const itemIndex = clickData.itemIndex;
        if (itemIndex == null || itemIndex < 0) return;

        this.selectedRowIndex = itemIndex;
        this.selectedGridType = 'view';
        const row = this.viewGridRows[itemIndex];
        this.selectedModel = row['모델명'] || '';

        this.openModelPopup();
      }
    },

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

      // 팝업 열기
      this.$refs.cmDialog1C0007009.openDialog(params);

      // 팝업 내부 RealGrid가 렌더링된 뒤에 접근
      this.$nextTick(() => {
        setTimeout(() => {
          const dialog = this.$refs.cmDialog1C0007009;
          const gridWrapper = dialog?.$refs?.cmDialog1Grid;

          const gridView = gridWrapper?.getGridView?.();
          const dp = gridWrapper?.getGridDataProvider?.();
          
          if (!gridView || !dp) {
            console.log('팝업 gridView 조회 실패 - 렌더링 지연');
            return;
          }

          // ✅ 더블클릭 이벤트
          gridView.onCellDblClicked = (grid, clickData) => {
            if (clickData.cellType !== 'data') return;

            const row = dp.getJsonRow(clickData.dataRow);
            if (!row) return;

            if (this.selectedGridType === 'input') {
              this.applyModelFromPopup(row);
              console.log("입력용 팝업: 더블클릭 적용 + 팝업 닫기");

            if (typeof dialog.closeDialog === "function") dialog.closeDialog();
            else if (typeof dialog.hide === "function") dialog.hide();
            else if (typeof dialog.close === "function") dialog.close();
            else console.warn("닫기 메소드 없음");
            }
            else if (this.selectedGridType === "view") {
              console.log("조회용 팝업: 더블클릭 적용(팝업 유지)");
            }
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
      console.log('📋 팝업에서 선택된 데이터:', row);

      this.applyModelFromPopup(row);
    },

    applyModelFromPopup(row) {
      const modelValue = row.model;
      if (!modelValue) {
        this.$toast('error', '모델 정보를 찾을 수 없습니다.');
        return;
      }

      if (this.selectedGridType === 'input' && this.inputGridDataProvider) {
        this.inputGridDataProvider.setValue(this.selectedRowIndex, '모델명', modelValue);
        if (this.inputGridRows[this.selectedRowIndex]) {
          this.inputGridRows[this.selectedRowIndex]['모델명'] = modelValue;
        }
      } else if (this.selectedGridType === 'view' && this.viewGridDataProvider) {
        this.viewGridDataProvider.setValue(this.selectedRowIndex, '모델명', modelValue);
        if (this.viewGridRows[this.selectedRowIndex]) {
          this.viewGridRows[this.selectedRowIndex]['모델명'] = modelValue;
        }
      }

      console.log('🎯 모델명 자동 적용:', modelValue);

      this.selectedRowIndex = null;
      this.selectedGridType = null;
      this.selectedModel = '';
    },
  },
};
</script>