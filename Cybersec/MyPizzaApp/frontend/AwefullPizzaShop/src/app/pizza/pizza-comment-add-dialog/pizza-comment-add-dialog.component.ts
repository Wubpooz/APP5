import {Component, inject, model} from '@angular/core';
import {MAT_DIALOG_DATA, MatDialogRef} from '@angular/material/dialog';
import {CommentDialogData} from '../types/commentDialogData';

@Component({
  selector: 'app-pizza-comment-dialog',
  templateUrl: './pizza-comment-add-dialog.component.html',
  styleUrl: './pizza-comment-add-dialog.component.scss'
})
export class PizzaCommentAddDialog {
  readonly dialogRef = inject(MatDialogRef<PizzaCommentAddDialog>);
  readonly data = inject<CommentDialogData>(MAT_DIALOG_DATA);
  readonly content = model(this.data.content);

  onNoClick(): void {
    this.dialogRef.close();
  }
}
