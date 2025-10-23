const c0007000Router = [
{
  path: '/c0007001',
  name: '부서별_계정별_비용',
  component: () => import('../views/web/c0007000/C0007001.vue'),
  meta: {
    upperSysResourceId:'C0007000',
    sysResourceId:"C0007001",
    requiresAuth: false,
  }
},
{
  path: '/c0007002',
  name: '자재투입정보',
  component: () => import('../views/web/c0007000/C0007002.vue'),
  meta: {
  upperSysResourceId:'C0007000',
  sysResourceId:"C0007002",
  }
 },
{
  path: '/c0007003',
  name: '생산정보',
  component: () => import('../views/web/c0007000/C0007003.vue'),
  meta: {
    upperSysResourceId:'C0007000',
    sysResourceId:"C0007003",
    requiresAuth: false,
  }
},
{
  path: '/c0007004',
  name: '제품정보',
  component: () => import('../views/web/c0007000/C0007004.vue'),
  meta: {
    upperSysResourceId:'C0007000',
    sysResourceId:"C0007004",
    requiresAuth: false,
  }
},  
];

export default c0007000Router;