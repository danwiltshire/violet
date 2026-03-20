import { TestBed } from '@angular/core/testing';

import { VioletApi } from './violet-api';

describe('VioletApi', () => {
  let service: VioletApi;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(VioletApi);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
