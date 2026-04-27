import {Injectable} from '@angular/core';
import {HttpClient, HttpHeaders} from '@angular/common/http';
import {catchError, map, Observable, throwError} from 'rxjs';
import {environment} from '../../environments/environment';
import {Pizza} from './types/pizza';

declare var jsonpickle: any;

@Injectable({
  providedIn: 'root'
})
export class PizzaService {

  constructor(private http: HttpClient) {
  }


  getPizza(): Observable<Pizza[]> {
    return this.http.get<Pizza[]>(`${environment.apiUrl}/pizza`).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Getting pizza list failed:', error);
        return throwError(error);
      })
    );
  }

  createPizza(name: string, description: string, imageUrl: string, price: number, category: 'MEAT' | 'FISH' | 'VEGAN'): Observable<any> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
    });

    const data: any = {name: name, description: description, image_url: imageUrl, price: price, category: category}
    data[jsonpickle.tags.PY_CLASS] = "awefull_pizza_shop.webserver.schemas.PizzaCreation"
    const body = jsonpickle.encode(data)
    return this.http.post(`${environment.apiUrl}/pizza/create`, body, {headers}).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Create pizza failed:', error);
        return throwError(error);
      })
    );
  }

  getPizzaById(pizzaId: string): Observable<Pizza> {
    return this.http.get<Pizza>(`${environment.apiUrl}/pizza/${pizzaId}`).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Getting pizza failed:', error);
        return throwError(error);
      })
    );
  }

  getPizzaByCategory(category: string) {
    return this.http.get<Pizza[]>(`${environment.apiUrl}/pizza/category/${category}`).pipe(
      map((response) => {
        return response;
      }),
      catchError((error) => {
        console.error('Getting pizza by category failed:', error);
        return throwError(error);
      })
    );
  }
}
