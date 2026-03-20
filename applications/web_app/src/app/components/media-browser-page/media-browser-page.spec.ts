import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MediaBrowserPage } from './media-browser-page';

describe('MediaBrowserPage', () => {
  let component: MediaBrowserPage;
  let fixture: ComponentFixture<MediaBrowserPage>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MediaBrowserPage],
    }).compileComponents();

    fixture = TestBed.createComponent(MediaBrowserPage);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
