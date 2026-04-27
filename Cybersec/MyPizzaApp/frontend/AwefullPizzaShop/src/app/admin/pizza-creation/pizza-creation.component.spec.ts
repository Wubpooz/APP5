import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaCreationComponent } from './pizza-creation.component';

describe('PizzaCreationComponent', () => {
  let component: PizzaCreationComponent;
  let fixture: ComponentFixture<PizzaCreationComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaCreationComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaCreationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
