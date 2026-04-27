import {Component, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {Pizza} from '../types/pizza';
import {PizzaService} from '../pizza.service';

@Component({
  selector: 'app-individual-pizza-screen',
  templateUrl: './individual-pizza-screen.component.html',
  styleUrl: './individual-pizza-screen.component.scss'
})
export class IndividualPizzaScreenComponent implements OnInit{
  id: string | null = null;
  pizza!: Pizza;

  constructor(private route: ActivatedRoute, private pizzaService: PizzaService) {
  }

  ngOnInit(): void {
    // Get the 'id' from the route parameters
    this.id = this.route.snapshot.paramMap.get('id');
    console.log(this.id);  // Do something with the 'id'
    if (this.id) {
      this.pizzaService.getPizzaById(this.id).subscribe({
        next: data => this.pizza = data
      })
    } else {
      console.error('no id specified for this component')
    }

  }
}
