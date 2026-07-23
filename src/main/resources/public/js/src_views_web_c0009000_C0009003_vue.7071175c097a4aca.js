(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0009000_C0009003_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009003.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009003.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0009000_js_C0009003_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0009000/js/C0009003.js */ "./src/views/web/c0009000/js/C0009003.js");
/* harmony import */ var _web_c0009000_js_C0009003_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0009000_js_C0009003_js__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var _utils_gridUtils__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @/utils/gridUtils */ "./src/utils/gridUtils.js");
/* harmony import */ var _web_c0007000_js_currencyConvert_js__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! @web/c0007000/js/currencyConvert.js */ "./src/views/web/c0007000/js/currencyConvert.js");
/* harmony import */ var _components_ExchangeRatePopup_vue__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! @/components/ExchangeRatePopup.vue */ "./src/components/ExchangeRatePopup.vue");






/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
  mixins: [_web_c0007000_js_currencyConvert_js__WEBPACK_IMPORTED_MODULE_4__["default"]],
  components: {
    ExchangeRatePopup: _components_ExchangeRatePopup_vue__WEBPACK_IMPORTED_MODULE_5__["default"]
  },
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      salesDataGrid: null,
      salesDataGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ'
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      }
    };
  },
  watch: {
    'params.yyyymm': function (newVal) {
      if (newVal) {
        this.onDateChange();
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
          if (this.$refs.salesDataGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      }
    }
  },
  computed: {
    gridView() {
      return this.$refs.salesDataGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.salesDataGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {
    const gv = this.gridView;
    if (this.salesDataGrid.columnLayout) {
      gv.setColumnLayout(this.salesDataGrid.columnLayout);
    }
  },
  beforeUnmount() {},
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.salesDataGrid = _.cloneDeep((_web_c0009000_js_C0009003_js__WEBPACK_IMPORTED_MODULE_2___default()));
      this.currencyFields = (_web_c0009000_js_C0009003_js__WEBPACK_IMPORTED_MODULE_2___default().currencyFields) || [];
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      this.gridView.commit();

      // VINA(USD): 금액 컬럼 소수점 2자리 표시 (본사는 정수 유지)
      (0,_utils_gridUtils__WEBPACK_IMPORTED_MODULE_3__.applyAmtFormat)(this.gridView, this.salesDataGrid.columns, this.userAuthInfo.curProdCtg, this.currency);
      let params = {
        yyyy: this.params.yyyymm.substring(0, 4),
        site: this.params.site != null ? this.siteMap[this.params.site] : null
      };
      const rows = [];
      let param = {
        menuId: 'c0009000',
        queryId: 'C0009003_Sch1',
        queryParams: params,
        target: rows
      };
      let resp = await this.$axios.api.search(param);
      let baseRows = rows;
      if (resp && resp.data) {
        baseRows = Array.isArray(resp.data) ? resp.data : resp.data.rows || rows;
      } else if (Array.isArray(resp)) {
        baseRows = resp;
      }
      // 선택 통화(KRW/VND)면 월평균 환율로 금액만 환산 표시 (수량 제외)
      const displayRows = await this.buildCurrencyRows(baseRows);
      this.salesDataGridRows = displayRows;
    },
    searchClick() {
      this.getDataList();
    },
    onCurrencyChange(currency) {
      this.setCurrency(currency);
      this.searchClick();
    },
    openExchangeRate() {
      this.$refs.exchangeRatePopup.openDialog({
        yyyymm: this.params.yyyymm
      });
    },
    onExchangeRateClosed() {
      if (this.isCurrencyReadonly) this.searchClick();
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `판매 실적 집계_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        }
      };
      grid.exportGrid(options);
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009003.vue?vue&type=template&id=29528aad":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009003.vue?vue&type=template&id=29528aad ***!
  \******************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

const _hoisted_1 = {
  class: "search_box"
};
const _hoisted_2 = {
  class: "form-floating me-1"
};
const _hoisted_3 = {
  class: "form-floating"
};
const _hoisted_4 = {
  class: "form-floating"
};
const _hoisted_5 = ["value"];
const _hoisted_6 = {
  class: "form-floating"
};
const _hoisted_7 = ["value"];
const _hoisted_8 = {
  class: "ms-2 text-primary",
  style: {
    "font-size": "12px"
  }
};
const _hoisted_9 = {
  class: "btn_area"
};
const _hoisted_10 = {
  class: "grid_box search_onerow"
};
const _hoisted_11 = {
  class: "left_box"
};
const _hoisted_12 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_13 = {
  class: "grid-border-none"
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_date_picker = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("date-picker");
  const _component_b_col = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-col");
  const _component_b_button = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-button");
  const _component_b_row = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-row");
  const _component_RealGrid = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("RealGrid");
  const _component_ExchangeRatePopup = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("ExchangeRatePopup");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_1, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_row, {
    class: "search_area"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "1",
      class: "period"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        label: "연도",
        mode: "year",
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event)
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[3] || (_cache[3] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelect",
        class: "select"
      }, "년도", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_3, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("input", {
        autocomplete: "off",
        type: "text",
        class: "form-control label-60",
        id: "floating",
        placeholder: "Site",
        "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => $data.params.site = $event),
        disabled: true
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[4] || (_cache[4] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), _ctx.showCurrencySelect ? ((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createBlock)(_component_b_col, {
      key: 0,
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("select", {
        class: "form-select label-60",
        id: "currencySelect",
        value: _ctx.currency,
        onChange: _cache[2] || (_cache[2] = $event => $options.onCurrencyChange($event.target.value))
      }, [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("option", {
        value: "USD"
      }, "USD", -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("option", {
        value: "KRW"
      }, "KRW", -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("option", {
        value: "VND"
      }, "VND", -1 /* CACHED */)]))], 40 /* PROPS, NEED_HYDRATION */, _hoisted_5), _cache[6] || (_cache[6] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "currencySelect"
      }, "통화", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })) : (0,vue__WEBPACK_IMPORTED_MODULE_0__.createCommentVNode)("v-if", true), _ctx.showCurrencySelect ? ((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createBlock)(_component_b_col, {
      key: 1,
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("input", {
        autocomplete: "off",
        type: "text",
        class: "form-control label-60",
        id: "baseRate",
        value: _ctx.baseRateDisplay,
        placeholder: "기준환율",
        disabled: true
      }, null, 8 /* PROPS */, _hoisted_7), _cache[7] || (_cache[7] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "baseRate"
      }, "기준환율", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })) : (0,vue__WEBPACK_IMPORTED_MODULE_0__.createCommentVNode)("v-if", true), _ctx.showCurrencySelect ? ((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createBlock)(_component_b_col, {
      key: 2,
      cols: "2",
      class: "ms-2 d-flex align-items-center"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
        class: "second",
        size: "sm",
        onClick: $options.openExchangeRate
      }, {
        default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[8] || (_cache[8] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("환율관리", -1 /* CACHED */)]))]),
        _: 1 /* STABLE */
      }, 8 /* PROPS */, ["onClick"]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", _hoisted_8, (0,vue__WEBPACK_IMPORTED_MODULE_0__.toDisplayString)(_ctx.appliedRateLabel), 1 /* TEXT */)]),
      _: 1 /* STABLE */
    })) : (0,vue__WEBPACK_IMPORTED_MODULE_0__.createCommentVNode)("v-if", true)]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_9, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[9] || (_cache[9] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_10, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_11, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_12, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[10] || (_cache[10] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_13, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "salesDataGrid",
    uid: 'salesDataGrid',
    grid: $data.salesDataGrid,
    layout: $data.salesDataGrid.columnLayout,
    step: '1',
    rows: $data.salesDataGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["grid", "layout", "rows"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_ExchangeRatePopup, {
    ref: "exchangeRatePopup",
    onClosePopup: $options.onExchangeRateClosed
  }, null, 8 /* PROPS */, ["onClosePopup"])]);
}

/***/ }),

/***/ "./src/utils/gridUtils.js":
/*!********************************!*\
  !*** ./src/utils/gridUtils.js ***!
  \********************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   applyAmtFormat: function() { return /* binding */ applyAmtFormat; },
/* harmony export */   applyAmtFormatLive: function() { return /* binding */ applyAmtFormatLive; }
/* harmony export */ });
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! core-js/modules/es.iterator.for-each.js */ "./node_modules/core-js/modules/es.iterator.for-each.js");
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_1__);


/**
 * 그리드 공용 유틸
 * ----------------------------------------------------------------------------
 * applyAmtFormat: 사이트(curProdCtg)에 따라 "금액" 컬럼의 소수 자릿수를 조정.
 *   - VINA(VN, USD): 정수 금액포맷(#,##0)을 소수점 2자리(#,##0.00)로 표시
 *   - 본사(HQ, 원화): 정수(#,##0) 유지
 *   - 수량/비율/순번 등 비-금액 컬럼과, 원래부터 소수인 컬럼(단가 등)은 제외
 *
 * 사용법 (각 화면 .vue 조회 메서드 등에서):
 *   import { applyAmtFormat } from '@/utils/gridUtils';
 *   applyAmtFormat(this.gridView, this.<clonedGridField>.columns, this.userAuthInfo.curProdCtg);
 *
 * ※ columns 는 원본(클론된 gridField) 컬럼 정의 배열을 넘긴다.
 *   (gridView 상태가 아니라 원본 numberFormat 기준으로 판단하므로 사이트 재전환에도 안전)
 */

// 금액이 아닌 컬럼(수량/비율/순번/기간 등) — 2자리 적용에서 제외
const NON_AMT_RE = /(수량|개수|매수|건수|장수|본수|qty|ea|pcs|순번|번호|순서|seq|\brn\b|\bno\b|년|월|일|비율|율|률|rate|percent|%|불량률|수율)/i;
function toDecimal2(fmt) {
  return typeof fmt === 'string' ? fmt.replace(/#,##0/g, '#,##0.00') : fmt;
}
function applyAmtFormat(gridView, columns, curProdCtg, currency = 'USD') {
  if (!gridView || !Array.isArray(columns)) return;
  // VINA(VN) & USD 표시일 때만 2자리. VINA라도 KRW/VND 환산표시면 정수, 본사(HQ)도 정수.
  const isVina = curProdCtg === 'VN' && (currency == null || currency === 'USD');
  columns.forEach(col => {
    if (!col || !col.name) return;
    const orig = col.numberFormat;
    // 정수형 금액포맷(#,##0)만 대상. 원래부터 소수(#,##0.00 - 단가 등)면 손대지 않음.
    if (typeof orig !== 'string' || orig.indexOf('#,##0') < 0 || orig.indexOf('.') >= 0) return;
    // 수량/비율/순번 등은 제외 → 금액 컬럼만
    const key = (col.name || '') + '|' + (col.fieldName || '') + '|' + (col.header && col.header.text || '');
    if (NON_AMT_RE.test(key)) return;
    const nf = isVina ? toDecimal2(orig) : orig; // VINA=2자리, 본사=원래 정수
    try {
      gridView.setColumnProperty(col.name, 'numberFormat', nf);
      if (col.footer && col.footer.numberFormat) {
        gridView.setColumnProperty(col.name, 'footer', {
          ...col.footer,
          numberFormat: isVina ? toDecimal2(col.footer.numberFormat) : col.footer.numberFormat
        });
      }
    } catch (e) {
      /* 컬럼 속성 적용 실패는 무시 */
    }
  });
}

/**
 * 동적으로 컬럼을 생성하는 화면(pivot/트리 등)용: gridView(또는 treeView)의
 * 현재 컬럼을 순회하여 VINA·USD일 때 금액 컬럼을 2자리로 표시.
 * (컬럼이 조회 시마다 새로 #,##0 로 생성되므로, 생성 직후 호출)
 */
function applyAmtFormatLive(gridView, curProdCtg, currency = 'USD') {
  if (!gridView || typeof gridView.getColumns !== 'function') return;
  const isVina = curProdCtg === 'VN' && (currency == null || currency === 'USD');
  if (!isVina) return; // 본사/비USD: 정수(생성된 기본 포맷) 유지
  const cols = gridView.getColumns() || [];
  cols.forEach(col => {
    if (!col || !col.name) return;
    const nf = col.numberFormat;
    if (typeof nf !== 'string' || nf.indexOf('#,##0') < 0 || nf.indexOf('.') >= 0) return;
    const key = (col.name || '') + '|' + (col.fieldName || '') + '|' + (col.header && col.header.text || '');
    if (NON_AMT_RE.test(key)) return;
    try {
      gridView.setColumnProperty(col.name, 'numberFormat', toDecimal2(nf));
      if (col.footer && col.footer.numberFormat) {
        gridView.setColumnProperty(col.name, 'footer', {
          ...col.footer,
          numberFormat: toDecimal2(col.footer.numberFormat)
        });
      }
    } catch (e) {/* 무시 */}
  });
}
/* harmony default export */ __webpack_exports__["default"] = ({
  applyAmtFormat,
  applyAmtFormatLive
});

/***/ }),

/***/ "./src/views/web/c0007000/js/currencyConvert.js":
/*!******************************************************!*\
  !*** ./src/views/web/c0007000/js/currencyConvert.js ***!
  \******************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var core_js_modules_es_iterator_filter_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! core-js/modules/es.iterator.filter.js */ "./node_modules/core-js/modules/es.iterator.filter.js");
/* harmony import */ var core_js_modules_es_iterator_filter_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_filter_js__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! core-js/modules/es.iterator.for-each.js */ "./node_modules/core-js/modules/es.iterator.for-each.js");
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var core_js_modules_es_iterator_map_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! core-js/modules/es.iterator.map.js */ "./node_modules/core-js/modules/es.iterator.map.js");
/* harmony import */ var core_js_modules_es_iterator_map_js__WEBPACK_IMPORTED_MODULE_3___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_map_js__WEBPACK_IMPORTED_MODULE_3__);
/* harmony import */ var core_js_modules_es_set_difference_v2_js__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! core-js/modules/es.set.difference.v2.js */ "./node_modules/core-js/modules/es.set.difference.v2.js");
/* harmony import */ var core_js_modules_es_set_difference_v2_js__WEBPACK_IMPORTED_MODULE_4___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_difference_v2_js__WEBPACK_IMPORTED_MODULE_4__);
/* harmony import */ var core_js_modules_es_set_intersection_v2_js__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! core-js/modules/es.set.intersection.v2.js */ "./node_modules/core-js/modules/es.set.intersection.v2.js");
/* harmony import */ var core_js_modules_es_set_intersection_v2_js__WEBPACK_IMPORTED_MODULE_5___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_intersection_v2_js__WEBPACK_IMPORTED_MODULE_5__);
/* harmony import */ var core_js_modules_es_set_is_disjoint_from_v2_js__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! core-js/modules/es.set.is-disjoint-from.v2.js */ "./node_modules/core-js/modules/es.set.is-disjoint-from.v2.js");
/* harmony import */ var core_js_modules_es_set_is_disjoint_from_v2_js__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_is_disjoint_from_v2_js__WEBPACK_IMPORTED_MODULE_6__);
/* harmony import */ var core_js_modules_es_set_is_subset_of_v2_js__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! core-js/modules/es.set.is-subset-of.v2.js */ "./node_modules/core-js/modules/es.set.is-subset-of.v2.js");
/* harmony import */ var core_js_modules_es_set_is_subset_of_v2_js__WEBPACK_IMPORTED_MODULE_7___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_is_subset_of_v2_js__WEBPACK_IMPORTED_MODULE_7__);
/* harmony import */ var core_js_modules_es_set_is_superset_of_v2_js__WEBPACK_IMPORTED_MODULE_8__ = __webpack_require__(/*! core-js/modules/es.set.is-superset-of.v2.js */ "./node_modules/core-js/modules/es.set.is-superset-of.v2.js");
/* harmony import */ var core_js_modules_es_set_is_superset_of_v2_js__WEBPACK_IMPORTED_MODULE_8___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_is_superset_of_v2_js__WEBPACK_IMPORTED_MODULE_8__);
/* harmony import */ var core_js_modules_es_set_symmetric_difference_v2_js__WEBPACK_IMPORTED_MODULE_9__ = __webpack_require__(/*! core-js/modules/es.set.symmetric-difference.v2.js */ "./node_modules/core-js/modules/es.set.symmetric-difference.v2.js");
/* harmony import */ var core_js_modules_es_set_symmetric_difference_v2_js__WEBPACK_IMPORTED_MODULE_9___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_symmetric_difference_v2_js__WEBPACK_IMPORTED_MODULE_9__);
/* harmony import */ var core_js_modules_es_set_union_v2_js__WEBPACK_IMPORTED_MODULE_10__ = __webpack_require__(/*! core-js/modules/es.set.union.v2.js */ "./node_modules/core-js/modules/es.set.union.v2.js");
/* harmony import */ var core_js_modules_es_set_union_v2_js__WEBPACK_IMPORTED_MODULE_10___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_set_union_v2_js__WEBPACK_IMPORTED_MODULE_10__);
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_11__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");











/**
 * VINA 통화 환산 믹스인 (표시 전용)
 * ----------------------------------------------------------------------------
 * - DB 저장금액은 항상 USD. 사용자가 KRW/VND 선택 시 해당 월 "월평균 환율"(DOI_EXCHANGE_RATE
 *   수동 등록값)로 금액 컬럼만 환산하여 화면에 표시한다. (원본 USD는 재조회로 복원)
 * - 비-USD 표시 중에는 편집/저장을 잠가 환산값이 USD 컬럼에 저장되는 사고를 막는다.
 *
 * 사용 화면 요구사항:
 *   data: params.site ('VINA'/'본사'), modelGridRows, ref="modelGrid"
 *   컴포넌트에 `currencyFields` (금액 컬럼 fieldName 배열)을 정의(또는 gridField에서 import)
 *   setup()에서 useC0001001() 스토어를 `srchInfo` 로 노출
 */

/* harmony default export */ __webpack_exports__["default"] = ({
  data() {
    return {
      appliedRate: null,
      // 현재 적용 환율 (USD 1 = N 통화)
      appliedRateMonth: null,
      // 화면에서 currencyFields 를 정의하지 않은 경우 대비 기본 빈 배열
      currencyFields: this.currencyFields || []
    };
  },
  computed: {
    // 통화 스토어 (setup 의 srchInfo 와 동일 인스턴스)
    _currencyStore() {
      return (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_11__.useC0001001)();
    },
    currency() {
      return this._currencyStore.currency;
    },
    isVinaSite() {
      return this.params && this.params.site === 'VINA';
    },
    // 통화선택 노출 여부
    showCurrencySelect() {
      return this.isVinaSite;
    },
    // 비-USD 표시 중이면 편집/저장 잠금
    isCurrencyReadonly() {
      return this.isVinaSite && this.currency !== 'USD';
    },
    // 기준환율 텍스트박스 표시값 (USD 1 = N 통화)
    baseRateDisplay() {
      if (!this.appliedRate) return '';
      return Number(this.appliedRate).toLocaleString(undefined, {
        maximumFractionDigits: 4
      });
    },
    // 적용환율 안내 라벨
    appliedRateLabel() {
      if (!this.isCurrencyReadonly || !this.appliedRate) return '';
      return `${this.appliedRateMonth} 월평균 환율 적용`;
    }
  },
  methods: {
    setCurrency(currency) {
      this._currencyStore.setCurrency(currency);
    },
    _normalizeYyyymm(yyyymm) {
      return yyyymm ? String(yyyymm).replaceAll('-', '') : null;
    },
    // (yyyymm, 통화) 월평균 기준환율 조회 — DOI_EXCHANGE_RATE 수동 등록값
    async fetchExchangeRate(yyyymm, currency) {
      const ym = this._normalizeYyyymm(yyyymm);
      if (!ym || !currency || currency === 'USD') return null;
      try {
        const data = await this.$axios.api.search({
          menuId: 'c0007012',
          queryId: 'C0007012_Rate',
          queryParams: {
            yyyymm: ym,
            currency
          },
          all: true
        });
        if (Array.isArray(data) && data.length > 0 && data[0]['환율'] != null) {
          return Number(data[0]['환율']);
        }
      } catch (e) {
        console.error('기준환율 조회 실패', e);
      }
      return null;
    },
    /**
     * 조회된 USD 행(rows)을 현재 통화에 맞춰 표시행으로 변환.
     * USD 이거나 VINA 가 아니면 원본 그대로 반환.
     * 환율 미등록 월이면 경고 후 USD 로 되돌리고 원본 반환.
     */
    async buildCurrencyRows(rows) {
      this.appliedRate = null;
      this.appliedRateMonth = null;
      if (!this.isVinaSite || this.currency === 'USD') return rows;
      const rate = await this.fetchExchangeRate(this.params.yyyymm, this.currency);
      if (!rate) {
        this.$toast && this.$toast('warning', `${this._normalizeYyyymm(this.params.yyyymm)} ${this.currency} 환율이 등록되지 않았습니다. USD로 표시합니다.`);
        this.setCurrency('USD');
        return rows;
      }
      this.appliedRate = rate;
      this.appliedRateMonth = this._normalizeYyyymm(this.params.yyyymm);
      const fields = this.currencyFields || [];
      return rows.map(r => {
        const nr = {
          ...r
        };
        fields.forEach(f => {
          const v = nr[f];
          if (v !== null && v !== undefined && v !== '' && !isNaN(Number(v))) {
            nr[f] = Math.round(Number(v) * rate);
          }
        });
        return nr;
      });
    },
    // 여러 YYYYMM 에 대한 (통화)월평균 환율을 한 번에 조회하여 맵으로 반환
    async fetchExchangeRateMap(yyyymms, currency) {
      const map = {};
      if (!currency || currency === 'USD') return map;
      const uniq = [...new Set((yyyymms || []).map(y => this._normalizeYyyymm(y)).filter(Boolean))];
      for (const ym of uniq) {
        map[ym] = await this.fetchExchangeRate(ym, currency);
      }
      return map;
    },
    /**
     * 여러 월이 섞인 집계행(rows)을 각 행의 소속 월(YYYYMM) 환율로 환산.
     * (연도 집계 화면용 — 단일월 buildCurrencyRows 와 달리 월별 환율을 개별 적용)
     * @param rows      원본(USD) 행 배열
     * @param resolveYm 행 → YYYYMM 문자열 반환 함수(또는 필드명). 미지정 시 YYYYMM/yyyymm 사용.
     * 등록된 월이 하나도 없으면 경고 후 USD 로 되돌린다. 등록 안된 월의 행은 USD 유지.
     */
    async buildCurrencyRowsByMonth(rows, resolveYm) {
      this.appliedRate = null;
      this.appliedRateMonth = null;
      if (!this.isVinaSite || this.currency === 'USD') return rows;
      if (!Array.isArray(rows) || rows.length === 0) return rows;
      const getYm = typeof resolveYm === 'function' ? resolveYm : r => this._normalizeYyyymm(r[resolveYm] ?? r.YYYYMM ?? r.yyyymm);
      const rateMap = await this.fetchExchangeRateMap(rows.map(getYm), this.currency);
      const registered = Object.keys(rateMap).filter(k => rateMap[k]);
      if (registered.length === 0) {
        this.$toast && this.$toast('warning', `${this.currency} 환율이 등록되지 않았습니다. USD로 표시합니다.`);
        this.setCurrency('USD');
        return rows;
      }
      this.appliedRate = rateMap[registered[0]];
      this.appliedRateMonth = registered.length === 1 ? registered[0] : '월별';
      const fields = this.currencyFields || [];
      return rows.map(r => {
        const rate = rateMap[getYm(r)];
        const nr = {
          ...r
        };
        if (!rate) return nr; // 미등록 월은 USD 유지
        fields.forEach(f => {
          const v = nr[f];
          if (v !== null && v !== undefined && v !== '' && !isNaN(Number(v))) {
            nr[f] = Math.round(Number(v) * rate);
          }
        });
        return nr;
      });
    },
    // 통화에 따라 그리드 편집 가능/잠금 전환
    applyCurrencyEditLock() {
      const gv = this.$refs.modelGrid && this.$refs.modelGrid.getGridView && this.$refs.modelGrid.getGridView();
      if (!gv) return;
      gv.setEditOptions({
        editable: !this.isCurrencyReadonly
      });
    }
  }
});

/***/ }),

/***/ "./src/views/web/c0009000/C0009003.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0009000/C0009003.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0009003_vue_vue_type_template_id_29528aad__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0009003.vue?vue&type=template&id=29528aad */ "./src/views/web/c0009000/C0009003.vue?vue&type=template&id=29528aad");
/* harmony import */ var _C0009003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0009003.vue?vue&type=script&lang=js */ "./src/views/web/c0009000/C0009003.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0009003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0009003_vue_vue_type_template_id_29528aad__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0009000/C0009003.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0009000/C0009003.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0009000/C0009003.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0009003.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009003.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0009000/C0009003.vue?vue&type=template&id=29528aad":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0009000/C0009003.vue?vue&type=template&id=29528aad ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009003_vue_vue_type_template_id_29528aad__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009003_vue_vue_type_template_id_29528aad__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0009003.vue?vue&type=template&id=29528aad */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009003.vue?vue&type=template&id=29528aad");


/***/ }),

/***/ "./src/views/web/c0009000/js/C0009003.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0009000/js/C0009003.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 판매 실적 집계
 */

const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
const grid = {
  options: {
    checkBar: {
      visible: false
    },
    copy: {
      enabled: true,
      singleMode: true
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 2
    },
    edit: {
      editable: false
    },
    footer: {
      visible: true
    },
    paste: {
      enabled: false
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: true
    },
    stateBar: {
      visible: false
    },
    filtering: {
      enabled: true
    },
    fixed: {
      colBarWidth: 1,
      colCount: 8
    }
  },
  fields: [{
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '모델명',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'set업체',
    dataType: ValueType.TEXT
  }, {
    fieldName: '고객코드',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우코드',
    dataType: ValueType.TEXT
  }, {
    fieldName: '두께',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'inch',
    dataType: ValueType.TEXT
  }, {
    fieldName: '제품구조',
    dataType: ValueType.TEXT
  }, {
    fieldName: '매출계획',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '계획대비실적',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty1',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt1',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty2',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt2',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty3',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt3',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty4',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt4',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty5',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt5',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty6',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt6',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty7',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt7',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty8',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt8',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty9',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt9',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty10',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt10',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty11',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt11',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'qty12',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'amt12',
    dataType: ValueType.NUMBER
  }],
  columnLayout: [{
    column: '구분'
  }, {
    column: '모델명'
  }, {
    column: 'set업체'
  }, {
    column: '고객코드'
  }, {
    column: '도우코드'
  }, {
    column: '두께'
  }, {
    column: 'inch'
  }, {
    column: '제품구조'
  }, {
    column: '매출계획'
  }, {
    column: '계획대비실적'
  }, {
    name: 'grp1월',
    header: {
      text: '1월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty1'
    }, {
      column: 'amt1'
    }]
  }, {
    name: 'grp2월',
    header: {
      text: '2월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty2'
    }, {
      column: 'amt2'
    }]
  }, {
    name: 'grp3월',
    header: {
      text: '3월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty3'
    }, {
      column: 'amt3'
    }]
  }, {
    name: 'grp4월',
    header: {
      text: '4월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty4'
    }, {
      column: 'amt4'
    }]
  }, {
    name: 'grp5월',
    header: {
      text: '5월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty5'
    }, {
      column: 'amt5'
    }]
  }, {
    name: 'grp6월',
    header: {
      text: '6월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty6'
    }, {
      column: 'amt6'
    }]
  }, {
    name: 'grp7월',
    header: {
      text: '7월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty7'
    }, {
      column: 'amt7'
    }]
  }, {
    name: 'grp8월',
    header: {
      text: '8월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty8'
    }, {
      column: 'amt8'
    }]
  }, {
    name: 'grp9월',
    header: {
      text: '9월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty9'
    }, {
      column: 'amt9'
    }]
  }, {
    name: 'grp10월',
    header: {
      text: '10월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty10'
    }, {
      column: 'amt10'
    }]
  }, {
    name: 'grp11월',
    header: {
      text: '11월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty11'
    }, {
      column: 'amt11'
    }]
  }, {
    name: 'grp12월',
    header: {
      text: '12월'
    },
    direction: 'horizontal',
    items: [{
      column: 'qty12'
    }, {
      column: 'amt12'
    }]
  }],
  columns: [{
    name: '구분',
    fieldName: '구분',
    width: 60,
    header: {
      text: '구분'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: '모델명',
    fieldName: '모델명',
    width: 80,
    header: {
      text: '모델명'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: 'set업체',
    fieldName: 'set업체',
    width: 80,
    header: {
      text: 'SET업체'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: '고객코드',
    fieldName: '고객코드',
    width: 140,
    header: {
      text: '고객코드'
    },
    autoFilter: true,
    styleName: 'tc',
    minWidth: 140,
    maxWidth: 140
  }, {
    name: '도우코드',
    fieldName: '도우코드',
    width: 140,
    header: {
      text: '도우코드'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: '두께',
    fieldName: '두께',
    width: 100,
    header: {
      text: '두께'
    },
    autoFilter: true,
    styleName: 'tr'
  }, {
    name: 'inch',
    fieldName: 'inch',
    width: 80,
    header: {
      text: 'inch'
    },
    autoFilter: true,
    styleName: 'tr'
  }, {
    name: '제품구조',
    fieldName: '제품구조',
    width: 90,
    header: {
      text: '제품구조'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: '매출계획',
    fieldName: '매출계획',
    width: 120,
    header: {
      text: '매출계획'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: '계획대비실적',
    fieldName: '계획대비실적',
    width: 120,
    header: {
      text: '계획대비실적'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty1',
    fieldName: 'qty1',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt1',
    fieldName: 'amt1',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty2',
    fieldName: 'qty2',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt2',
    fieldName: 'amt2',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty3',
    fieldName: 'qty3',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt3',
    fieldName: 'amt3',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty4',
    fieldName: 'qty4',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt4',
    fieldName: 'amt4',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty5',
    fieldName: 'qty5',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt5',
    fieldName: 'amt5',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty6',
    fieldName: 'qty6',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt6',
    fieldName: 'amt6',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty7',
    fieldName: 'qty7',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt7',
    fieldName: 'amt7',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty8',
    fieldName: 'qty8',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt8',
    fieldName: 'amt8',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty9',
    fieldName: 'qty9',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt9',
    fieldName: 'amt9',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty10',
    fieldName: 'qty10',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt10',
    fieldName: 'amt10',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty11',
    fieldName: 'qty11',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt11',
    fieldName: 'amt11',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'qty12',
    fieldName: 'qty12',
    width: 80,
    header: {
      text: '수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }, {
    name: 'amt12',
    fieldName: 'amt12',
    width: 120,
    header: {
      text: '금액'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: "sum",
      numberFormat: "#,##0",
      styleName: "sum-footer1"
    }
  }]
};
grid.currencyFields = ['amt1', 'amt2', 'amt3', 'amt4', 'amt5', 'amt6', 'amt7', 'amt8', 'amt9', 'amt10', 'amt11', 'amt12', '매출계획'];
module.exports = grid;

/***/ }),

/***/ "./src/views/web/store/C0001001.js":
/*!*****************************************!*\
  !*** ./src/views/web/store/C0001001.js ***!
  \*****************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   useC0001001: function() { return /* binding */ useC0001001; }
/* harmony export */ });
/* harmony import */ var pinia__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! pinia */ "./node_modules/pinia/dist/pinia.mjs");
/* harmony import */ var moment__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! moment */ "./node_modules/moment/moment.js");
/* harmony import */ var moment__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(moment__WEBPACK_IMPORTED_MODULE_1__);


const useC0001001 = (0,pinia__WEBPACK_IMPORTED_MODULE_0__.defineStore)('c0001001', {
  state: () => ({
    yyyymm: moment__WEBPACK_IMPORTED_MODULE_1___default()().format('YYYY-MM'),
    currency: 'USD' // VINA 화면 표시통화 (USD 기본 / KRW / VND). 화면군 공유
  }),
  getters: {
    getSearchkInfo: state => {
      return {
        yyyymm: state.yyyymm
      };
    },
    curCurrency: state => state.currency
  },
  actions: {
    setSearchInfo(obj) {
      this.yyyymm = obj.yyyymm;
    },
    setCurrency(currency) {
      this.currency = currency || 'USD';
    }
  }
});

/***/ })

}]);
//# sourceMappingURL=src_views_web_c0009000_C0009003_vue.7071175c097a4aca.js.map