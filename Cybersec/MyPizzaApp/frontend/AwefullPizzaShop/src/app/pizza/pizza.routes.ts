import {Routes} from '@angular/router';
import {PizzaSelectionScreenComponent} from './pizza-selection-screen/pizza-selection-screen.component';
import {IndividualPizzaScreenComponent} from './individual-pizza-screen/individual-pizza-screen.component';

export const routes: Routes = [
  {path: '', component: PizzaSelectionScreenComponent, title: 'Select your pizza'},
  {path: 'category/:category', component: PizzaSelectionScreenComponent, title: 'Select your pizza'},
  {path:':id', component: IndividualPizzaScreenComponent}
]
