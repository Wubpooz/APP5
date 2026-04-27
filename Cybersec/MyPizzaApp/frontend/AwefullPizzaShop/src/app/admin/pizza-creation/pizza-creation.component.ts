import {Component, inject} from '@angular/core';
import {MatDialogRef} from '@angular/material/dialog';
import {FormControl, FormGroup, Validators} from '@angular/forms';

@Component({
  selector: 'app-pizza-creation',
  templateUrl: './pizza-creation.component.html',
  styleUrl: './pizza-creation.component.scss'
})
export class PizzaCreationComponent {
  readonly dialogRef = inject(MatDialogRef<PizzaCreationComponent>);
  form: FormGroup = new FormGroup({
    name: new FormControl('', [Validators.required]),
    description: new FormControl('', [Validators.required]),
    price: new FormControl('', [Validators.required]),
    imageUrl: new FormControl('', [Validators.required]),
    category: new FormControl('', [Validators.required])
  });

  onNoClick(): void {
    this.dialogRef.close();
  }

  onSave() {
    if (this.form.valid) {
      console.log(this.form.value);
      this.dialogRef.close(this.form.value);
    }
  }
}
