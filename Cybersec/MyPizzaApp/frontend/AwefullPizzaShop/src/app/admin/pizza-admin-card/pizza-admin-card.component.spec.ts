import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaAdminCardComponent } from './pizza-admin-card.component';

describe('PizzaAdminCardComponent', () => {
  let component: PizzaAdminCardComponent;
  let fixture: ComponentFixture<PizzaAdminCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaAdminCardComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaAdminCardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
