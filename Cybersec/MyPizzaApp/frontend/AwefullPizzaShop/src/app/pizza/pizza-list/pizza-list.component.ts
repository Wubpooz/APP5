import {Component, Input} from '@angular/core';
import {Pizza} from '../types/pizza';

@Component({
  selector: 'app-pizza-list',
  templateUrl: './pizza-list.component.html',
  styleUrl: './pizza-list.component.scss'
})
export class PizzaListComponent {
  @Input({required: true}) pizzas: Pizza[] = [];
}
