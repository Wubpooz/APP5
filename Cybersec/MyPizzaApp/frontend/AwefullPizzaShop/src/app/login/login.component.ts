import {Component, OnInit} from '@angular/core';
import {AuthService} from './auth.service';
import {ActivatedRoute, Router} from '@angular/router';
import {Credentials} from './types/credentials';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent implements OnInit {
  errorMessage!: string;
  returnUrl: string = '/pizza';

  constructor(private authService: AuthService, private route: ActivatedRoute, private router: Router) {
  }

  login(credentials: Credentials) {
    this.authService.login(credentials.username, credentials.password).subscribe({
        next: (response) => {
          this.router.navigate([this.returnUrl]);
        },
        error: (error) => {
          this.errorMessage = 'Invalid username or password';
        },
        complete: () => {
          console.log('Login process completed.');
        }
      }
    );
  }

  ngOnInit(): void {
    const url = this.route.snapshot.queryParams['returnUrl'];
    if (this.isValidReturnUrl(url)) {
      this.returnUrl = url;
    }
  }

  // Method to validate if the returnUrl is within the application
  private isValidReturnUrl(url: string): boolean {
    // Allow only internal URLs (starting with '/') or root
    return (url.startsWith('/') || url === '/');
  }
}
