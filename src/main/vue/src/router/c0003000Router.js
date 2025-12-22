const c0003000Router = [
{
   path: '/c0003001',
   name: '제조원가 집계',
   component: () => import('../views/web/c0003000/C0003001.vue'),
   meta: {
     upperSysResourceId:'C0003000',
     sysResourceId:"C0003001",
     requiresAuth: true,
   }
 },
{
  path: '/c0003002',
  name: '매출원가 집계',
  component: () => import('../views/web/c0003000/C0003002.vue'),
  meta: {
    upperSysResourceId:'C0003000',
    sysResourceId:"C0003002",
    requiresAuth: true,
  }
}
  /*
  {
    path: '/m0003001',
    name: 'Back#1',
    component: () => import('../views/web/m0003000/M0003001.vue'),
    meta: {
      upperSysResourceId:'M0003000',
      sysResourceId:"M0003001",
      requiresAuth: true,      
    }
  }, 
  {
    path: '/m0003002',
    name: 'Back#2 Cassette QC',
    component: () => import('../views/web/m0003000/M0003002.vue'),
    meta: {
      upperSysResourceId:'M0003000',
      sysResourceId:"M0003002",
      requiresAuth: true,
    }
  },
  {
    path: '/m0003003',
    name: 'Back#2 Cell QC',
    component: () => import('../views/web/m0003000/M0003003.vue'),
    meta: {
      upperSysResourceId:'M0003000',
      sysResourceId:"M0003003",
      requiresAuth: true,
    }
  },  */
 /* {
    path: '/m0003008',
    name: 'Rework',
    component: () => import('../views/web/m0003000/M0003008.vue'),
    meta: {
      upperSysResourceId:'M0003000',
      sysResourceId:"M0003008",
      requiresAuth: true,
    }
  },
  {
    path: '/m0003009',
    name: '포장/출하',
    component: () => import('../views/web/m0003000/M0003009.vue'),
    meta: {
      upperSysResourceId:'M0003000',
      sysResourceId:"M0003009",
      requiresAuth: true,
    }
  }, */ 
];

export default c0003000Router;