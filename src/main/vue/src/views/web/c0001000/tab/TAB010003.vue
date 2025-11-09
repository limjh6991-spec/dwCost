<!-- 기준정보 > 자재코드 -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <div class="form-floating me-1">
              <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
              <label for="floatingSelect" class="select">기준월</label>
            </div>
          </div>
        </b-col>
        <b-col cols="2">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" :disabled="true" />
            <label for="floating">사업장</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick" onclick="console.log('TAB010003 onclick 이벤트 발생')"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="materialGrid" :uid="'materialGrid'" :step="'1'" :rows="materialGridRows" style="height: 100%" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>
<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import UploadPopup from '@components/UploadPopup.vue';
import gridField from '@web/c0001000/js/TAB010003.js';


export default {
  components: { UploadPopup },
  setup() {
    const srchInfo = useC0001001();
    console.log(srchInfo.yyyymm);
    const userAuthInfo = useUserAuthInfo();
    return { 
			srchInfo,
      userAuthInfo 
    };
  },
  data() {
    return {
      materialGrid: null,
      materialGridRows: [],
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
      duplicateKey: ['yyyymm', 'site', 'matCode'],
      isValidteCellMaterialGrid: false,
    };
  },
  computed: {
    materialGridView() {
      const gridView = this.$refs.materialGrid && this.$refs.materialGrid.getGridView();
      console.log('[computed] materialGridView:', gridView);
      return gridView;
    },
    materialDataProvider() {
      const dataProvider = this.$refs.materialGrid && this.$refs.materialGrid.getGridDataProvider();
      console.log('[computed] materialDataProvider:', dataProvider);
      return dataProvider;
    }
  },
  created() {
    console.log('[created] TAB010003 컴포넌트 생성됨');
    // 기준월을 현재 월로 초기화
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    this.params.yyyymm = this.srchInfo.yyyymm; //`${year}-${month}`;
    console.log('[created] 기준월 초기화:', this.params.yyyymm);
    
    this.initializeGrid();
  },
  mounted() {
    console.log('[mounted] TAB010003 마운트됨');
    console.log('[mounted] userAuthInfo:', this.userAuthInfo);
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    console.log('[mounted] site 설정:', this.params.site);
    this.$nextTick(() => {
      console.log('[mounted] $nextTick에서 getMaterialList 호출');
      this.getMaterialList();
    });
  },
  watch: {
    'params.yyyymm': function(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
          console.log('[C0003007] yyyymm 변경:', this.params.yyyymm);
        }
      }
     },
    userAuthInfo: {
      handler(newVal) {
        if (newVal) {
          if (newVal.curProdCtg) {
            this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
            if (this.$refs.acctGrid != null) {
              this.getAcctList();
            }
          }
        }
      },
    }
  },
  methods: {
    // 한글 컬럼명을 영어 fieldName으로 매핑하는 함수
    mapDataFields(data) {
      if (!data || !Array.isArray(data)) return [];
      
      return data.map(item => ({
        ...item,
        // 한글 컬럼명을 영어 fieldName으로 매핑
        prodName: item['제품명'],
        prodCode: item['제품번호'],
        prodInventoryClass: item['품목자산분류'],
        prodLargeClass: item['품목대분류'],
        prodMidClass: item['품목중분류'],
        prodSmallClass: item['품목소분류'],
        processSeq: item['공정차수'],
        process: item['공정'],
        processMatName: item['공정품명'],
        processMatCode: item['공정품번호'],
        matName: item['자재명'],
        matCode: item['자재번호'],
        matInventoryClass: item['자재자산분류'],
        matLargeClass: item['자재대분류'],
        matMidClass: item['자재중분류'],
        matSmallClass: item['자재소분류'],
        inputUnit: item['투입단위'],
        reqQty: item['소요량'],
        inLossRate: item['내부Loss율'],
        outLossRate: item['외부Loss율'],
        assyLoc: item['조립위치'],
        etc: item['특이사항'],
        firstRegDate: item['최초작성일'],
        firstRegId: item['최초작성자'],
        lastModDate: item['최종수정일'],
        lastModId: item['최종수정자']
      }));
    },
    
    initializeGrid() {
      this.materialGrid = _.cloneDeep(gridField);
    },
    
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    
    async getMaterialList() {
      if (!this.materialGridView) return;
      this.materialGridView.commit();
      
      try {
        // yyyymm 값 처리 (YYYY-MM 형태를 YYYYMM으로 변환)
        let yyyymm = this.params.yyyymm;
        if (yyyymm && yyyymm.includes('-')) {
          yyyymm = yyyymm.replace('-', '');
        }
        
        const param = {
          yyyymm: yyyymm,
          site: this.siteMap[this.params.site] || this.params.site
        };

        // 파라미터 유효성 검사
        if (!param.yyyymm) {
          this.$toast('error', '기준월을 선택해주세요.');
          return;
        }

        console.log('[getMaterialList] 요청 파라미터:', param);
        
        const response = await this.$axios.post('/api/c0001000/c0001004/tab3/select', param);
        
        if (response.data) {
          // 데이터 매핑 적용
          const mappedData = this.mapDataFields(response.data);
          await this.materialDataProvider.setRows(mappedData);
          console.log('[getMaterialList] 응답:', response.data);
          console.log('[getMaterialList] 매핑된 데이터:', mappedData);
        } else {
          console.warn('[getMaterialList] 응답에 데이터가 없습니다');
          await this.materialDataProvider.setRows([]);
          this.$toast('info', '조회된 데이터가 없습니다.');
        }
      } catch (error) {
        console.error('[getMaterialList] 오류:', error);
        let errorMessage = 'BOM 조회에 실패했습니다.';
        
        if (error.response?.status) {
          switch (error.response.status) {
            case 404: errorMessage = 'API를 찾을 수 없습니다.'; break;
            case 401: errorMessage = '인증이 필요합니다.'; break;
            case 403: errorMessage = '접근 권한이 없습니다.'; break;
            default: errorMessage = error.response.data?.message || errorMessage;
          }
        } else if (error.request) {
          errorMessage = '서버 응답이 없습니다. 네트워크 연결을 확인해주세요.';
        }
        
        this.$toast('error', errorMessage);
        await this.materialDataProvider.setRows([]);
      }
    },
    
    searchClick() {
      console.log('[searchClick] 조회 버튼 클릭됨');
      console.log('[searchClick] params:', this.params);
      console.log('[searchClick] materialGridView:', this.materialGridView);
      console.log('[searchClick] materialDataProvider:', this.materialDataProvider);
      this.getMaterialList();
    },
    
    addBtnClick() {
      if (!this.materialGridView || !this.materialDataProvider) return;
      
      this.materialGridView.commit();
      
      // yyyymm 값 처리 (YYYY-MM 형태를 YYYYMM으로 변환)
      let yyyymm = this.params.yyyymm;
      if (yyyymm && yyyymm.includes('-')) {
        yyyymm = yyyymm.replace('-', '');
      }
      
      const newRow = {
        yyyymm: yyyymm,
        site: this.siteMap[this.params.site] || this.params.site
      };
      
      this.materialDataProvider.addRow(newRow);
      
      const lastIndex = this.materialGridView.getItemCount() - 1;
      this.materialGridView.setCurrent({ 
        itemIndex: lastIndex,
        fieldName: 'matCode' 
      });
    },
    
    delBtnClick() {
      if (!this.materialGridView || !this.materialDataProvider) return;
      
      this.materialGridView.commit();
      
      const selectedItems = this.materialGridView.getSelectedItems();
      if (_.isEmpty(selectedItems)) {
        this.$toast('info', '선택된 정보가 없습니다.');
        return;
      }
      
      // 새로 추가된 행 처리
      const newItems = selectedItems.filter(itemIndex => 
        this.materialDataProvider.getRowState(itemIndex) === RowState.CREATED
      );
      if (newItems.length > 0) {
        this.materialDataProvider.removeRows(newItems);
      }
      
      // 기존 행 처리
      selectedItems.forEach(itemIndex => {
        const state = this.materialDataProvider.getRowState(itemIndex);
        if (state !== RowState.CREATED) {
          this.materialDataProvider.setRowState(itemIndex, RowState.DELETED);
        }
      });
    },
    
    async saveBtnClick() {
      if (!this.materialGridView || !this.materialDataProvider) return;
      
      try {
        this.materialGridView.commit();
        
        const saveData = this.$refs.materialGrid.getSaveData();
        const params = {
          menuId: 'C0001004',
          delete: [{ queryId: 'deleteMaterial', data: saveData.delete }],
          insert: [{ queryId: 'insertMaterial', data: saveData.insert }],
          update: [{ queryId: 'updateMaterial', data: saveData.update }]
        };
        
        const response = await this.$axios.post('/api/c0001000/c0001004/tab3/save', params);
        
        if (response.data?.status === 'success') {
          this.materialDataProvider.clearRowStates();
          this.$toast('success', '저장되었습니다.');
          await this.getMaterialList();
        } else {
          this.$toast('error', response.data?.message || '저장 실패');
        }
      } catch (error) {
        console.error('saveBtnClick 오류:', error);
        this.$toast('error', error.response?.data?.message || '저장 중 오류가 발생했습니다.');
      }
    },
    
    async excelBtnClick() {
      if (!this.materialGridView) return;
      
      try {
        this.materialGridView.commit();
        
        // yyyymm 값 처리 (YYYY-MM 형태를 YYYYMM으로 변환)
        let yyyymm = this.params.yyyymm;
        if (yyyymm && yyyymm.includes('-')) {
          yyyymm = yyyymm.replace('-', '');
        }
        
        const response = await this.$axios({
          method: 'post',
          url: '/api/c0001000/c0001004/tab3/excel',
          responseType: 'blob',
          data: {
            yyyymm: yyyymm,
            site: this.siteMap[this.params.site] || this.params.site
          }
        });
        
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `BOM_${new Date().getTime()}.xlsx`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      } catch (error) {
        console.error('excelBtnClick 오류:', error);
        this.$toast('error', '엑셀 다운로드에 실패했습니다.');
      }
    },
    
    uploadClick() {
      console.warn('[uploadClick] 구현 예정');
    },
    
    closePopup() {
      this.$emit('close');
    },
  },
};
</script>