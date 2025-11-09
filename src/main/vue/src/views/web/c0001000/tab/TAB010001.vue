<!-- 기준정보 > 계정과목 관리 (TAB010001) -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <!--b-col cols="2">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.yyyy">
              <option v-for="yyyy in yearList" :key="yyyy.value" :value="yyyy">
                {{ yyyy.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">년도</label>
          </div>
        </b-col-->
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
            <label for="floatingSelect" class="select">기준월</label>
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
        <b-button @click="searchClick" onclick="console.log('TAB010001 onclick 이벤트 발생')"><span class="ico_search"></span>조회</b-button>
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
        <RealGrid ref="acctGrid" :uid="'acctGrid'" :step="'1'" :rows="acctGridRows" style="height: 100%" :fitLayoutWidthEnable="false"/>
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>
<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0001000/js/TAB010001.js';
import axios from 'axios';
export default {
  components: {},
  props: {
    yearList: {
      type: Array,
      default: () => []
    }
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { 
			srchInfo,
      userAuthInfo 
    };
  },
  data() {
    return {
      acctGrid: null,
      acctGridRows: [],
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
      duplicateKey: ['yyyy', 'selCode', 'site', 'acct'],
      isValidteCellAcctGrid: false,
    };
  },
  computed: {
    acctGridView() {
      return this.$refs.acctGrid && this.$refs.acctGrid.getGridView();
    },
    acctDataProvider() {
      return this.$refs.acctGrid && this.$refs.acctGrid.getGridDataProvider();
    }
  },
  watch: {
    // yearList: {
    //   handler(newList) {
    //     if (newList && newList.length > 0 && !this.params.yyyy) {
    //       this.params.yyyy = newList[0];
    //       // 그리드가 초기화된 후에 검색 실행
    //       this.$nextTick(() => {
    //         if (this.acctGridView) {
    //           this.getAcctList();
    //         }
    //       });
    //     }
    //   },
    //   immediate: true
    // },
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
  created() {
    console.log('[created] TAB010001 컴포넌트 생성됨');
    this.initializeGrid();
  },
  mounted() {
    console.log('[mounted] TAB010001 컴포넌트 마운트됨');
    console.log('[mounted] userAuthInfo:', this.userAuthInfo);
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    console.log('[mounted] site 설정:', this.params.site);
  },
  mounted() {
    // if (this.yearList && this.yearList.length > 0) {
    //   this.params.yyyy = this.yearList[0];
    // }
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(() => {
      this.getAcctList();
    });
  },
  methods: {
    // 한글 컬럼명을 영어 fieldName으로 매핑하는 함수
    mapDataFields(data) {
      if (!data || !Array.isArray(data)) return [];
      
      return data.map(item => ({
        ...item,
        // 한글 컬럼명을 영어 fieldName으로 매핑
        acctItnCode: item['계정과목내부코드'],
        acctIssued: item['전표기표여부'],
        debitCredit: item['차대'],
        largeAcct: item['계정대분류'],
        mngItemType: item['관리항목유형'],
        upperAcct: item['상위계정과목'],
        mplanAcct: item['경영계획과목'],
        upperAcctItnCode: item['상위계정과목내부코드'],
        smallClass: item['소분류'],
        midClass: item['중분류'],
        largeClass: item['대분류'],
        comment: item['특이사항']
      }));
    },
    
    async initializeGrid() {
      try {
        // 그리드 필드 복제
        this.acctGrid = _.cloneDeep(gridField);
        
        // 그리드 인스턴스 가져오기
        const grid = this.$refs.acctGrid;
        if (!grid) {
          console.error('Grid reference not found');
          return;
        }
        
        this.acctGridView = grid.getGridView();
        this.acctDataProvider = grid.getDataProvider();
        
        if (!this.acctGridView || !this.acctDataProvider) {
          console.error('Grid instances not initialized properly');
          return;
        }
        
        // 그리드 옵션 설정
        this.acctGridView.setOptions({
          display: {
            focusVisible: true,
            rowFocusVisible: true,
            emptyMessage: '데이터가 없습니다.'
          },
          edit: {
            enterToTab: true,
            enterToNextRow: true,
            skipReadOnly: true,
            editWhenFocused: true
          },
          select: {
            style: 'rows'
          }
        });
        
        // 키보드 핸들러 설정
        this.acctGridView.onKeyDown = (grid, key, ctrl, shift, alt) => {
          if (key === 9) { // TAB key
            const curr = grid.getCurrent();
            const fields = grid.getColumnNames();
            const fieldIndex = fields.indexOf(curr.fieldName);
            
            if (fieldIndex < fields.length - 1) {
              grid.setCurrent({
                itemIndex: curr.itemIndex,
                fieldName: fields[fieldIndex + 1]
              });
            } else if (curr.itemIndex < grid.getItemCount() - 1) {
              grid.setCurrent({
                itemIndex: curr.itemIndex + 1,
                fieldName: fields[0]
              });
            }
            return true;
          }
          return false;
        };
        
        // 데이터 변경 이벤트 핸들러
        this.acctDataProvider.onRowStateChanged = () => {
          this.acctGridView.refresh();
        };
        
        console.log('[initializeGrid] Grid initialized successfully');
      } catch (e) {
        console.error('[initializeGrid] Error:', e);
        this.$toast('error', '그리드 초기화 실패');
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getAcctList() {
      if (!this.acctGridView) return;
      this.acctGridView.commit();
      
      try {
        const param = {
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.siteMap[this.params.site] || this.params.site
        };

        // 파라미터 유효성 검사
        if (!param.yyyymm) {
          this.$toast && this.$toast('error', '년도를 선택해주세요.');
          return;
        }

        console.log('getAcctList 요청 파라미터:', param);
        
        const response = await this.$axios.post('/api/c0001000/c0001004/tab1/select', param);
        
        if (response.data) {
          // 데이터 매핑 적용
          const mappedData = this.mapDataFields(response.data);
          await this.acctDataProvider.setRows(mappedData);
          console.log('getAcctList 응답:', response.data);
          console.log('getAcctList 매핑된 데이터:', mappedData);
        } else {
          console.warn('응답에 데이터가 없습니다');
          await this.acctDataProvider.setRows([]);
        }
      } catch (error) {
        console.error('getAcctList 오류:', error);
        
        let errorMessage;
        if (error.response) {
          switch (error.response.status) {
            case 404:
              errorMessage = 'API를 찾을 수 없습니다. 백엔드 설정을 확인해주세요.';
              break;
            case 401:
              errorMessage = '인증이 필요합니다.';
              break;
            case 403:
              errorMessage = '접근 권한이 없습니다.';
              break;
            default:
              errorMessage = error.response.data?.message || '계정과목 조회에 실패했습니다.';
          }
        } else if (error.request) {
          errorMessage = '서버 응답이 없습니다. 네트워크 연결을 확인해주세요.';
        } else {
          errorMessage = '요청 설정 중 오류가 발생했습니다.';
        }

        this.$toast && this.$toast('error', errorMessage);
        await this.acctDataProvider.setRows([]);
      }
    },
    searchClick() {
      console.log('[searchClick] TAB010001 조회 버튼 클릭됨');
      console.log('[searchClick] params:', this.params);
      console.log('[searchClick] acctGridView:', this.acctGridView);
      console.log('[searchClick] acctDataProvider:', this.acctDataProvider);
      
      // 년도가 설정되지 않은 경우 경고
      if (!this.params.yyyymm) {
        this.$toast('error', '년월를 선택해주세요.');
        return;
      }
      this.getAcctList();
    },
    addBtnClick() {
      if (!this.acctGridView || !this.acctDataProvider) return;
      
      this.acctGridView.commit();
      
      const newRow = {
        yyyy: this.params.yyyy?.value || this.params.yyyy,
        site: this.siteMap[this.params.site] || this.params.site
      };
      
      this.acctDataProvider.addRow(newRow);
      
      const lastIndex = this.acctGridView.getItemCount() - 1;
      this.acctGridView.setCurrent({ 
        itemIndex: lastIndex,
        fieldName: 'acctName' 
      });
    },
    delBtnClick() {
      if (!this.acctGridView || !this.acctDataProvider) return;
      
      this.acctGridView.commit();
      
      const selectedItems = this.acctGridView.getSelectedItems();
      if (_.isEmpty(selectedItems)) {
        this.$toast('info', '선택된 정보가 없습니다.');
        return;
      }
      
      // 새로 추가된 행 처리
      const newItems = selectedItems.filter(itemIndex => 
        this.acctDataProvider.getRowState(itemIndex) === RowState.CREATED
      );
      if (newItems.length > 0) {
        this.acctDataProvider.removeRows(newItems);
      }
      
      // 기존 행 처리
      selectedItems.forEach(itemIndex => {
        const state = this.acctDataProvider.getRowState(itemIndex);
        if (state !== RowState.CREATED) {
          this.acctDataProvider.setRowState(itemIndex, RowState.DELETED);
        }
      });
    },
    async saveBtnClick() {
      if (!this.acctGridView || !this.acctDataProvider) return;
      
      try {
        this.acctGridView.commit();
        
        const saveData = this.$refs.acctGrid.getSaveData();
        const params = {
          menuId: 'C0001004',
          delete: [{ queryId: 'deleteAcct', data: saveData.delete }],
          insert: [{ queryId: 'insertAcct', data: saveData.insert }],
          update: [{ queryId: 'updateAcct', data: saveData.update }]
        };
        
        const response = await this.$axios.post('/api/c0001000/c0001004/tab1/save', params);
        
        if (response.data?.status === 'success') {
          this.acctDataProvider.clearRowStates();
          this.$toast('success', '저장되었습니다.');
          await this.getAcctList();
        } else {
          this.$toast('error', response.data?.message || '저장 실패');
        }
      } catch (error) {
        console.error('saveBtnClick 오류:', error);
        this.$toast('error', error.response?.data?.message || '저장 중 오류가 발생했습니다.');
      }
    },
    async excelBtnClick() {
      if (!this.acctGridView) return;
      
      try {
        this.acctGridView.commit();
        
        const response = await this.$axios({
          method: 'post',
          url: '/api/c0001000/tab010001/tab1/excel',
          responseType: 'blob',
          data: {
            yyyy: this.params.yyyy?.value || this.params.yyyy,
            site: this.siteMap[this.params.site] || this.params.site
          }
        });
        
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `계정과목_${new Date().getTime()}.xlsx`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      } catch (error) {
        console.error('excelBtnClick 오류:', error);
        this.$toast('error', '엑셀 다운로드에 실패했습니다.');
      }
    },
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0001000/TAB010001/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10'],
        excelGrid,
        fileName: '원가계정정보_template',
      });
    },
    closePopup() {
      this.$emit('close');
    },
  },
};
</script>