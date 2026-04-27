import {HttpErrorResponse, HttpInterceptorFn, HttpRequest} from '@angular/common/http';
import {catchError, throwError} from 'rxjs';
import {AuthService} from './auth.service';
import {inject} from '@angular/core';
import {ActivatedRoute, Router} from '@angular/router';

export const authInterceptor: HttpInterceptorFn = (req: HttpRequest<any>, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  const route = inject(ActivatedRoute);
  const token = authService.getToken();

  // If the token exists, clone the request and add the Authorization header
  let request;
  if (token) {
    const clonedRequest = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`),
    });

    request = next(clonedRequest);
  } else {
    request = next(req); // If no token, proceed with the request unmodified
  }

  return request.pipe(catchError((error: HttpErrorResponse) => {
    // Check if the error status is 401 (Unauthorized)
    if (error.status === 401) {
      // Call the AuthService to log out the user
      authService.logout();
      console.log(route.snapshot.url)
      // Redirect the user to the login page
      router.navigate(['/login'], {queryParams: {returnUrl: route.snapshot.url.join('')}});
    }
    // Forward the error to the next handler
    return throwError(() => new Error(error.message));
  }));
}
