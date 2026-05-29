<template>
	<div :id="gridId" style="width:100%;height:100%;" ></div>
</template>

<script>

import { GridView, LocalDataProvider } from 'realgrid';
import '@assets/style/realgrid.css'
// import { useGlobalCountStore } from "@/stores/globalCount";

let gridInstances = {}; // 전역 객체로 동적 변수 관리

export default {
	setup(){

	},
	props: {
		uid: { type: String, default: 'grid' },
		step: { type: Number, default: 0 },
		rows: { type: Array, default: null },
		fitLayoutWidthEnable: { type: Boolean, default: true },
	},
	data () {
		return {					    
			target: null,
			gridId: `realgrid-${this.$uuid()}`,
		}
	},
	watch: {
		rows: {
      handler(newRows) {
				const { dataProvider } = gridInstances[this.gridId];
        if (dataProvider) {
          dataProvider.setRows(newRows);
        }
      },
      deep: true
    }
	},
	mounted() {
		this.created();
	},
	beforeUnmount() {
		this.destroy();
	},
	methods: {
		getGridView(){
			const instance = gridInstances[this.gridId];
			return instance ? instance.gridView : null;
		},
		getGridDataProvider(){
			const instance = gridInstances[this.gridId];
			return instance ? instance.dataProvider : null;
		},
		created() {

			this.destroy();

			const maxIterations = 50;
			let iterations = 0;
			this.target = this.$parent;		

			while (this.target[this.uid] === undefined) {
				this.target = this.target.$parent;
				iterations++;
				if(iterations >= maxIterations) {
					console.error(`최대 반복 횟수(${maxIterations})를 초과했습니다.`);
					break;
				}
				if(!this.target) {
					console.error("더 이상 상위 parent가 없습니다.");
					break;
				}
			}
			
			gridInstances[this.gridId] = {
        dataProvider: new LocalDataProvider(false),
        gridView: new GridView(this.gridId),
      };
			if(this.target[this.uid] == undefined) return;
      const { dataProvider, gridView } = gridInstances[this.gridId];

			gridView.setDataSource(dataProvider);
			dataProvider.setFields(this.target[this.uid].fields);
			gridView.setColumns(this.target[this.uid].columns);		
			gridView.setOptions(this.target[this.uid].options);
			//dataProvider.addRows([{},{},{}])
			if(this.target[this.uid].layout)gridView.setColumnLayout(this.target[this.uid].layout);
			
			// 높이가 지정되지 않은 경우. -> 공통 적용 행 높이 30
			if(!(this.target[this.uid].options != undefined 
				&& this.target[this.uid].options.display != undefined  
				&& this.target[this.uid].options.display.rowHeight != undefined)){
					gridView.setDisplayOptions({rowHeight: 30});
			}
			
			let targetId = this.uid.charAt(0).toUpperCase() + this.uid.slice(1);
			
			let onDataLoadComplatedFlag = true;
			Object.keys(this.target)
			.filter(item => item.startsWith('on') && item.endsWith(targetId))
			.forEach(item => {
				if(item.replace(targetId,'') == 'onDataLoadComplated'){
					onDataLoadComplatedFlag = false;
				}
				Object.keys(gridView).filter(item1 => item1 == item.replace(targetId,'')).forEach(item2 => {
					gridView[item2] = this.target[item];
				});
				Object.keys(dataProvider).filter(item1 => item1 == item.replace(targetId,'')).forEach(item2 => {
					dataProvider[item2] = this.target[item];
				});
			});

			if(onDataLoadComplatedFlag){
				gridView['onDataLoadComplated'] = this.onDataLoadComplated
			}
			Object.keys(this.target)
			.filter(item => item.startsWith('set') && item.endsWith(targetId))
			.forEach(item => {
				gridView[item.replace(targetId,'')](this.target[item]);			
			});
		},
		destroy() {
			const instance = gridInstances[this.gridId];
			if (instance) {
				instance.gridView.destroy();
				instance.dataProvider.destroy();
				delete gridInstances[this.gridId];
			}
		},

		getSaveData() {
			const { dataProvider } = gridInstances[this.gridId];			
			return this.$utils.getGridSaveData(dataProvider);
		},

		onDataLoadComplated(grid){
			//console.log("this.fitLayoutWidthEnable:::",this.fitLayoutWidthEnable)
			if(this.fitLayoutWidthEnable){
				grid.fitLayoutWidth(null);
			}
		}
	}
}
</script>
