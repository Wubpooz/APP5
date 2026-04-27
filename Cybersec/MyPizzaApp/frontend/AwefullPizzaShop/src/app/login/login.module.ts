import {NgModule} from '@angular/core';
import {CommonModule} from '@angular/common';
import {LoginFormComponent} from './login-form/login-form.component';
import {MatCard, MatCardContent, MatCardTitle} from '@angular/material/card';
import {MatFormField} from '@angular/material/form-field';
import {ReactiveFormsModule} from '@angular/forms';
import {MatInput} from '@angular/material/input';
import {MatButton} from '@angular/material/button';
import {LoginComponent} from './login.component';
import {RegisterComponent} from './register/register.component';
import {RouterModule} from '@angular/router';
import {routes} from './login.routes';


@NgModule({
  declarations: [
    LoginFormComponent,
    LoginComponent,
    RegisterComponent
  ],
  imports: [
    CommonModule,
    MatCard,
    MatCardTitle,
    MatCardContent,
    MatFormField,
    ReactiveFormsModule,
    MatInput,
    MatButton,
    RouterModule.forChild(routes)
  ],
  exports: [
    LoginFormComponent,
    LoginComponent,
    RegisterComponent
  ],
})
export class LoginModule {
}

