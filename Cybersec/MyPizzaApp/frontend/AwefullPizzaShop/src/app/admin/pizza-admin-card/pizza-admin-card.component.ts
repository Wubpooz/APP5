import {Component, Input} from '@angular/core';
import {Pizza} from '../../pizza/types/pizza';

@Component({
  selector: 'app-pizza-admin-card',
  templateUrl: './pizza-admin-card.component.html',
  styleUrl: './pizza-admin-card.component.scss'
})
export class PizzaAdminCardComponent {
  @Input({required: true}) pizza!: Pizza;
}
