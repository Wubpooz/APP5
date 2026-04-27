import {NgModule} from '@angular/core';
import {CommonModule} from '@angular/common';
import {AdminScreenComponent} from './admin-screen/admin-screen.component';
import {PizzaCreationComponent} from './pizza-creation/pizza-creation.component';
import {RouterModule} from '@angular/router';
import {routes} from './admin.routes';
import {MatButton, MatIconButton} from '@angular/material/button';
import {MatCard, MatCardContent, MatCardHeader, MatCardImage, MatCardTitle} from '@angular/material/card';
import {MatError, MatFormField, MatLabel} from '@angular/material/form-field';
import {MatInput} from '@angular/material/input';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {PizzaAdminCardComponent} from './pizza-admin-card/pizza-admin-card.component';
import {PizzaAdminListComponent} from './pizza-admin-list/pizza-admin-list.component';
import {MatIcon} from '@angular/material/icon';
import {MatDialogActions, MatDialogClose, MatDialogContent, MatDialogTitle} from '@angular/material/dialog';
import {UserListComponent} from './user-list/user-list.component';
import {
  MatCell,
  MatCellDef,
  MatColumnDef,
  MatHeaderCell,
  MatHeaderCellDef,
  MatHeaderRow,
  MatHeaderRowDef,
  MatRow,
  MatRowDef,
  MatTable
} from '@angular/material/table';
import {UserEditDialogComponent} from './user-edit-dialog/user-edit-dialog.component';
import {MatOption, MatSelect} from '@angular/material/select';


@NgModule({
  declarations: [
    AdminScreenComponent,
    PizzaCreationComponent,
    PizzaAdminCardComponent,
    PizzaAdminListComponent,
    UserListComponent,
    UserEditDialogComponent
  ],
  imports: [
    CommonModule,
    RouterModule.forChild(routes),
    MatButton,
    MatCard,
    MatCardContent,
    MatCardTitle,
    MatFormField,
    MatInput,
    ReactiveFormsModule,
    MatCardImage,
    MatIconButton,
    MatIcon,
    MatCardHeader,
    MatDialogActions,
    MatDialogContent,
    MatDialogTitle,
    MatLabel,
    FormsModule,
    MatDialogClose,
    MatTable,
    MatColumnDef,
    MatHeaderCell,
    MatCell,
    MatHeaderCellDef,
    MatCellDef,
    MatHeaderRow,
    MatRow,
    MatHeaderRowDef,
    MatRowDef,
    MatSelect,
    MatOption,
    MatError
  ]
})
export class AdminModule {
}
