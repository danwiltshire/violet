import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MediaBrowserHeader } from './media-browser-header';

describe('MediaBrowserHeader', () => {
  let component: MediaBrowserHeader;
  let fixture: ComponentFixture<MediaBrowserHeader>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MediaBrowserHeader],
    }).compileComponents();

    fixture = TestBed.createComponent(MediaBrowserHeader);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
