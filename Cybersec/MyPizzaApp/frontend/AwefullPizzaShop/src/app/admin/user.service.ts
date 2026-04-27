import {Injectable} from '@angular/core';
import {HttpClient, HttpHeaders, HttpParams} from '@angular/common/http';
import {catchError, map, Observable, throwError} from 'rxjs';
import {environment} from '../../environments/environment';
import {jwtDecode} from 'jwt-decode';
import {User, UserRole} from './types/user';

@Injectable({
  providedIn: 'root'
})
export class UserService {

  constructor(private http: HttpClient) {
  }


  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(`${environment.apiUrl}/users`).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Getting users failed:', error);
        return throwError(error);
      })
    );
  }

  editUser(userId:string, username:string,email:string,role:UserRole): Observable<any> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
    });
    const body = {email:email, name:username, role:role}
    return this.http.post(`${environment.apiUrl}/users/${userId}`, body, {headers})
  }

}
