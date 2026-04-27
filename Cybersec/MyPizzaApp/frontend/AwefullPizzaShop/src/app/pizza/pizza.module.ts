import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import {RouterModule} from '@angular/router';
import {routes} from './pizza.routes';
import { PizzaCardComponent } from './pizza-card/pizza-card.component';
import { PizzaListComponent } from './pizza-list/pizza-list.component';
import { PizzaSelectionScreenComponent } from './pizza-selection-screen/pizza-selection-screen.component';
import {MatCard, MatCardContent, MatCardImage} from '@angular/material/card';
import {MatDialogActions, MatDialogClose, MatDialogContent, MatDialogTitle} from '@angular/material/dialog';
import {MatFormField, MatLabel} from '@angular/material/form-field';
import {MatInput} from '@angular/material/input';
import {MatButton} from '@angular/material/button';
import {FormsModule} from '@angular/forms';
import {PizzaCommentAddDialog} from './pizza-comment-add-dialog/pizza-comment-add-dialog.component';
import { PizzaCommentListComponent } from './pizza-comment-list/pizza-comment-list.component';
import {
  MatExpansionPanel, MatExpansionPanelContent,
  MatExpansionPanelDescription,
  MatExpansionPanelHeader,
  MatExpansionPanelTitle
} from '@angular/material/expansion';
import { PizzaCommentCardComponent } from './pizza-comment-card/pizza-comment-card.component';
import { IndividualPizzaScreenComponent } from './individual-pizza-screen/individual-pizza-screen.component';



@NgModule({
  declarations: [
    PizzaCardComponent,
    PizzaListComponent,
    PizzaSelectionScreenComponent,
    PizzaCommentAddDialog,
    PizzaCommentListComponent,
    PizzaCommentCardComponent,
    IndividualPizzaScreenComponent,
  ],
  imports: [
    CommonModule,
    RouterModule.forChild(routes),
    MatCardContent,
    MatCard,
    MatDialogContent,
    MatFormField,
    MatDialogActions,
    MatDialogClose,
    MatDialogTitle,
    MatInput,
    MatButton,
    MatLabel,
    FormsModule,
    MatExpansionPanel,
    MatExpansionPanelTitle,
    MatExpansionPanelDescription,
    MatCardImage,
    MatExpansionPanelHeader,
    MatExpansionPanelContent
  ]
})
export class PizzaModule { }
