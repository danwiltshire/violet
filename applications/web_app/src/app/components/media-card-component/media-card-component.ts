import { Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-media-card-component',
  imports: [RouterLink],
  templateUrl: './media-card-component.html',
  styleUrl: './media-card-component.css',
})
export class MediaCardComponent {
  mediaId = input.required<string>();
  title = input.required<string>();
  subtitle = input<string>();
  bannerImageSrc = input.required<string>();
  /**
   * Allows the media card to be generic, enabling navigation
   * between TV shows, season and episodes, as well as movies.
   */
  routerLink = input.required<readonly (string | number)[]>();
}
