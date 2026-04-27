import {Injectable} from '@angular/core';
import {ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot} from '@angular/router';
import {AuthService} from '../login/auth.service';

@Injectable({
  providedIn: 'root'
})
export class AdminGuard implements CanActivate {

  constructor(private authService: AuthService, private router: Router) {
  }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    // Check if the user is logged in
    if (this.authService.isLoggedIn()) {
      // Get the user's role from the token
      const userRole = this.authService.getUserRole();
      console.log(userRole);
      // Check if the role is 'Admin'
      if (userRole === 'Admin') {
        return true; // Allow access to the route
      }
    }

    // If the user is not logged in or does not have the required role, redirect
    this.router.navigate(['/login'], {queryParams: {returnUrl: state.url}});
    return false;
  }
}
