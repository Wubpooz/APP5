import {Component, OnInit} from '@angular/core';
import {PizzaService} from '../pizza.service';
import {Pizza} from '../types/pizza';
import {ActivatedRoute} from '@angular/router';

@Component({
  selector: 'app-pizza-selection-screen',
  templateUrl: './pizza-selection-screen.component.html',
  styleUrl: './pizza-selection-screen.component.scss'
})
export class PizzaSelectionScreenComponent implements OnInit {
  pizzas: Pizza[] = [];

  constructor(private route: ActivatedRoute, private pizzaService: PizzaService) {
  }


  ngOnInit() {
     this.route.paramMap.subscribe({
      next: params => {
        var category = params.get('category');
        if (category) {
          this.pizzaService.getPizzaByCategory(category).subscribe({
            next: data => {
              this.pizzas = data
            }
          })
        } else {
          this.pizzaService.getPizza().subscribe({
            next: data => {
              this.pizzas = data
            }
          })
        }
      }
    })


  }

}
