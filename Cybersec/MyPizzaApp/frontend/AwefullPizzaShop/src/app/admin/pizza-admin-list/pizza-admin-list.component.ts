import {Component, inject, OnInit} from '@angular/core';
import {MatDialog} from '@angular/material/dialog';
import {PizzaCreation} from '../types/pizzaCreation';
import {PizzaCreationComponent} from '../pizza-creation/pizza-creation.component';
import {Pizza} from '../../pizza/types/pizza';
import {PizzaService} from '../../pizza/pizza.service';

declare var jsonpickle: any;

@Component({
  selector: 'app-pizza-admin-list',
  templateUrl: './pizza-admin-list.component.html',
  styleUrl: './pizza-admin-list.component.scss'
})
export class PizzaAdminListComponent implements OnInit {
  readonly dialog = inject(MatDialog);
  protected pizzas: Pizza[] = [];

  constructor(private pizzaService: PizzaService) {
  }

  ngOnInit() {
    this.pizzaService.getPizza().subscribe({
      next: data => {
        this.pizzas = data
      }
    })
  }

  openCreateNewPizzaDialog(): void {
    const dialogRef = this.dialog.open(PizzaCreationComponent, {
      data: {},
    });

    dialogRef.afterClosed().subscribe((result: PizzaCreation | undefined) => {
      console.log('The dialog was closed');
      if (result !== undefined) {
        this.pizzaService.createPizza(result.name, result.description, result.imageUrl, result.price, result.category).subscribe({
          next: data => this.pizzaService.getPizza().subscribe({
            next: data => this.pizzas = data
          })
        })
      }
    });
  }
}
