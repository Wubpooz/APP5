import {Component, Inject} from '@angular/core';
import {MAT_DIALOG_DATA, MatDialogRef} from '@angular/material/dialog';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {User} from '../types/user';

@Component({
  selector: 'app-user-edit-dialog',
  templateUrl: './user-edit-dialog.component.html',
})
export class UserEditDialogComponent {
  userForm: FormGroup;

  constructor(
    public dialogRef: MatDialogRef<UserEditDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: User,
    private fb: FormBuilder
  ) {
    this.userForm = this.fb.group({
      id: [data.id, ''],
      name: [data.name, [Validators.required]],
      email: [data.email, [Validators.required, Validators.email]],
      role: [data.role, [Validators.required]],
    });
  }

  onSave(): void {
    if (this.userForm.valid) {
      console.log(this.userForm.value);
      this.dialogRef.close(this.userForm.value); // Return updated user data
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}
