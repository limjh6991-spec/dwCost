<!-- 기준정보 > 부서 관리 (TAB010002) -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.yyyy">
              <option v-for="yyyy in yearList" :key="yyyy.value" :value="yyyy">
                {{ yyyy.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">년도</label>
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
        <b-button @click="searchClick" onclick="console.log('TAB010002 onclick 이벤트 발생')"><span class="ico_search"></span>조회</b-button>
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
        <RealGrid 
          ref="deptGrid" 
          :uid="'deptGrid'" 
          :step="'1'" 
          :rows="deptGridRows" 
          style="height: 100%"
          @created="onGridCreated"
          @destroyed="onGridDestroyed"
        />
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
import gridField from '@web/c0001000/js/TAB010002.js';
export default {
  components: { UploadPopup },
  props: {
    yearList: {
      type: Array,
      default: () => []
    }
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      deptGrid: null,
      deptGridRows: [],
      params: {
        yyyy: null,
        site: 'HQ',
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      isProcessing: false,
      duplicateKey: ['yyyy', 'selCode', 'site', 'dept'],
      isValidteCellDeptGrid: false,
    };
  },
  computed: {
    deptGridView() {
      const gridView = this.$refs.deptGrid && this.$refs.deptGrid.getGridView();
      console.log('[computed] deptGridView:', gridView);
      return gridView;
    },
    deptDataProvider() {
      const dataProvider = this.$refs.deptGrid && this.$refs.deptGrid.getGridDataProvider();
      console.log('[computed] deptDataProvider:', dataProvider);
      return dataProvider;
    }
  },
  created() {
    console.log('[created] TAB010002 컴포넌트 생성됨');
    this.initializeGrid();
  },
  mounted() {
    console.log('[mounted] TAB010002 컴포넌트 마운트됨');
    console.log('[mounted] yearList:', this.yearList);
    console.log('[mounted] userAuthInfo:', this.userAuthInfo);
    
    if (this.yearList && this.yearList.length > 0) {
      this.params.yyyy = this.yearList[0];
      console.log('[mounted] yyyy 설정:', this.params.yyyy);
    }
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    console.log('[mounted] site 설정:', this.params.site);
    
    this.$nextTick(() => {
      console.log('[mounted] $nextTick에서 getDeptList 호출');
      this.getDeptList();
    });
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal) {
          if (newVal.curProdCtg) {
            this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
            if (this.$refs.deptGrid != null) {
              this.getDeptList();
            }
          }
        }
      },
      deep: true,
      immediate: true
    }
  },
  methods: {
    initializeGrid() {
      console.log('[initializeGrid] TAB010002 그리드 초기화 시작');
      this.deptGrid = _.cloneDeep(gridField);
      console.log('[initializeGrid] TAB010002 그리드 초기화 완료');
    },
    async getDeptList() {
      if (!this.deptGridView) return;
      this.deptGridView.commit();
      
      try {
        const param = {
          yyyy: this.params.yyyy?.value || this.params.yyyy,
          site: this.siteMap[this.params.site] || this.params.site
        };

        if (!param.yyyy) {
          this.$toast('error', '연도를 선택해주세요.');
          return;
        }

        console.log('[getDeptList] 요청 파라미터:', param);
        
        const response = await this.$axios.post('/api/c0001000/c0001004/tab2/select', param);
        
        if (response.data) {
          await this.deptDataProvider.setRows(response.data);
          console.log('[getDeptList] 응답:', response.data);
        } else {
          console.warn('[getDeptList] 응답에 데이터가 없습니다');
          await this.deptDataProvider.setRows([]);
          this.$toast('info', '조회된 데이터가 없습니다.');
        }
      } catch (error) {
        console.error('[getDeptList] 오류:', error);
        let errorMessage = '부서 조회에 실패했습니다.';
        
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
        await this.deptDataProvider.setRows([]);
      }
    },
    searchClick() {
      console.log('[searchClick] TAB010002 조회 버튼 클릭됨');
      console.log('[searchClick] params:', this.params);
      console.log('[searchClick] deptGridView:', this.deptGridView);
      console.log('[searchClick] deptDataProvider:', this.deptDataProvider);
      
      if (this.isProcessing) {
        console.warn('[searchClick] 이전 요청 처리 중...');
        return;
      }
      this.getDeptList();
    },
    addBtnClick() {
      if (!this.deptGridView || !this.deptDataProvider) {
        console.warn('[addBtnClick] Grid 인스턴스가 없습니다.');
        return;
      }

      try {
        // 현재 편집 중인 내용 커밋
        this.deptGridView.commit();
        
        // 새 행 추가
        this.deptDataProvider.addRow({
          yyyy: this.params.yyyy?.value || this.params.yyyy,
          site: this.siteMap[this.params.site] || this.params.site
        });
        
        // 마지막 행으로 이동하고 부서명 필드 선택
        const lastIndex = this.deptGridView.getItemCount() - 1;
        this.deptGridView.setCurrent({
          itemIndex: lastIndex,
          fieldName: 'deptName'
        });
      } catch (e) {
        console.error('[addBtnClick] Error:', e);
        this.$toast('error', '새 행 추가 실패');
      }
    },
    delBtnClick() {
      if (!this.deptGridView || !this.deptDataProvider) {
        console.warn('[delBtnClick] Grid 인스턴스가 없습니다.');
        return;
      }

      try {
        // 현재 편집 중인 내용 커밋
        this.deptGridView.commit();
        
        // 선택된 항목 가져오기
        const selectedItems = this.deptGridView.getSelectedItems();
        if (_.isEmpty(selectedItems)) {
          this.$toast('info', '선택된 정보가 없습니다.');
          return;
        }

        // 새로 추가된 행 중 선택된 것들 완전히 제거
        const newItemsToDelete = selectedItems.filter(itemIndex => 
          this.deptDataProvider.getRowState(itemIndex) === RowState.CREATED
        );
        if (newItemsToDelete.length > 0) {
          this.deptDataProvider.removeRows(newItemsToDelete);
        }

        // 기존 행들은 삭제 상태로 변경
        selectedItems.forEach(itemIndex => {
          const rowState = this.deptDataProvider.getRowState(itemIndex);
          if (rowState !== RowState.CREATED) {
            this.deptDataProvider.setRowState(itemIndex, RowState.DELETED);
          }
        });
      } catch (e) {
        console.error('[delBtnClick] Error:', e);
        this.$toast('error', '행 삭제 실패');
      }
    },
    async saveBtnClick() {
      if (!this.deptGridView || !this.deptDataProvider) {
        console.warn('[saveBtnClick] Grid 인스턴스가 없습니다.');
        return;
      }

      // 중복 저장 방지
      if (this.isProcessing) {
        console.warn('[saveBtnClick] 이전 요청 처리 중...');
        return;
      }

      try {
        this.isProcessing = true;
        this.deptGridView.showLoading();

        // 현재 편집 중인 내용 커밋
        this.deptGridView.commit();
        
        // 저장할 데이터 수집
        const saveData = this.$refs.deptGrid.getSaveData();
        const params = {
          menuId: 'C0001004',
          delete: [{ queryId: 'deleteDept', data: saveData.delete }],
          insert: [{ queryId: 'insertDept', data: saveData.insert }],
          update: [{ queryId: 'updateDept', data: saveData.update }]
        };

        console.log('[saveBtnClick] 저장 요청 데이터:', {
          delete: saveData.delete.length,
          insert: saveData.insert.length,
          update: saveData.update.length
        });

        // 저장 API 호출
        const response = await this.$axios.post('/api/c0001000/c0001004/tab2/save', params);
        
        if (response.data?.status === 'success') {
          this.deptDataProvider.clearRowStates();
          this.$toast('success', '저장되었습니다.');
          // 저장 후 데이터 재조회
          await this.getDeptList();
        } else {
          this.$toast('error', response.data?.message || '저장 실패');
        }
      } catch (e) {
        console.error('[saveBtnClick] Error:', e);
        this.$toast('error', e?.response?.data?.message || '저장 실패');
      } finally {
        this.isProcessing = false;
        if (this.deptGridView) {
          this.deptGridView.hideLoading();
        }
      }
    },
    uploadClick() {
      // 업로드 기능은 추후 구현
      console.warn('[uploadClick] 구현 예정');
    },
    
    async excelBtnClick() {
      if (!this.deptGridView) return;
      
      try {
        this.deptGridView.commit();
        
        const response = await this.$axios({
          method: 'post',
          url: '/api/c0001000/c0001004/tab2/excel',
          responseType: 'blob',
          data: {
            yyyy: this.params.yyyy?.value || this.params.yyyy,
            site: this.siteMap[this.params.site] || this.params.site
          }
        });
        
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `부서_${new Date().getTime()}.xlsx`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      } catch (error) {
        console.error('[excelBtnClick] 오류:', error);
        this.$toast('error', '엑셀 다운로드에 실패했습니다.');
      }
    },
    
    closePopup() {
      this.$emit('close');
    },
  },
};
</script>
