<!-- 기준정보 > 모델 관리 (TAB010004) -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
            <label for="floatingSelect" class="select">기준월</label>
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
        <b-button @click="searchClick"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <!-- <b-button class="second" @click="uploadClick">업로드</b-button> -->
          <b-button v-show="showItemApiButton" class="second" @click="itemApiCallClick">API 호출</b-button>
          <!-- 데이터 생성(GEN_DOI_MODEL_MAST)은 VN 미사용 → HQ 전용 노출. VN은 품목 API로 적재 -->
          <b-button v-show="!isClosedMonth && siteMap[params.site] !== 'VN'" class="second" @click="genData">데이터 생성</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button v-show="!isClosedMonth" class="sub" @click="addBtnClick">추가</b-button>
          <b-button v-show="!isClosedMonth" @click="delBtnClick">삭제</b-button>
          <b-button v-show="!isClosedMonth" class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="modelGrid" :uid="'modelGrid'" :step="'1'" :rows="modelGridRows" style="height: 100%" :fitLayoutWidthEnable="false" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>
<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0001000/js/TAB010004.js';
import axios from 'axios';
import ifaceApiMixin from '@/mixins/ifaceApiMixin.js';
export default {
  components: {},
  mixins: [ifaceApiMixin],
  props: {
    yearList: {
      type: Array,
      default: () => [],
    },
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { 
			srchInfo,
      userAuthInfo,
    };
  },
  data() {
    return {
      modelGrid: null,
      modelGridRows: [],
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
      isProcessing: false,
      duplicateKey: ['yyyymm', 'selCode', 'site', 'model'],
      isValidteCellModelGrid: false,
      isClosedMonth: false,
    };
  },
  computed: {
    gridView() {
      return this.$refs.modelGrid && this.$refs.modelGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.modelGrid && this.$refs.modelGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
    // 품목(ITEM) [API 호출] 버튼: SUPERADMIN 계정 + VN 전용(면적기준정보 원천 적재)
    showItemApiButton() {
      try {
        const roles = (this.userAuthInfo && this.userAuthInfo.roleList) || [];
        return roles.includes('SUPERADMIN') && this.siteMap[this.params.site] === 'VN';
      } catch (e) { return false; }
    },
  },
  watch: {
    'params.yyyymm': async function(newVal) {
      if (newVal) {
        this.onDateChange();
        await this.checkClosingMonth();
      } else {
        this.isClosedMonth = false;
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
        }
      }
     },
     prodCtg: {
      handler(newVal) {
        if (newVal) {
            this.params.site = newVal === 'VN' ? 'VINA' : '본사';
            if (this.$refs.modelGrid != null) {
              this.searchClick();
            }
          }
        },
      },
    },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      this.searchClick();
      this.calcXYForAddRows();
    });
  },
  methods: {
    // [SUPERADMIN·VN] 품목(ITEM) API 호출 → DOI_VN_IF_ITEM 적재 (면적기준 DOI_MODEL_MAST 원천).
    //   적재 직후 UP_VN_IF_XFORM_ITEM 자동 실행 → DOI_MODEL_MAST(X=장변, Y=단변, XY=면적) 반영.
    itemApiCallClick() {
      if (!this.params.yyyymm) { this.$toast && this.$toast('error', '기준월을 선택해주세요.'); return; }
      const site = this.siteMap[this.params.site];
      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      // 정의서(품목) 요청 샘플과 동일한 기본 필터로 호출.
      //  ⚠️ SMStatus는 반드시 '2001002'(품목상태=사용). 빈 값('')이면 상태코드 미매칭으로 0건 조회됨.
      //  ※ PAGE_NO/PAGE_SIZE 미지정(넣으면 ERP가 전량·부가정보 생략 경로). 부가정보 포함 요청은 영림원 정상 샘플 재현.
      //  장변/단변(CMF ITEM_CMF_11/12)은 응답 DataBlock4 {RowIDX,ColIDX,AddInfoName}로 옴 → 로더 적재 후
      //  UP_VN_IF_XFORM_ITEM 이 DOI_MODEL_MAST(X/Y/XY)에 자동 반영. yyyymm은 면적기준 기준월.
      //  ※ TitleSerl은 필터(값 지정 시 마스터까지 0건) — 넣지 말 것.
      this.callIface({
        key: 'ITEM',
        yyyymm: yyyymm,
        params: {
          // 영림원 정상 요청 샘플(531건, 부가정보 DataBlock4 포함) 재현 — 필드 구성을 그대로 맞춤.
          //  ⚠️ PAGE_NO/PAGE_SIZE를 넣으면 ERP가 전량(4,908건)·부가정보 생략 경로로 감 → 넣지 말 것.
          //  ⚠️ SMStatus='2001002'(사용) 필수, SMStatusName은 빈값. TitleSerl/InPutType 등은 빈값(값 지정 시 필터로 동작).
          Result: '', ROW_IDX: '', IsChangedMst: '0',
          ItemName: '', AssetSeq: '', AssetName: '',
          UMItemClass: '', UMItemClassName: '',
          UMEtcItemClass: '', UMEtcItemClassName: '', UMEtcItemClassValue: '', UMEtcItemClassValueName: '',
          IsSTDItem: '0', ItemSeq: '', ItemNo: '', Spec: '',
          SMStatus: '2001002', SMStatusName: '',
          IsSet: '0',
          RegDateFr: '', RegDateTo: '', RegUserSeq: '', RegUser: '', EmpSeq: '', DeptSeq: '',
          UMItemClassL: '', UMItemClassLName: '', UMItemClassM: '', UMItemClassMName: '',
          InPutType: '', TitleSerl: '',
          AddText1: '', AddText2: '', AddText3: '', AddText4: '', AddText5: '', AddText6: '0', AddText7: '',
          AddCd3: '', AddCd5: '',
          site,
        },
        successLabel: '품목',
      });
    },
    initializeGrid() {
      this.modelGrid = _.cloneDeep(gridField);
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm
        ? this.params.yyyymm.replaceAll('-', '')
        : null;

      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }

      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: { yyyymm },
        });

        this.isClosedMonth =
          res?.data?.isClosed === true || res?.data?.isClosed === 'Y';

      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      if (!this.gridView) return;

      this.gridView.commit();
      
      let params = {
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.siteMap[this.params.site],
        };

        let param = {
          menuId: 'c0001004',
          queryId: 'selectTab4GridData',
          queryParams: params,
          target: this.modelGridRows,
        };
        let resp = await this.$axios.api.search(param);
      },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해 주세요.');
        return;
      }
      this.getDataList();
    },
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();

      this.gridDataProvider.addRow({
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site,
        selCode: 'ACTUAL',
        addYn: 'Y',
        xy: null
      });

      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex });
    },
    calcXYForAddRows() {
      if (!this.gridDataProvider) return;

      let syncing = false;

      this.gridDataProvider.onValueChanged = (provider, dataRow, fieldName) => {
        if (syncing) return;
        if (fieldName !== 'x' && fieldName !== 'y') return;

        // 신규 행 xy 계산
        const addYn = provider.getValue(dataRow, 'addYn');
        if (addYn !== 'Y') return;

        const x = this.normalizeNumber(provider.getValue(dataRow, 'x'));
        const y = this.normalizeNumber(provider.getValue(dataRow, 'y'));

        syncing = true;
        provider.setValue(dataRow, 'xy', (x != null && y != null) ? (x * y) : null);
        syncing = false;
      };
    },
    normalizeNumber(v) {
      if (v === '' || v === undefined || v === null) return null;
      const n = Number(String(v).replaceAll(',', ''));
      return Number.isFinite(n) ? n : null;
    },
    applyXY(rows) {
      if (!rows || rows.length === 0) return;

      rows.forEach(r => {
        r.x = this.normalizeNumber(r.x);
        r.y = this.normalizeNumber(r.y);

        r.xy = (r.x != null && r.y != null) ? (r.x * r.y) : null;
        
        if (!r.addYn) r.addYn = 'Y';
      });
    },
    delBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
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
          if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            newRows.push(itemIndex);
          } else {
            existingRows.push(this.gridDataProvider.getJsonRow(itemIndex));
          }
        });

        if (newRows.length > 0) {
          this.gridDataProvider.removeRows(newRows);
        }

        if (existingRows.length > 0) {
          try {
            let param = {
              menuId: 'c0001004',
              delete: [{ queryId: 'deleteTab1Data', data: existingRows }],
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
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();

      let saveData = this.$refs.modelGrid.getSaveData();

      this.applyXY(saveData.insert);
      this.applyXY(saveData.update);

      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidteCellModelGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellModelGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0001004',
              delete: [{ queryId: 'deleteTab4Data', data: saveData.delete }],
              insert: [{ queryId: 'insertTab4Data', data: saveData.insert }],
              update: [{ queryId: 'updateTab4Data', data: saveData.update }],
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
      }
    },
    onValidateColumnModelGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidteCellModelGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'model'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'model'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
      }

      return error;
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `면적기준정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
    // uploadClick() {
    //   let excelGrid = _.cloneDeep(gridField);
    //   excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
    //   this.$refs.uploadPopup1.openDialog({
    //     dialogTitle: '업로드 팝업',
    //     uploadApi: '/api/c0001000/c0001004/tab4Upload',
    //     headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15'],
    //     excelGrid,
    //     fileName: '면적기준정보_template',
    //   });
    // },
    closePopup() {
      this.searchClick();
    },
    async genData() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해 주세요.');
        return;
      }

      try {
        // 기존 데이터 확인
        let checkParams = {
          yyyymm: this.params.yyyymm.replaceAll('-', ''),
          site: this.siteMap[this.params.site],
        };

        let checkResp = await this.$axios.post('/api/c0001000/c0001004/checkExistingData', checkParams);
        
        if (checkResp.data && checkResp.data.exists) {
          this.$confirm('데이터 생성', '해당월 데이터가 존재합니다. 기존 데이터를 삭제하시겠습니까?', async (confirm) => {
            if (confirm) {
              this.$toast && this.$toast('info', '데이터를 생성 중입니다.');

              this.modelGridRows = [];

              await this.executeGenProcedure(checkParams);
            }
          });
        } else {
          await this.executeGenProcedure(checkParams);
        }
      } catch (error) {
        this.$toast && this.$toast('error', '데이터 생성 중 오류가 발생했습니다.');
        console.error(error);
      }
    },
    async executeGenProcedure(params) {
      try {
        let procParams = {
          yyyymm: params.yyyymm,
          site: params.site,
        };

        let resp = await this.$axios.post('/api/c0001000/c0001004/genModelMast', procParams);
        
        console.log('프로시저 응답:', resp.data);
        
        if (resp.data && resp.data.success) {
          // 데이터 생성 후 안정화 시간 대기
          await new Promise(resolve => setTimeout(resolve, 1500));
          // 데이터 조회
          this.searchClick();
          this.$toast && this.$toast('info', '데이터 생성이 완료되었습니다.');
        } else {
          const errorMsg = resp.data?.message || '데이터 생성에 실패했습니다.';
          this.$toast && this.$toast('error', errorMsg);
          console.error('프로시저 실행 실패:', resp.data);
        }
      } catch (error) {
        this.$toast && this.$toast('error', '프로시저 실행 중 오류가 발생했습니다: ' + error.message);
        console.error('프로시저 호출 에러:', error);
      }
    },
  },
};
</script>
