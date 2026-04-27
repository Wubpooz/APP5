import {Component, EventEmitter, Input, Output} from '@angular/core';
import {FormControl, FormGroup} from "@angular/forms";
import {Credentials} from '../types/credentials';

@Component({
  selector: 'app-login-form',
  templateUrl: './login-form.component.html',
  styleUrl: './login-form.component.scss'
})
export class LoginFormComponent {
  form: FormGroup = new FormGroup({
    username: new FormControl(''),
    password: new FormControl(''),
  });

  submit() {
    if (this.form.valid) {
      this.submitEM.emit({username: this.form.value.username, password: this.form.value.password});
    }
  }
  @Input() error: string | null | undefined;
  @Input() returnUrl: string|null|undefined;
  @Output() submitEM = new EventEmitter<Credentials>();
}
