import { Component, computed, CUSTOM_ELEMENTS_SCHEMA, input } from '@angular/core';

import 'vidstack/player';
import 'vidstack/player/layouts/plyr';
import 'vidstack/player/ui';
import { environment } from '../../../environments/environment';

@Component({
  selector: "app-vidstack-player",
  templateUrl: './vidstack-player.html',
  standalone: true,
  imports: [],
  schemas: [
    CUSTOM_ELEMENTS_SCHEMA
  ],
  styleUrls: [],
})
export class VidStackPlayerComponent {
  mediaId = input.required<string>();
  mediaSrc = computed(() =>
    `${environment.outputBaseUrl}/${this.mediaId()}/stream/${this.mediaId()}.mpd`
  );
  posterPath = input.required<string>();
  posterUrl = computed(() =>
    `${environment.imagesBaseUrl}/${this.posterPath()}`
  );
}