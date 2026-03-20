import { Component, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterOutlet } from '@angular/router';
import { VidStackPlayerComponent } from '../vidstack-player/vidstack-player';
import { VidstackPlayerHeader } from '../vidstack-player-header/vidstack-player-header';

@Component({
  selector: 'app-vidstack-player-layout',
  imports: [VidStackPlayerComponent, RouterOutlet, VidstackPlayerHeader],
  templateUrl: './vidstack-player-layout.html',
})
export class PlayerPageComponent {
  mediaId = signal('');

  private activatedRoute = inject(ActivatedRoute);

  constructor() {
    this.activatedRoute.params.subscribe((params) => {
      this.mediaId.set(params['mediaId']);
    });
  }
}
