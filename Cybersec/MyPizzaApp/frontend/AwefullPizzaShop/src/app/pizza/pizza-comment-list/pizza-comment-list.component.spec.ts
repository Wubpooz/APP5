import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaCommentListComponent } from './pizza-comment-list.component';

describe('PizzaCommentListComponent', () => {
  let component: PizzaCommentListComponent;
  let fixture: ComponentFixture<PizzaCommentListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaCommentListComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaCommentListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
