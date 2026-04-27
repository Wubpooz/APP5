import {Component, Input, OnChanges, SimpleChanges} from '@angular/core';
import {UserComment} from '../types/userComment';
import {DomSanitizer, SafeHtml} from '@angular/platform-browser';

@Component({
  selector: 'app-pizza-comment-card',
  templateUrl: './pizza-comment-card.component.html',
  styleUrl: './pizza-comment-card.component.scss'
})
export class PizzaCommentCardComponent implements OnChanges {
  @Input({required: true}) comment!: UserComment;
  commentContent: SafeHtml = '';


  constructor(private sanitizer: DomSanitizer) {
    this.sanitizer = sanitizer;
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (this.commentContent == '') {
      this.commentContent = this.sanitizer.bypassSecurityTrustHtml(this.comment.content);
    }
  }

}
