import {RouterModule, Routes} from '@angular/router';
import {HomepageComponent} from './homepage/homepage.component';
import {AuthGuard} from './auth.guard';
import {NgModule} from '@angular/core';
import {AdminGuard} from './admin/admin.guard';

export const routes: Routes = [
  {path: '', component: HomepageComponent},
  {path: 'login', loadChildren: () => import('./login/login.module').then(m => m.LoginModule)},
  {
    path: 'pizza',
    loadChildren: () => import('./pizza/pizza.module').then(m => m.PizzaModule),
    canActivate: [AuthGuard]
  },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule),
    canActivate: [AuthGuard, AdminGuard]
  },
  //{path: '**', canActivate: [AuthGuard]},
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {
}
