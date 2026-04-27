import { ComponentFixture, TestBed } from '@angular/core/testing';

import { IndividualPizzaScreenComponent } from './individual-pizza-screen.component';

describe('IndividualPizzaScreenComponent', () => {
  let component: IndividualPizzaScreenComponent;
  let fixture: ComponentFixture<IndividualPizzaScreenComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [IndividualPizzaScreenComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(IndividualPizzaScreenComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
