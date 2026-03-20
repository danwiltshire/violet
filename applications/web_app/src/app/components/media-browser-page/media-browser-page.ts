import { Component, input } from '@angular/core';
import { MediaBrowserHeader } from '../media-browser-header/media-browser-header';
import { MediaCardComponent } from '../media-card-component/media-card-component';

export interface MediaCardVm {
  id: string;
  title: string;
  subtitle?: string;
  imageSrc: string;
  routerLink: readonly (string | number)[];
}

@Component({
  selector: 'app-media-browser-page',
  imports: [MediaBrowserHeader, MediaCardComponent],
  templateUrl: './media-browser-page.html',
  styleUrl: './media-browser-page.css',
})
export class MediaBrowserPage {
  cards = input.required<readonly MediaCardVm[]>();
}
