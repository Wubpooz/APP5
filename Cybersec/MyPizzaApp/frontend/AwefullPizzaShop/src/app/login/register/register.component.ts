import {Component, OnInit} from '@angular/core';
import {FormControl, FormGroup} from '@angular/forms';
import {AuthService} from '../auth.service';
import {ActivatedRoute, Router} from '@angular/router';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrl: './register.component.scss'
})
export class RegisterComponent implements OnInit {
  form: FormGroup = new FormGroup({
    email: new FormControl(''),
    username: new FormControl(''),
    password: new FormControl(''),
    confirmPassword: new FormControl(''),
  });
  error: string | null | undefined;
  private returnUrl: string = '';

  constructor(private authService: AuthService, private route: ActivatedRoute, private router: Router) {
  }

  ngOnInit(): void {
    const url = this.route.snapshot.queryParams['returnUrl'];
    if (this.isValidReturnUrl(url)) {
      this.returnUrl = url;
    }
  }

  submit() {
    if (this.form.valid) {
      if (this.form.value.password !== this.form.value.confirmPassword) {
        this.error = 'password does not Match'
        return;
      }
      this.authService.register(this.form.value.email, this.form.value.username, this.form.value.password).subscribe({
        next: (response) => {
          this.router.navigate([this.returnUrl]);
        },
        error: (error) => {
          if (error.error.detail !==undefined) {
            this.error = "An error occurred during register:"+ JSON.stringify(error.error.detail);
          } else {
            this.error = "An error occurred during register:"+ JSON.stringify(error);
          }

        },
        complete: () => {
          console.log('Register process completed.');
        }
      })
    }
  }

  // Method to validate if the returnUrl is within the application
  private isValidReturnUrl(url: string): boolean {
    // Allow only internal URLs (starting with '/') or root
    return (url.startsWith('/') || url === '/');
  }

}
