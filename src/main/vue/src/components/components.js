import RealGrid from './RealGrid.vue';
import MenuTabs from './MenuTabs.vue';
import AuthTabs from './AuthTabs.vue';
import CodeSelect from './CodeSelect.vue';

import HistoryView from './production/HistoryView.vue';
import LogViewer from './production/LogViewer.vue';

import DatePicker from './DatePicker.vue';

import CmDialog1   from './CmDialog1.vue';
import CmDialog2   from './CmDialog2.vue';

import UploadPopup   from './UploadPopup.vue';
import ExchangeRatePopup from './ExchangeRatePopup.vue';

import FileAttachComponent   from './FileAttachComponent.vue';
import FileAttachPopup   from './FileAttachPopup.vue';

import DateTimeSpinner   from './DateTimeSpinner.vue';

export default {
  install(app) {
    app.component('RealGrid', RealGrid);
    app.component('MenuTabs', MenuTabs);
    app.component('AuthTabs', AuthTabs);  //화면에서 권한 있는 텝만 사용 필요한 경우
    app.component('CodeSelect', CodeSelect);

    app.component('HistoryView', HistoryView);
    app.component('LogViewer', LogViewer);

    app.component('DatePicker', DatePicker);
	
	app.component('CmDialog1', CmDialog1); // 그리드 1개만 나오는 팝업
	app.component('CmDialog2', CmDialog2); // 검색조건이있는 팝업

	app.component('UploadPopup', UploadPopup);
	app.component('ExchangeRatePopup', ExchangeRatePopup); // 환율관리 팝업 (VINA USD 환산)
    app.component('FileAttachComponent', FileAttachComponent);
    app.component('FileAttachPopup', FileAttachPopup);
    
    app.component('DateTimeSpinner', DateTimeSpinner);
  }
}