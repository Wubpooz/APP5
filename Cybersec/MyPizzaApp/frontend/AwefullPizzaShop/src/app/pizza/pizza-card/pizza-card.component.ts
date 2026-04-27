import {booleanAttribute, Component, inject, Input, model, OnInit, signal} from '@angular/core';
import {Pizza} from '../types/pizza';
import {MatDialog} from '@angular/material/dialog';
import {PizzaCommentAddDialog} from '../pizza-comment-add-dialog/pizza-comment-add-dialog.component';
import {UserComment} from '../types/userComment';
import {CommentService} from '../comment.service';
import {BehaviorSubject} from 'rxjs';

@Component({
  selector: 'app-pizza-card',
  templateUrl: './pizza-card.component.html',
  styleUrl: './pizza-card.component.scss'
})
export class PizzaCardComponent implements OnInit {
  @Input({transform: booleanAttribute}) openComments: boolean = false;
  readonly commentContent = signal('');
  readonly name = model('');
  readonly dialog = inject(MatDialog);
  comments: UserComment[] = []
  private pizzaSubject = new BehaviorSubject<Pizza | null>(null);
  pizza$ = this.pizzaSubject.asObservable();

  constructor(private commentService: CommentService) {
  }

  private _pizza!: Pizza

  get pizza() {
    return this._pizza;
  }

  @Input({required: true})
  set pizza(pizza: Pizza) {
    this._pizza = pizza;
    this.pizzaSubject.next(pizza);
  }

  ngOnInit() {
    this.pizza$.subscribe({
      next: value => {
        if (value) {
          this.commentService.getCommentForPizza(value.id).subscribe({
            next: data => this.comments = data
          })
        }
      }
    })

  }

  openCommentDialog(): void {
    const dialogRef = this.dialog.open(PizzaCommentAddDialog, {
      data: {name: this.name(), content: this.commentContent()},
    });

    dialogRef.afterClosed().subscribe(result => {
      console.log('The dialog was closed');
      if (result !== undefined) {
        this.commentService.createComment(this.pizza.id, result).subscribe({
            next: _ => this.commentService.getCommentForPizza(this.pizza.id).subscribe({
              next: data => this.comments = data
            })
          }
        )
      }
    });
  }

}
