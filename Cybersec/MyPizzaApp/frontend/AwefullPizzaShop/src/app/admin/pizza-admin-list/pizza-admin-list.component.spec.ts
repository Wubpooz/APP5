import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PizzaAdminListComponent } from './pizza-admin-list.component';

describe('PizzaAdminListComponent', () => {
  let component: PizzaAdminListComponent;
  let fixture: ComponentFixture<PizzaAdminListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [PizzaAdminListComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PizzaAdminListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
