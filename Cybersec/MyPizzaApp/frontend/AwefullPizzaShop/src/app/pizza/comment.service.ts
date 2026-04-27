import {Injectable} from '@angular/core';
import {HttpClient, HttpHeaders} from '@angular/common/http';
import {catchError, map, Observable, throwError} from 'rxjs';
import {environment} from '../../environments/environment';
import {UserComment} from './types/userComment';


@Injectable({
  providedIn: 'root'
})
export class CommentService {

  constructor(private http: HttpClient) {
  }


  getCommentForPizza(pizzaId: string): Observable<UserComment[]> {
    return this.http.get<UserComment[]>(`${environment.apiUrl}/pizza/${pizzaId}/comment`).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Getting pizza comments failed:', error);
        return throwError(error);
      })
    );
  }

  createComment(pizzaId: string, content: string): Observable<any> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
    });
    const body = {content: content}
    return this.http.post(`${environment.apiUrl}/pizza/${pizzaId}/comment/create`, body, {headers}).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Create pizza comment failed:', error);
        return throwError(error);
      })
    );
  }

}
