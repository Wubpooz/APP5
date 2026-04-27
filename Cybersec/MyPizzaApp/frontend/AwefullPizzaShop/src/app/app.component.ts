import {Component} from '@angular/core';
import {faBacon, faFish, faLeaf} from '@fortawesome/free-solid-svg-icons';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'AwefullPizzaShop';
  showFiller = false;
  protected readonly faFish = faFish;
  protected readonly faLeaf = faLeaf;
  protected readonly faBacon = faBacon;
}
