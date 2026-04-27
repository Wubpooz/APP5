import {AfterViewInit, Component, Input, ViewChild} from '@angular/core';
import {MatExpansionPanel} from '@angular/material/expansion';
import {UserComment} from '../types/userComment';

@Component({
  selector: 'app-pizza-comment-list',
  templateUrl: './pizza-comment-list.component.html',
  styleUrl: './pizza-comment-list.component.scss'
})
export class PizzaCommentListComponent implements AfterViewInit {
  @Input({required: true}) comments!: UserComment[];
  @Input() opened: boolean = false;
  @ViewChild('expansionPanel') expansionPanel!: MatExpansionPanel;


  ngAfterViewInit() {
    if (this.opened) {
      this.expansionPanel.open()
    }
  }
}
