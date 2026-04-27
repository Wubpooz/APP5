import {Routes} from '@angular/router';
import {LoginComponent} from './login.component';
import {RegisterComponent} from './register/register.component';

export const routes: Routes = [
  {path: '', component: LoginComponent, title: 'Login'},
  {path: 'register', component: RegisterComponent}
]
