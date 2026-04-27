import {Routes} from '@angular/router';
import {AdminScreenComponent} from './admin-screen/admin-screen.component';
import {PizzaAdminListComponent} from './pizza-admin-list/pizza-admin-list.component';
import {UserListComponent} from './user-list/user-list.component';

export const routes: Routes = [
  {path: '', component: AdminScreenComponent, title: 'Login'},
  {path: 'pizza', component: PizzaAdminListComponent},
  {path: 'users', component: UserListComponent}
]
