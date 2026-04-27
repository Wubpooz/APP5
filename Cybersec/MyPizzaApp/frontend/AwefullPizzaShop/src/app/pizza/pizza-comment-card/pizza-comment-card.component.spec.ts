import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaCommentCardComponent } from './pizza-comment-card.component';

describe('PizzaCommentCardComponent', () => {
  let component: PizzaCommentCardComponent;
  let fixture: ComponentFixture<PizzaCommentCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaCommentCardComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaCommentCardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
