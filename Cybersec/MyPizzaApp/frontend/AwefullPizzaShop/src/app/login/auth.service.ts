import {Injectable} from '@angular/core';
import {HttpClient, HttpHeaders, HttpParams} from '@angular/common/http';
import {catchError, map, Observable, throwError} from 'rxjs';
import {environment} from '../../environments/environment';
import {jwtDecode} from 'jwt-decode';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  constructor(private http: HttpClient) {
  }

  // Login method to call the backend and get the token
  login(username: string, password: string): Observable<any> {
    const body = new HttpParams()
      .set('username', username)
      .set('password', password);
    const headers = new HttpHeaders({
      'Content-Type': 'application/x-www-form-urlencoded', // Set content type to form data
    });


    return this.http.post<{ access_token: string }>(`${environment.apiUrl}/token`, body.toString(), {headers}).pipe(
      map((response) => {
        // Store the token in local storage
        localStorage.setItem('access_token', response.access_token);
        return response;
      }),
      catchError((error) => {
        console.error('Login failed:', error);
        return throwError(error);
      })
    );
  }

  // Logout method to remove token from local storage
  logout(): void {
    localStorage.removeItem('access_token');
  }

  // Method to check if the user is logged in
  isLoggedIn(): boolean {
    return localStorage.getItem('access_token') !== null;
  }

  // Method to get the token from local storage
  getToken(): string | null {
    return localStorage.getItem('access_token');
  }

  getUserRole(): string | null {
    const token = this.getToken();
    if (token) {
      try {
        const decoded: any = jwtDecode(token); // Decode the JWT
        return decoded.role || null; // Adjust this line based on your JWT structure
      } catch (InvalidTokenError) {
        return null;
      }
    }
    return null; // Return null if there’s no token
  }

  register(email: string, username: string, password: string): Observable<any> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
    });

    const body = {email:email, name:username, password:password}

    return this.http.post(`${environment.apiUrl}/register`, body, {headers}).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Register failed:', error);
        return throwError(error);
      })
    );
  }

}
