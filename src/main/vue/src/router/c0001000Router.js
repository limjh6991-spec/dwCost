const c0001000Router = [
  {
    path: '/c0001009',
    name: '사용자-메뉴 권한 관리',
    component: () => import('../views/web/c0001000/C0001009.vue'),
    meta: {
      upperSysResourceId:'C0001000',
      sysResourceId:"C0001009",
      requiresAuth: true,
    }
  },
];

export default c0001000Router;