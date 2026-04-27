import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaSelectionScreenComponent } from './pizza-selection-screen.component';

describe('PizzaSelectionScreenComponent', () => {
  let component: PizzaSelectionScreenComponent;
  let fixture: ComponentFixture<PizzaSelectionScreenComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaSelectionScreenComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaSelectionScreenComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
