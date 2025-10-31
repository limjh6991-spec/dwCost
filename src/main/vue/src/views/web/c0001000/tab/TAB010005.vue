<!-- 기준정보 > 모델 관리 (TAB010005) -->
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
        <b-button @click="searchClick" onclick="console.log('TAB010005 onclick 이벤트 발생')"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="modelGrid" :uid="'modelGrid'" :step="'1'" :rows="modelGridRows" style="height: 100%" />
      </div>
    </div>
  </div>
</template>
<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import gridField from '@web/c0001000/js/TAB010005.js';
export default {
  components: {},
  props: {
    yearList: {
      type: Array,
      default: () => []
    }
  },
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      modelGrid: null,
      modelGridRows: [],
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
      duplicateKey: ['yyyy', 'selCode', 'site', 'model'],
      isValidteCellModelGrid: false,
    };
  },
  computed: {
    modelGridView() {
      return this.$refs.modelGrid && this.$refs.modelGrid.getGridView();
    },
    modelDataProvider() {
      return this.$refs.modelGrid && this.$refs.modelGrid.getGridDataProvider();
    }
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    if (this.yearList && this.yearList.length > 0) {
      this.params.yyyy = this.yearList[0];
    }
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(() => {
      this.getModelList();
    });
  },
  watch: {
    userAuthInfo: {
      handler(newVal) {
        if (newVal) {
          if (newVal.curProdCtg) {
            this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
            if (this.$refs.modelGrid != null) {
              this.getModelList();
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
      this.modelGrid = _.cloneDeep(gridField);
    },
      async getModelList() {
      if (!this.modelGridView) return;
      this.modelGridView.commit();
      
      try {
        const param = {
          yyyy: this.params.yyyy?.value || this.params.yyyy,
          site: this.siteMap[this.params.site] || this.params.site
        };

        // 파라미터 유효성 검사
        if (!param.yyyy) {
          this.$toast && this.$toast('error', '년도를 선택해주세요.');
          return;
        }

        console.log('getModelList 요청 파라미터:', param);
        
        const response = await this.$axios.post('/api/c0001000/c0001004/tab5/select', param);
        
        if (response.data) {
          await this.modelDataProvider.setRows(response.data);
          console.log('getModelList 응답:', response.data);
        } else {
          console.warn('응답에 데이터가 없습니다');
          await this.modelDataProvider.setRows([]);
        }
      } catch (error) {
        console.error('getModelList 오류:', error);
        
        let errorMessage;
        if (error.response) {
          // 서버 응답이 있는 경우
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
              errorMessage = error.response.data?.message || '면적기준정보 조회에 실패했습니다.';
          }
        } else if (error.request) {
          // 요청은 보냈지만 응답이 없는 경우
          errorMessage = '서버 응답이 없습니다. 네트워크 연결을 확인해주세요.';
        } else {
          // 요청 설정 중 오류 발생
          errorMessage = '요청 설정 중 오류가 발생했습니다.';
        }

        this.$toast && this.$toast('error', errorMessage);
        await this.modelDataProvider.setRows([]);
      }
    },
    searchClick() {
      console.log('[searchClick] TAB010005 조회 버튼 클릭됨');
      console.log('[searchClick] params:', this.params);
      console.log('[searchClick] modelGridView:', this.modelGridView);
      console.log('[searchClick] modelDataProvider:', this.modelDataProvider);
      this.getModelList();
    },
    excelBtnClick() {},
  },
};
</script>
