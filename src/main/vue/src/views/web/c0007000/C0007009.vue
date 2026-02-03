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
import gridField from '@web/c0007000/js/C0007009.js';
import { RowState } from 'realgrid';

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
      viewGrid: null,
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
  created() {
    this.viewGrid = _.cloneDeep(gridField);
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.srchInfo.curProdCtg === 'VN' ? 'VINA' : '본사';

    this.$nextTick(() => {
      const gv = this.viewGridView;
      if (!gv) return;

      gv.onEditBegin = (grid, index) => {
        if (index.fieldName === '구분') {
          return false;
        }
      };
    });
  },
  activated() {
    this.reInitScreen();
  },
  methods: {
    initializeGrid() {
      this.modelGrid = _.cloneDeep(gridField);
    },    
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
      if (!this.viewGridView || !this.viewGridDataProvider) return;

      this.viewGridView.commit();

      this.viewGridDataProvider.addRow({
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        selCode: 'ACTUAL',
        siteOrg: this.siteMap[this.params.site] || this.params.site,
        site: this.params.site,
        구분: '',
        도우코드: '',
        rmaIn: null,
        rmaOut: null,
        생성자: this.userAuthInfo.userInfo.userName,
        생성시각: null,
      });

      let itemIndex = this.viewGridView.getItemCount() - 1;
      this.viewGridView.setCurrent({ itemIndex: itemIndex });
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

      if (fieldName === '도우코드') {
        if (itemIndex == null || itemIndex < 0) return;

        const rowState = this.viewGridDataProvider.getRowState(itemIndex);
        if (rowState !== 'created') {
          return;
        }

        if (grid.isEditing()) {
          try {
            grid.commit(true);
          } catch (e) {
            console.warn('⚠️ [onCellClickedViewGrid] commit 중 에러 → cancel()', e);
            try {
              grid.cancel();
            } catch (e2) {
              console.warn('⚠️ [onCellClickedViewGrid] cancel 실패', e2);
            }
          }
        }

        this.selectedRowIndex = itemIndex;
        this.selectedModel = '';

        this.openModelPopup();
      }
    },

    async deleteRmaData() {
      if (!this.viewGridView || !this.viewGridDataProvider) return;

      this.viewGridView.commit();
      const checkedRows = this.viewGridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 행을 선택하세요');
        return;
      }

      const deletedCount = checkedRows.length;
      
      this.$confirm('확인', `${deletedCount}건을 삭제하시겠습니까?`, async (confirmed) => {
        if (!confirmed) return;

        let newRows = [];
        let existingRows = [];
        
        checkedRows.forEach((itemIndex) => {
          if (this.viewGridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            newRows.push(itemIndex);
          } else {
            existingRows.push(this.viewGridDataProvider.getJsonRow(itemIndex));
          }
        });

        if (newRows.length > 0) {
          this.viewGridDataProvider.removeRows(newRows);
        }

        if (existingRows.length > 0) {
          try {
            let param = {
              menuId: 'c0007009',
              delete: [{ queryId: 'deleteRmaData', data: existingRows }],
            };
            await this.$axios.api.saveData(param);
            this.searchClick();
          } catch {
            this.$toast('error', '삭제 중 에러가 발생했습니다.');
            return;
          }
        }
        
        this.$toast('success', `${deletedCount}건이 삭제되었습니다.`);
      });
    },

    async updateRmaData() {
      if (!this.viewGridView || !this.viewGridDataProvider) return;

      this.viewGridView.commit();

      let saveData = this.$refs.viewGrid.getSaveData();

      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      
      const allRows = [...(saveData.insert || []), ...(saveData.update || [])];
      const emptyDowuCode = allRows.find(row => !row.도우코드 || row.도우코드.trim() === '');
      if (emptyDowuCode) {
        this.$toast('error', '도우코드가 선택되지 않았습니다.');
        return;
      }

      this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
        if (confirm) {
          let param = {
            menuId: 'c0007009',
            delete: [{ queryId: 'deleteRmaData', data: saveData.delete }],
            insert: [{ queryId: 'insertRmaData', data: saveData.insert }],
            update: [{ queryId: 'updateRmaData', data: saveData.update }],
          };

          try {
            let resp = await this.$axios.api.saveData(param);
            this.$toast('info', '저장완료');
            this.searchClick();
          } catch {
            this.$toast('info', '에러발생. 다시 작업해주세요.');
          }
        }
      });
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
    openModelPopup() {
      const siteCode = this.siteMap[this.params.site] || this.params.site;
      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;

      const queryParams = {
        yyyymm: yyyymm,
        site: siteCode,
      };

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
      const category = lastChar === 'P' ? '양산' : '개발';
      this.viewGridDataProvider.setValue(this.selectedRowIndex, '구분', category);

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