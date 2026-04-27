import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaCommentAddDialog } from './pizza-comment-add-dialog.component';

describe('PizzaCommentDialogComponent', () => {
  let component: PizzaCommentAddDialog;
  let fixture: ComponentFixture<PizzaCommentAddDialog>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaCommentAddDialog]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaCommentAddDialog);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
